import 'dart:math' show min;

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:untitled/common/api_service/colibri_timeline_service.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/models/colibri_post_models.dart';

/// 全局收藏状态（应用内唯一真相，permanent 单例）。
///
/// 设计要点（修复旧版重复/错位/不同步）：
/// - [ids]（RxSet）是「是否已收藏」的唯一来源：所有帖子卡片的书签图标用 Obx
///   观察它，任意页面收藏/取消 → 全局卡片即时同步，不存在卡片各自维护的本地状态。
/// - [posts] 收藏页列表按 id 去重维护（同一帖子物理上只有一条）；配合卡片的
///   ValueKey，头部插入/移除时 State 永远跟随正确的帖子，不再重复渲染。
/// - [toggle] 乐观更新 + 失败回滚；[syncFromServer] 以服务端列表为最终真相对齐。
/// - GetStorage 缓存 ids + 帖子原始 JSON：离线/弱网进入收藏页也能秒开。
class BookmarkStore extends GetxController {
  static BookmarkStore get i => Get.find<BookmarkStore>();

  static const String _cacheKey = 'colibri_bookmarks_v2';
  static const int pageSize = 10;

  /// 已收藏帖子 id 集合（收藏状态唯一真相）。
  final RxSet<int> ids = <int>{}.obs;

  /// 收藏页帖子列表（新收藏置顶；按 id 物理唯一）。
  final RxList<ColibriPost> posts = <ColibriPost>[].obs;

  /// 本地分页可见条数。
  final RxInt visibleCount = 0.obs;

  /// 首次加载（无任何数据可展示时全屏 loading）。
  final RxBool loading = false.obs;

  /// 下拉刷新中。
  final RxBool refreshing = false.obs;

  bool _everSynced = false;

  bool get _loggedIn =>
      SessionManager.shared.isLogin() &&
      (SessionManager.shared.getToken()?.isNotEmpty ?? false);

  bool isBookmarked(int id) => ids.contains(id);

  bool get hasMore => visibleCount.value < posts.length;

  /// 分页可见帖子。
  List<ColibriPost> get visiblePosts => posts.take(visibleCount.value).toList();

  @override
  void onInit() {
    super.onInit();
    try {
      GetStorage().remove('colibri_bookmarks_cache'); // 清理旧版（v1）缓存
    } catch (_) {}
    _loadCache();
    if (_loggedIn) syncFromServer();
  }

  /// 进入主界面（登录成功 / 启动自动登录均会走到）：确保与服务端同步过一次。
  void onEnterHome() {
    if (!_everSynced && !loading.value && !refreshing.value) syncFromServer();
  }

  // ===================== 收藏切换 =====================

  /// 收藏 / 取消收藏（乐观更新；失败自动回滚）。返回最终是否已收藏。
  Future<bool> toggle(ColibriPost post) async {
    final target = !ids.contains(post.id);
    _applyLocal(post, target);
    bool result;
    try {
      result = await ColibriTimelineService.shared.togglePostBookmark(post.id);
    } catch (_) {
      _applyLocal(post, !target); // 回滚
      rethrow;
    }
    // 以服务端返回为准（理论上 == target，不一致则对齐）
    if (result != target) _applyLocal(post, result);
    _persist();
    return result;
  }

  /// 应用一次收藏状态（ids + posts + 分页可见数联动）。
  void _applyLocal(ColibriPost post, bool bookmarked) {
    if (bookmarked) {
      ids.add(post.id);
      final updated = post.copyWith(isBookmarked: true);
      final i = posts.indexWhere((p) => p.id == post.id);
      if (i >= 0) {
        posts[i] = updated;
      } else {
        posts.insert(0, updated); // 新收藏置顶
        visibleCount.value = min(visibleCount.value + 1, posts.length);
      }
    } else {
      ids.remove(post.id);
      posts.removeWhere((p) => p.id == post.id);
      if (visibleCount.value > posts.length) visibleCount.value = posts.length;
    }
  }

  // ===================== 服务端同步 =====================

  /// 以服务端收藏列表为最终真相对齐（数据按 id 去重）。
  Future<void> syncFromServer() async {
    if (!_loggedIn) return;
    if (loading.value || refreshing.value) return;
    if (posts.isEmpty && ids.isEmpty) {
      loading.value = true;
    } else {
      refreshing.value = true;
    }
    try {
      final list = await ColibriTimelineService.shared.fetchBookmarks();
      final dedup = <int, ColibriPost>{};
      for (final p in list) {
        dedup.putIfAbsent(p.id, () => p.copyWith(isBookmarked: true));
      }
      ids
        ..clear()
        ..addAll(dedup.keys);
      posts.assignAll(dedup.values);
      visibleCount.value = min(
          visibleCount.value == 0 ? pageSize : visibleCount.value,
          posts.length);
      _everSynced = true;
      _persist();
    } catch (_) {
      // 同步失败保留缓存，下拉可重试
    } finally {
      loading.value = false;
      refreshing.value = false;
    }
  }

  /// 下拉刷新入口（命名避开 GetX 自带 refresh）。
  Future<void> pullRefresh() => syncFromServer();

  /// 上拉加载更多（本地分页）。
  void loadMore() {
    if (!hasMore) return;
    visibleCount.value = min(visibleCount.value + pageSize, posts.length);
  }

  // ===================== 登出复位 =====================

  /// 登出 / 401：清空内存状态与缓存。
  void reset() {
    ids.clear();
    posts.clear();
    visibleCount.value = 0;
    loading.value = false;
    refreshing.value = false;
    _everSynced = false;
    try {
      GetStorage().remove(_cacheKey);
    } catch (_) {}
  }

  // ===================== 本地缓存 =====================

  void _loadCache() {
    try {
      final raw = GetStorage().read(_cacheKey);
      if (raw is! Map) return;
      final cachedIds = raw['ids'];
      if (cachedIds is List) {
        ids.addAll(cachedIds.map((e) => int.tryParse('$e')).whereType<int>());
      }
      final list = raw['posts'];
      if (list is List) {
        final cached = list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .map(ColibriPost.fromJson)
            .toList();
        final dedup = <int, ColibriPost>{};
        for (final p in cached) {
          dedup.putIfAbsent(p.id, () => p.copyWith(isBookmarked: true));
        }
        posts.assignAll(dedup.values);
        visibleCount.value = min(pageSize, posts.length);
      }
    } catch (_) {}
  }

  /// 持久化 ids + 帖子原始 JSON。
  void _persist() {
    try {
      GetStorage().write(_cacheKey, {
        'saved_at': DateTime.now().millisecondsSinceEpoch,
        'ids': ids.toList(),
        'posts': posts.map((p) => p.rawJson).toList(),
      });
    } catch (_) {}
  }
}

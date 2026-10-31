import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_guest_service.dart';
import 'package:untitled/common/api_service/colibri_timeline_service.dart';
import 'package:untitled/common/managers/guest_session.dart';
import 'package:untitled/models/colibri_post_models.dart';

/// 一条主评论线程的 UI 状态。
///
/// - [root]：主评论（一级节点）；
/// - [previewReplies]：折叠态展示的最新 2 条回复（服务端首屏水合，零额外请求）；
/// - [loadedReplies]：展开后拉取到的回复（分页累积），折叠时保留缓存，二次展开秒开；
/// - [total]：线程内全部回复数（含任意层级，服务端按 root_id 归并）。
class CommentThread {
  ColibriComment root;
  final RxList<ColibriComment> previewReplies;
  final RxList<ColibriComment> loadedReplies;
  final RxInt total;
  final RxBool expanded;
  final RxBool loadingFirst;
  final RxBool loadingMore;
  final RxBool actionError;

  int? _cursor;
  bool hasMore = false;
  bool get firstPageLoaded => loadedReplies.isNotEmpty;

  int get rootId => root.id;

  CommentThread({
    required this.root,
    required List<ColibriComment> previews,
    required int repliesTotal,
  })  : previewReplies = previews.obs,
        loadedReplies = <ColibriComment>[].obs,
        total = repliesTotal.obs,
        expanded = false.obs,
        loadingFirst = false.obs,
        loadingMore = false.obs,
        actionError = false.obs;

  /// 折叠时显示预览，展开时显示已加载的完整列表。
  List<ColibriComment> get visibleReplies =>
      expanded.value ? loadedReplies : previewReplies;

  bool containsComment(int commentId) {
    if (root.id == commentId) return true;
    return previewReplies.any((c) => c.id == commentId) ||
        loadedReplies.any((c) => c.id == commentId);
  }
}

/// B站式树状评论控制器：主评论分页 + 线程展开/折叠 + 回复分页 + 发布/删除/表态联动。
class CommentThreadController extends GetxController {
  ColibriPost post;
  final RxList<CommentThread> threads = <CommentThread>[].obs;
  final RxBool loading = true.obs;
  final RxBool loadingMoreRoots = false.obs;
  final RxBool sending = false.obs;
  final Rx<ColibriComment?> replyTarget = Rx<ColibriComment?>(null);

  /// 主评论分页
  int? _rootCursor;
  bool _hasMoreRoots = true;
  bool _fetchingRoots = false;

  static const int pageSize = 20;

  CommentThreadController(this.post);

  bool get isGuest => GuestSession.i.isGuest;

  ColibriTimelineService get _api => ColibriTimelineService.shared;
  ColibriGuestService get _guestApi => ColibriGuestService.shared;

  @override
  void onReady() {
    loadInitial();
    super.onReady();
  }

  /// 首屏：帖子详情（threaded 只回主评论 + 回复预览）。
  Future<void> loadInitial() async {
    loading.value = true;
    try {
      final result = isGuest
          ? await _guestApi.fetchPostDetail(post.hashId, threaded: true)
          : await _api.fetchPostDetail(post.hashId, threaded: true);
      post = result.post;
      threads.assignAll(result.comments.map((c) => CommentThread(
            root: c,
            previews: c.previewReplies,
            repliesTotal: c.repliesTotal,
          )));
      _updateRootCursor(result.comments);
      _hasMoreRoots = result.comments.length >= pageSize;
    } catch (_) {
      // 保留旧数据，UI 可通过下拉重试
    } finally {
      loading.value = false;
    }
  }

  /// 底部触底加载更多主评论。
  Future<void> loadMoreRoots() async {
    if (_fetchingRoots || loading.value || !_hasMoreRoots) return;
    _fetchingRoots = true;
    loadingMoreRoots.value = true;
    try {
      final page = isGuest
          ? await _guestApi.fetchPostComments(post.hashId,
              cursor: _rootCursor, threaded: true)
          : await _api.fetchPostComments(post.hashId,
              cursor: _rootCursor, threaded: true);
      for (final c in page) {
        if (!threads.any((t) => t.rootId == c.id)) {
          threads.add(CommentThread(
              root: c,
              previews: c.previewReplies,
              repliesTotal: c.repliesTotal));
        }
      }
      _updateRootCursor(page);
      _hasMoreRoots = page.length >= pageSize;
    } catch (_) {
    } finally {
      _fetchingRoots = false;
      loadingMoreRoots.value = false;
    }
  }

  void _updateRootCursor(List<ColibriComment> page) {
    if (page.isNotEmpty) {
      _rootCursor = page.map((c) => c.id).reduce((a, b) => a < b ? a : b);
    }
  }

  /// 展开/折叠线程。首次展开且预览不全时拉第一页回复。
  Future<void> toggleExpand(CommentThread thread) async {
    if (!thread.expanded.value) {
      thread.expanded.value = true;
      if (!thread.firstPageLoaded) {
        if (thread.total.value > thread.previewReplies.length) {
          // 乐观置 true：即使首屏请求失败，底部「点击重试」也能再次发起加载
          thread.hasMore = true;
          await _fetchRepliesPage(thread, isFirst: true);
        } else {
          // 预览即全部回复，直接转正，无需请求
          thread.loadedReplies.assignAll(thread.previewReplies);
          thread.hasMore = false;
        }
      }
    } else {
      // 折叠保留 loadedReplies 缓存，二次展开零等待
      thread.expanded.value = false;
    }
  }

  Future<void> loadMoreReplies(CommentThread thread) async {
    if (thread.loadingMore.value || !thread.hasMore) return;
    await _fetchRepliesPage(thread, isFirst: false);
  }

  Future<void> _fetchRepliesPage(CommentThread thread,
      {required bool isFirst}) async {
    final flag = isFirst ? thread.loadingFirst : thread.loadingMore;
    if (flag.value) return;
    flag.value = true;
    thread.actionError.value = false;
    try {
      final result = isGuest
          ? await _guestApi.fetchCommentReplies(thread.rootId,
              cursor: isFirst ? null : thread._cursor)
          : await _api.fetchCommentReplies(thread.rootId,
              cursor: isFirst ? null : thread._cursor);
      final incoming = isFirst
          ? result.replies
          : [...thread.loadedReplies, ...result.replies];
      // 按 id 去重（首屏预览与分页结果可能重叠）
      final seen = <int>{};
      final merged = <ColibriComment>[];
      for (final c in incoming) {
        if (seen.add(c.id)) merged.add(c);
      }
      thread.loadedReplies.assignAll(merged);
      thread.total.value = result.total;
      if (result.replies.isNotEmpty) {
        thread._cursor =
            result.replies.map((c) => c.id).reduce((a, b) => a < b ? a : b);
      }
      thread.hasMore =
          merged.length < result.total && result.replies.isNotEmpty;
    } catch (_) {
      thread.actionError.value = true;
    } finally {
      flag.value = false;
    }
  }

  /// 设置/取消回复目标（目标可以是主评论或任意回复）。
  void setReplyTarget(ColibriComment? comment) {
    replyTarget.value = comment;
  }

  CommentThread? _threadOfRoot(int rootId) {
    final idx = threads.indexWhere((t) => t.rootId == rootId);
    return idx == -1 ? null : threads[idx];
  }

  /// 发表主评论或回复。[text] 由输入框 trim 后传入。
  Future<bool> send(String text) async {
    if (sending.value || text.isEmpty) return false;
    sending.value = true;
    try {
      final target = replyTarget.value;
      final parentId = target?.id;
      final result = await _api.createComment(
          postId: post.id, content: text, parentId: parentId);
      final created = result.comment;

      if (created.isRoot) {
        threads.insert(
          0,
          CommentThread(root: created, previews: const [], repliesTotal: 0),
        );
      } else {
        final threadRootId = created.rootId ?? target?.rootId ?? target?.id;
        final thread =
            threadRootId == null ? null : _threadOfRoot(threadRootId);
        // 可见的回复必属于已加载线程；找不到时保守刷新首屏保证数据一致
        if (thread != null) {
          thread.total.value += 1;
          thread.previewReplies
            ..insert(0, created)
            ..removeRangeSafe(CommentThreadServicePreview.previewCount);
          // 已展开加载过（哪怕当前折叠）也要同步缓存，避免二次展开出现陈旧列表
          if (thread.firstPageLoaded &&
              !thread.loadedReplies.any((c) => c.id == created.id)) {
            thread.loadedReplies.insert(0, created);
          }
          thread.hasMore = thread.loadedReplies.length < thread.total.value;
          threads.refresh();
        } else {
          await loadInitial();
        }
      }

      _applyServerCount(result.commentsCount, fallback: post.commentsCount + 1);
      replyTarget.value = null;
      return true;
    } catch (_) {
      return false;
    } finally {
      sending.value = false;
    }
  }

  /// 删除评论。主评论删除时整棵子树（服务端级联）同步从 UI 移除。
  Future<bool> delete(ColibriComment comment) async {
    final serverCount = await _api.deleteComment(comment.id);

    if (comment.isRoot) {
      final idx = threads.indexWhere((t) => t.rootId == comment.id);
      if (idx != -1) {
        final removedSubtree = 1 + threads[idx].total.value;
        threads.removeAt(idx);
        _applyServerCount(serverCount,
            fallback: post.commentsCount - removedSubtree);
      }
    } else {
      final rootId = comment.rootId;
      if (rootId != null) {
        final thread = _threadOfRoot(rootId);
        if (thread != null) {
          thread.previewReplies.removeWhere((c) => c.id == comment.id);
          thread.loadedReplies.removeWhere((c) => c.id == comment.id);
          if (thread.total.value > 0) thread.total.value -= 1;
          // 折叠态预览被删后，若有已加载缓存则重建预览，保证始终尽量展示 2 条
          if (!thread.expanded.value &&
              thread.firstPageLoaded &&
              thread.previewReplies.length <
                  CommentThreadServicePreview.previewCount) {
            thread.previewReplies.assignAll(thread.loadedReplies
                .take(CommentThreadServicePreview.previewCount));
          }
          threads.refresh();
        }
      }
      _applyServerCount(serverCount, fallback: post.commentsCount - 1);
    }
    return true;
  }

  /// 表态更新：按 id 定位主评论或任意线程内回复（预览/已加载列表全覆盖）。
  void applyReactions(int commentId, List<ColibriReaction> reactions) {
    for (final thread in threads) {
      if (thread.root.id == commentId) {
        thread.root = thread.root.copyWith(reactions: reactions);
        threads.refresh();
        return;
      }
      if (_replaceIn(thread.previewReplies, commentId, reactions) |
          _replaceIn(thread.loadedReplies, commentId, reactions)) {
        thread.previewReplies.refresh();
        thread.loadedReplies.refresh();
        return;
      }
    }
  }

  bool _replaceIn(RxList<ColibriComment> list, int commentId,
      List<ColibriReaction> reactions) {
    final idx = list.indexWhere((c) => c.id == commentId);
    if (idx == -1) return false;
    list[idx] = list[idx].copyWith(reactions: reactions);
    return true;
  }

  void _applyServerCount(int? serverCount, {required int fallback}) {
    final count = serverCount ?? (fallback < 0 ? 0 : fallback);
    post =
        post.copyWith(commentsCount: count, commentsCountFormatted: '$count');
  }
}

/// 预览条数常量（与后端 CommentThreadService::PREVIEW_PER_THREAD 保持一致）。
class CommentThreadServicePreview {
  static const int previewCount = 2;
}

/// RxList 小工具：安全截断。
extension on RxList<ColibriComment> {
  void removeRangeSafe(int max) {
    if (length > max) removeRange(max, length);
  }
}

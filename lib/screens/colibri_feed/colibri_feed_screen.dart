import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_guest_service.dart';
import 'package:untitled/common/api_service/colibri_timeline_service.dart';
import 'package:untitled/common/managers/guest_session.dart';
import 'package:untitled/common/managers/haptic_manager.dart';
import 'package:untitled/common/widgets/colibri_ui.dart';
import 'package:untitled/common/widgets/colibri_skeleton.dart';
import 'package:untitled/common/widgets/guest_auth_sheet.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/colibri_post_models.dart';
import 'package:untitled/screens/colibri_feed/colibri_post_card.dart';
import 'package:untitled/screens/colibri_feed/colibri_post_detail_screen.dart';
import 'package:untitled/screens/colibri_feed/colibri_story_bar.dart';
import 'package:untitled/screens/colibri_social/colibri_search_screen.dart';
import 'package:untitled/utilities/const.dart';

/// 关注时间线（自己+关注的人）与推荐时间线（全部作者，按互动排序）。
class ColibriFeedController extends GetxController {
  static const int pageSize = 20;
  final RxInt activeTab = 0.obs;

  // 关注
  final RxList<ColibriPost> followingPosts = <ColibriPost>[].obs;
  final RxBool followingLoading = true.obs;
  final RxBool followingLoadingMore = false.obs;
  int _followingPage = 1;
  int _followingRequestId = 0;
  bool _followingHasMore = true;

  // 推荐
  final RxList<ColibriPost> recommendPosts = <ColibriPost>[].obs;
  final RxBool recommendLoading = true.obs;
  final RxBool recommendLoadingMore = false.obs;
  int _recommendPage = 1;
  int _recommendRequestId = 0;
  bool _recommendHasMore = true;

  // 全局置顶（管理后台置顶：关注 / 推荐两个 tab 的列表顶部统一展示）
  final RxList<ColibriPost> pinnedPosts = <ColibriPost>[].obs;

  // 访客精选流（未登录 + 访客开关开启时使用，数据源 guest/v1/feed）
  final RxList<ColibriPost> guestPosts = <ColibriPost>[].obs;
  final RxBool guestLoading = true.obs;
  final RxBool guestLoadingMore = false.obs;
  int _guestPage = 1;
  bool _guestHasMore = true;

  bool get isFollowing => activeTab.value == 0;
  bool get isGuest => GuestSession.i.isGuest;

  /// 与新建的 TabController 同步（TabController 每次重建都从 index 0 开始）。
  /// 全局重建（维护恢复 / 401 重登等 Get.offAll 场景）后本控制器可能被 GetX
  /// 复用而 activeTab 残留旧值，必须复位，否则切换判定失步、刷新被跳过。
  void syncTab(int index) => activeTab.value = index;

  /// Insert a just-published post into the currently visible feed.
  void showPublishedPost(ColibriPost post, {required bool following}) {
    final posts = following ? followingPosts : recommendPosts;
    if (following) {
      _followingRequestId++;
      followingLoading.value = false;
      followingLoadingMore.value = false;
    } else {
      _recommendRequestId++;
      recommendLoading.value = false;
      recommendLoadingMore.value = false;
    }
    posts.removeWhere((item) => item.id == post.id);
    posts.insert(0, post);
  }

  /// 本地同步：从两个列表中移除已删除的帖子（另一个 tab 在刷新前也立即消失）。
  void removePostById(int postId) {
    followingPosts.removeWhere((p) => p.id == postId);
    recommendPosts.removeWhere((p) => p.id == postId);
    pinnedPosts.removeWhere((p) => p.id == postId);
  }

  /// 拉取全局置顶帖（非登录/访客态跳过；失败静默，不打断浏览）。
  Future<void> loadPins() async {
    if (GuestSession.i.isGuest) {
      return;
    }
    try {
      final list = await ColibriTimelineService.shared.fetchGlobalPins();
      pinnedPosts.assignAll(list);
    } catch (_) {}
  }

  @override
  void onInit() {
    super.onInit();
    if (GuestSession.i.isGuest) {
      loadGuestFeed();
    } else {
      loadFollowing();
      loadRecommend();
      loadPins();
    }
  }

  void switchTab(int i) => activeTab.value = i;

  // ===================== 关注 =====================
  Future<void> loadFollowing({bool clearBeforeLoad = false}) async {
    final requestId = ++_followingRequestId;
    followingLoading.value = true;
    followingLoadingMore.value = false;
    if (clearBeforeLoad) followingPosts.clear();
    _followingPage = 1;
    _followingHasMore = true;
    try {
      final list = await ColibriTimelineService.shared.fetchFeed(page: 1);
      if (requestId != _followingRequestId) return;
      followingPosts.assignAll(list);
      if (list.length < pageSize) _followingHasMore = false;
    } catch (_) {
      if (requestId == _followingRequestId) _followingHasMore = false;
    } finally {
      if (requestId == _followingRequestId) followingLoading.value = false;
    }
  }

  Future<void> loadMoreFollowing() async {
    if (followingLoading.value ||
        followingLoadingMore.value ||
        !_followingHasMore) {
      return;
    }
    followingLoadingMore.value = true;
    final requestId = _followingRequestId;
    final next = _followingPage + 1;
    try {
      final list = await ColibriTimelineService.shared.fetchFeed(page: next);
      if (requestId != _followingRequestId) return;
      if (list.isEmpty) {
        _followingHasMore = false;
      } else {
        _followingPage = next;
        final existingIds = followingPosts.map((post) => post.id).toSet();
        followingPosts.addAll(
          list.where((post) => existingIds.add(post.id)),
        );
        if (list.length < pageSize) _followingHasMore = false;
      }
    } catch (_) {
      if (requestId == _followingRequestId) _followingHasMore = false;
    } finally {
      if (requestId == _followingRequestId) {
        followingLoadingMore.value = false;
      }
    }
  }

  // ===================== 推荐 =====================
  Future<void> loadRecommend({bool clearBeforeLoad = false}) async {
    final requestId = ++_recommendRequestId;
    recommendLoading.value = true;
    recommendLoadingMore.value = false;
    if (clearBeforeLoad) recommendPosts.clear();
    _recommendPage = 1;
    _recommendHasMore = true;
    try {
      final list =
          await ColibriTimelineService.shared.fetchRecommendFeed(page: 1);
      if (requestId != _recommendRequestId) return;
      recommendPosts.assignAll(list);
      if (list.length < pageSize) _recommendHasMore = false;
    } catch (_) {
      if (requestId == _recommendRequestId) _recommendHasMore = false;
    } finally {
      if (requestId == _recommendRequestId) recommendLoading.value = false;
    }
  }

  Future<void> loadMoreRecommend() async {
    if (recommendLoading.value ||
        recommendLoadingMore.value ||
        !_recommendHasMore) {
      return;
    }
    recommendLoadingMore.value = true;
    final requestId = _recommendRequestId;
    final next = _recommendPage + 1;
    try {
      final list =
          await ColibriTimelineService.shared.fetchRecommendFeed(page: next);
      if (requestId != _recommendRequestId) return;
      if (list.isEmpty) {
        _recommendHasMore = false;
      } else {
        _recommendPage = next;
        final existingIds = recommendPosts.map((post) => post.id).toSet();
        recommendPosts.addAll(
          list.where((post) => existingIds.add(post.id)),
        );
        if (list.length < pageSize) _recommendHasMore = false;
      }
    } catch (_) {
      if (requestId == _recommendRequestId) _recommendHasMore = false;
    } finally {
      if (requestId == _recommendRequestId) {
        recommendLoadingMore.value = false;
      }
    }
  }

  // 刷新当前 tab
  Future<void> refreshActive() =>
      isFollowing ? loadFollowing() : loadRecommend();

  // ===================== 访客精选 =====================

  Future<void> loadGuestFeed() async {
    guestLoading.value = true;
    _guestPage = 1;
    _guestHasMore = true;
    try {
      final list = await ColibriGuestService.shared.fetchFeed(page: 1);
      guestPosts.assignAll(list);
      if (list.length < pageSize) _guestHasMore = false;
    } catch (_) {
      _guestHasMore = false;
    } finally {
      guestLoading.value = false;
    }
  }

  Future<void> loadMoreGuest() async {
    if (guestLoading.value || guestLoadingMore.value || !_guestHasMore) return;
    guestLoadingMore.value = true;
    final next = _guestPage + 1;
    try {
      final list = await ColibriGuestService.shared.fetchFeed(page: next);
      if (list.isEmpty) {
        _guestHasMore = false;
      } else {
        _guestPage = next;
        guestPosts.addAll(list);
        if (list.length < pageSize) _guestHasMore = false;
      }
    } catch (_) {
      _guestHasMore = false;
    } finally {
      guestLoadingMore.value = false;
    }
  }
}

class ColibriFeedScreen extends StatefulWidget {
  const ColibriFeedScreen({super.key});

  @override
  State<ColibriFeedScreen> createState() => ColibriFeedScreenState();
}

class ColibriFeedScreenState extends State<ColibriFeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ColibriFeedController _controller;
  final ScrollController _followingScrollController = ScrollController();
  final ScrollController _recommendScrollController = ScrollController();

  /// 上一次稳定所在的 tab（本地追踪，不依赖可复用的 GetX 控制器状态）。
  int _lastTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(ColibriFeedController());
    _tabController = TabController(length: 2, vsync: this);
    // TabController 每次都从 0 开始，必须同步 GetX 控制器，
    // 否则全局重建后 activeTab 残留旧值导致切换判定失步。
    _controller.syncTab(_tabController.index);
    _lastTabIndex = _tabController.index;
    _tabController.addListener(_onTabChanged);
  }

  int get selectedFeedTabIndex => _tabController.index;

  void showPublishedPost(ColibriPost post, {required bool following}) {
    _controller.showPublishedPost(post, following: following);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scrollController =
          following ? _followingScrollController : _recommendScrollController;
      if (scrollController.hasClients) scrollController.jumpTo(0);
    });
  }

  void _onTabChanged() {
    if (_tabController.index == _lastTabIndex) return;
    _lastTabIndex = _tabController.index;
    _controller.switchTab(_tabController.index);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _followingScrollController.dispose();
    _recommendScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 访客态：单栏「精选」公开流，无关注/推荐 Tab、无发帖 FAB，
    // 顶部故事条替换为登录引导卡（故事/发帖均为登录后能力）。
    if (_controller.isGuest) {
      return Scaffold(
        backgroundColor: cWhite,
        appBar: AppBar(
          backgroundColor: cWhite,
          surfaceTintColor: cWhite,
          elevation: 0,
          title: Text(LKeys.feedFeatured.tr,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 17, color: cMainText)),
        ),
        body: _FeedListTab(
          leading: const _GuestGuideCard(),
          loading: _controller.guestLoading,
          loadingMore: _controller.guestLoadingMore,
          posts: _controller.guestPosts,
          onRefresh: _controller.loadGuestFeed,
          onLoadMore: _controller.loadMoreGuest,
          onPostRemoved: null,
          emptyWidget: ColibriEmptyState(
            icon: Icons.explore_rounded,
            title: LKeys.feedEmptyPublicTitle.tr,
            subtitle: LKeys.feedPullToRefresh.tr,
            topSpacing: 60,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cWhite,
      appBar: AppBar(
        backgroundColor: cWhite,
        surfaceTintColor: cWhite,
        elevation: 0,
        title: const Text('Feed',
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 17, color: cMainText)),
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 9),
          indicator: BoxDecoration(
            color: cPrimary.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
          ),
          labelColor: cGreen,
          unselectedLabelColor: cLightText,
          labelStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          splashFactory: NoSplash.splashFactory,
          dividerColor: Colors.transparent,
          tabs: [
            Tab(text: LKeys.feedFollow.tr),
            Tab(text: LKeys.feedForYou.tr),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FeedListTab(
            leading: const ColibriStoryBar(),
            loading: _controller.followingLoading,
            loadingMore: _controller.followingLoadingMore,
            posts: _controller.followingPosts,
            scrollController: _followingScrollController,
            pinnedPosts: _controller.pinnedPosts,
            onRefresh: _controller.loadFollowing,
            onLoadMore: _controller.loadMoreFollowing,
            onPostRemoved: _controller.removePostById,
            emptyWidget: _buildFollowingEmpty(context),
          ),
          _FeedListTab(
            leading: const ColibriStoryBar(),
            loading: _controller.recommendLoading,
            loadingMore: _controller.recommendLoadingMore,
            posts: _controller.recommendPosts,
            scrollController: _recommendScrollController,
            pinnedPosts: _controller.pinnedPosts,
            onRefresh: _controller.loadRecommend,
            onLoadMore: _controller.loadMoreRecommend,
            onPostRemoved: _controller.removePostById,
            emptyWidget: _buildRecommendEmpty(),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowingEmpty(BuildContext context) {
    return ColibriEmptyState(
      icon: Icons.group_add_rounded,
      title: LKeys.feedEmptyFollowingTitle.tr,
      subtitle: LKeys.feedEmptyFollowingDesc.tr,
      topSpacing: 60,
      action: ColibriPillButton(
        text: LKeys.feedFindPeople.tr,
        icon: Icons.explore_rounded,
        filled: true,
        height: 42,
        onTap: () => Get.to(() => const ColibriSearchScreen(), opaque: false),
      ),
    );
  }

  Widget _buildRecommendEmpty() {
    return ColibriEmptyState(
      icon: Icons.explore_rounded,
      title: LKeys.feedEmptyRecommendTitle.tr,
      subtitle: LKeys.feedPullToRefresh.tr,
      topSpacing: 60,
    );
  }
}

class ColibriCreateButton extends StatefulWidget {
  final VoidCallback onPressed;

  const ColibriCreateButton({super.key, required this.onPressed});

  @override
  State<ColibriCreateButton> createState() => _ColibriCreateButtonState();
}

class _ColibriCreateButtonState extends State<ColibriCreateButton> {
  static const double _buttonWidth = 112;
  static const double _buttonHeight = 48;
  static const double _buttonRadius = 24;

  bool _pressed = false;
  bool _launching = false;

  void _handleTap() {
    if (_launching) return;
    HapticManager.shared.medium();
    setState(() {
      _pressed = false;
      _launching = true;
    });
    Future<void>.delayed(const Duration(milliseconds: 90), () {
      if (mounted) widget.onPressed();
    });
    Future<void>.delayed(const Duration(milliseconds: 460), () {
      if (mounted) setState(() => _launching = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: LKeys.feedCreatePostLabel.tr,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          if (!_launching) setState(() => _pressed = true);
        },
        onTapCancel: () {
          if (_pressed) setState(() => _pressed = false);
        },
        onTap: _handleTap,
        child: AnimatedScale(
          scale: _pressed ? 0.95 : (_launching ? 1.04 : 1),
          duration: Duration(milliseconds: _pressed ? 110 : 260),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            width: _buttonWidth,
            height: _buttonHeight,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xF7FFFFFF),
                    borderRadius: BorderRadius.circular(_buttonRadius),
                    border: Border.all(color: const Color(0xFFE2E5EA)),
                    boxShadow: [
                      BoxShadow(
                        color: cBlack.withValues(alpha: _pressed ? 0.12 : 0.2),
                        blurRadius: _pressed ? 8 : 14,
                        offset: Offset(0, _pressed ? 2 : 5),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: _buttonWidth,
                    height: _buttonHeight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Icon(
                            _launching ? Icons.edit_rounded : Icons.add_rounded,
                            key: ValueKey(_launching),
                            color: cPrimary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          LKeys.feedPublish.tr,
                          style: const TextStyle(
                            color: cPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedSkeletonList extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget leading;

  const _FeedSkeletonList({required this.onRefresh, required this.leading});

  @override
  State<_FeedSkeletonList> createState() => _FeedSkeletonListState();
}

class _FeedSkeletonListState extends State<_FeedSkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: cPrimary,
      onRefresh: widget.onRefresh,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: 6,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              thickness: 1,
              color: cLightBg,
            ),
            itemBuilder: (_, index) {
              if (index == 0) {
                return widget.leading is _GuestGuideCard
                    ? widget.leading
                    : _FeedSkeletonHeader(_animationController.value);
              }
              return _FeedSkeletonPost(
                phase: (_animationController.value + index * 0.12) % 1,
              );
            },
          );
        },
      ),
    );
  }
}

class _FeedSkeletonHeader extends StatelessWidget {
  final double phase;

  const _FeedSkeletonHeader(this.phase);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          _SkeletonBlock(width: 54, height: 54, phase: phase, radius: 27),
          const SizedBox(width: 12),
          _SkeletonBlock(width: 74, height: 10, phase: phase),
          const SizedBox(width: 10),
          _SkeletonBlock(width: 54, height: 10, phase: phase),
        ],
      ),
    );
  }
}

class _FeedSkeletonPost extends StatelessWidget {
  final double phase;

  const _FeedSkeletonPost({required this.phase});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SkeletonBlock(width: 42, height: 42, phase: phase, radius: 21),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBlock(width: 112, height: 10, phase: phase),
                  const SizedBox(height: 8),
                  _SkeletonBlock(width: 76, height: 8, phase: phase),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SkeletonBlock(width: double.infinity, height: 11, phase: phase),
          const SizedBox(height: 9),
          FractionallySizedBox(
            widthFactor: 0.82,
            child: _SkeletonBlock(
                width: double.infinity, height: 11, phase: phase),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SkeletonBlock(width: 44, height: 9, phase: phase),
              const SizedBox(width: 24),
              _SkeletonBlock(width: 44, height: 9, phase: phase),
              const SizedBox(width: 24),
              _SkeletonBlock(width: 44, height: 9, phase: phase),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  final double width;
  final double height;
  final double phase;
  final double radius;

  const _SkeletonBlock({
    required this.width,
    required this.height,
    required this.phase,
    this.radius = 5,
  });

  @override
  Widget build(BuildContext context) {
    final shift = phase * 2 - 1;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(shift - 1, 0),
              end: Alignment(shift + 1, 0),
              colors: const [
                Color(0xFFE9EBEF),
                Color(0xFFF7F8FA),
                Color(0xFFE9EBEF),
              ],
              stops: const [0.35, 0.5, 0.65],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedListTab extends StatelessWidget {
  final RxList<ColibriPost> posts;
  final RxBool loading;
  final RxBool loadingMore;

  /// 列表顶部挂件：登录态为故事条；访客态为登录引导卡。
  final Widget leading;

  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;
  final ScrollController? scrollController;

  /// 帖子被删除后的本地同步（从两个列表中移除）。
  final void Function(int postId)? onPostRemoved;
  final Widget emptyWidget;

  /// 全局置顶帖（登录态两个 tab 列表顶部统一展示；置顶帖本身不参与分页）。
  final RxList<ColibriPost>? pinnedPosts;

  const _FeedListTab({
    required this.posts,
    required this.loading,
    required this.loadingMore,
    required this.leading,
    required this.onRefresh,
    required this.onLoadMore,
    this.scrollController,
    this.onPostRemoved,
    required this.emptyWidget,
    this.pinnedPosts,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (loading.value) {
        return ColibriSkeletonPosts(
          leading: leading,
          onRefresh: onRefresh,
        );
      }
      // 置顶帖固定展示在列表顶部（两个 tab 共用同一份全局置顶）。
      // 不去重：与网页端一致，置顶帖即使出现在主列表中也照常在顶部展示置顶标识
      // （推荐流 explore 本身包含全部作者帖子，去重会导致置顶区被过滤掉）。
      final pins = pinnedPosts ?? const <ColibriPost>[];
      final visiblePins = pins.toList();
      final isEmpty = posts.isEmpty && visiblePins.isEmpty;
      if (isEmpty) {
        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: cPrimary,
                onRefresh: onRefresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    leading,
                    emptyWidget,
                  ],
                ),
              ),
            ),
          ],
        );
      }
      return Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: cPrimary,
              onRefresh: onRefresh,
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                    onLoadMore();
                  }
                  return false;
                },
                child: ListView.separated(
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: 1 +
                      visiblePins.length +
                      posts.length +
                      (posts.isEmpty ? 1 : 0) +
                      (loadingMore.value ? 1 : 0),
                  separatorBuilder: (context, index) {
                    final postCount = visiblePins.length + posts.length;
                    if (index >= 1 && index < postCount) {
                      return const Divider(
                        height: 1,
                        thickness: 1,
                        color: cLightBg,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  itemBuilder: (context, index) {
                    // 首项：顶部挂件（故事条 / 访客登录引导卡）
                    if (index == 0) {
                      return leading;
                    }
                    var postIndex = index - 1;
                    // 置顶帖区：固定在列表最顶部，带置顶标识
                    if (postIndex < visiblePins.length) {
                      final post = visiblePins[postIndex];
                      return ColibriPostCard(
                        key: ValueKey('pinned_${post.id}'),
                        post: post,
                        resizeMediaToDisplayBounds: true,
                        onChanged: () {
                          onPostRemoved?.call(post.id);
                          onRefresh();
                        },
                        onTap: () async {
                          await Get.to(
                              () => ColibriPostDetailScreen(post: post),
                              opaque: false);
                        },
                      );
                    }
                    postIndex -= visiblePins.length;
                    // 主列表为空（仅置顶帖）：末尾渲染空态提示
                    if (posts.isEmpty) {
                      return postIndex == 0
                          ? emptyWidget
                          : const SizedBox.shrink();
                    }
                    if (postIndex >= posts.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                            child: CircularProgressIndicator(color: cPrimary)),
                      );
                    }
                    final post = posts[postIndex];
                    return ColibriPostCard(
                      key: ValueKey('feed_${post.id}'),
                      post: post,
                      resizeMediaToDisplayBounds: true,
                      onChanged: () {
                        // 删除等操作后：本地立即从两个列表移除 + 刷新当前 tab
                        onPostRemoved?.call(post.id);
                        onRefresh();
                      },
                      onTap: () async {
                        await Get.to(() => ColibriPostDetailScreen(post: post),
                            opaque: false);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

/// Translucent sign-in prompt shown above the public guest feed.
class _GuestGuideCard extends StatelessWidget {
  const _GuestGuideCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: const Color(0xFFFFFFFF),
          child: InkWell(
            onTap: () {
              HapticManager.shared.selection();
              openAuthSheet();
            },
            child: Container(
              constraints: const BoxConstraints(minHeight: 76),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE4E6EA)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined,
                      size: 22, color: Color(0xFF1D1D1F)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(LKeys.feedGuestPostPrompt.tr,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: cMainText)),
                        const SizedBox(height: 3),
                        Text(LKeys.feedGuestFollowPrompt.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: cLightText)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(LKeys.commonSignIn.tr,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_social_service.dart';
import 'package:untitled/common/managers/app_command_handler.dart';
import 'package:untitled/common/managers/bookmark_store.dart';
import 'package:untitled/common/managers/chat_unread_store.dart';
import 'package:untitled/common/managers/guest_session.dart';
import 'package:untitled/common/managers/haptic_manager.dart';
import 'package:untitled/common/managers/reverb_service.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/widgets/guest_auth_sheet.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/colibri_chat/chats_screen.dart';
import 'package:untitled/screens/colibri_home/colibri_home_navigation.dart';
import 'package:untitled/screens/colibri_home/colibri_home_tab.dart';
import 'package:untitled/screens/colibri_feed/colibri_create_post_screen.dart';
import 'package:untitled/screens/colibri_feed/colibri_feed_screen.dart';
import 'package:untitled/models/colibri_post_models.dart';
import 'package:untitled/screens/colibri_guest/guest_locked_view.dart';
import 'package:untitled/screens/colibri_guest/guest_me_page.dart';
import 'package:untitled/screens/colibri_social/colibri_notifications_screen.dart';
import 'package:untitled/screens/colibri_social/colibri_profile_screen.dart';
import 'package:untitled/screens/colibri_social/colibri_search_screen.dart';
import 'package:untitled/utilities/const.dart';

/// ColibriPlus 主界面：Feed / 通知 / Chats / Me 四个核心 Tab（搜索为独立页）。
///
/// 访客态（[GuestSession.isGuest]）：
/// - Feed 切换为访客精选流（见 ColibriFeedScreen 内部分流）；
/// - 通知 / 聊天为「登录后可用」锁定态，不创建业务控制器、不发请求；
/// - 「我的」为访客引导页（登录/注册双按钮）；
/// - 搜索等登录后入口点击弹登录引导。
class ColibriHomeScreen extends StatefulWidget {
  const ColibriHomeScreen({super.key});

  @override
  State<ColibriHomeScreen> createState() => _ColibriHomeScreenState();
}

class _ColibriHomeScreenState extends State<ColibriHomeScreen>
    with WidgetsBindingObserver {
  static const double _navBarHeight = ColibriHomeNavigation.height;
  static const double _navBarBottomMargin = 0;
  static const double _createButtonGap = 24;

  int _index = 0;
  double _tabDirection = 1;
  int _notifUnread = 0; // 社交通知未读
  final Set<int> _visitedTabs = {0};
  final GlobalKey<ColibriFeedScreenState> _feedKey =
      GlobalKey<ColibriFeedScreenState>();
  final GlobalKey<ColibriProfileScreenState> _profileKey =
      GlobalKey<ColibriProfileScreenState>();

  bool get _isGuest => GuestSession.i.isGuest;

  /// WS 回调固定引用（dispose 才能真正 off；旧写法闭包每次新建导致监听泄漏，
  /// 一条通知触发 N 次拉取，和聊天页叠加会拖垮限流）。
  late final void Function(dynamic) _onNotification = _handleNotification;

  /// 用户私有频道的广播通知。
  /// - chat.notification：聊天消息提示，刷新聊天未读角标（会话列表频道在
  ///   首次打开聊天 Tab 前尚未订阅，靠这里兜底实时红点）；
  /// - 其余（main.notification 等）：社交通知，刷新通知未读数。
  void _handleNotification(dynamic payload) {
    final type = payload is Map ? payload['type']?.toString() : null;
    if (type == 'chat.notification') {
      ChatUnreadStore.i.refreshNow();
      return;
    }
    _refreshNotifUnread();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 访客：不建立用户私有频道、不拉未读（通知/聊天锁定态）；公共命令频道已在 main 订阅
    if (_isGuest) return;
    // 登录后建立实时连接并订阅本人通知频道（公共命令频道已在启动时订阅）
    ReverbService.shared.connect();
    ReverbService.shared.subscribePublicCommands();
    // 全局收藏状态与服务端对齐（缓存已秒开在内存；登录/自动登录统一入口，幂等）
    BookmarkStore.i.onEnterHome();
    // 重挂全局指令监听（封禁/维护等）：登出/401 时 disconnect 会清空
    // 事件表，重登后必须重挂，否则实时指令失聪。幂等。
    AppCommandHandler.shared.register();
    _subscribeNotifChannel();
    // 聊天未读角标由 ChatUnreadStore 统一管理（WS 防抖对账），这里只做首拉
    ChatUnreadStore.i.ensureLoaded();
    _refreshNotifUnread();
    // 社交通知实时刷新角标（聊天消息监听在 store 内，避免重复请求）
    ReverbService.shared.on(ReverbService.eventNotification, _onNotification);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 回前台：兜底对账未读（修复角标停留旧值/时有时无）
    if (state == AppLifecycleState.resumed && !_isGuest) {
      ChatUnreadStore.i.refreshNow();
      _refreshNotifUnread();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!_isGuest) {
      ReverbService.shared
          .off(ReverbService.eventNotification, _onNotification);
    }
    super.dispose();
  }

  /// 订阅当前用户的社交通知私有频道。
  void _subscribeNotifChannel() {
    final userId = SessionManager.shared.getColibriUser()?['id'];
    if (userId != null && '$userId'.isNotEmpty) {
      ReverbService.shared.subscribeUser('$userId');
    }
  }

  Future<void> _refreshNotifUnread() async {
    try {
      final count =
          await ColibriSocialService.shared.fetchUnreadNotifications();
      if (mounted && count != _notifUnread) {
        setState(() => _notifUnread = count);
      }
    } catch (_) {}
  }

  Future<void> _openCreatePost() async {
    final sourceIndex = _index;
    final sourceFeedTab =
        sourceIndex == 0 ? _feedKey.currentState?.selectedFeedTabIndex : null;
    final publishedPost = await Get.to<ColibriPost>(
      () => const CreatePostScreen(),
      opaque: false,
    );
    if (publishedPost == null || !mounted) return;
    if (sourceIndex == 0 && sourceFeedTab != null) {
      _feedKey.currentState?.showPublishedPost(
        publishedPost,
        following: sourceFeedTab == 0,
      );
    } else if (sourceIndex == 3) {
      _profileKey.currentState?.showPublishedPost(publishedPost);
    }
  }

  void _onTab(int i) {
    if (i == 1) {
      HapticManager.shared.selection();
      // 访客：搜索/发现为登录后能力，弹引导而不打开搜索页
      if (_isGuest) {
        AuthGate.requireLogin(() {}, feature: LKeys.homeSearchAndDiscovery.tr);
        return;
      }
      // 搜索：以独立页打开，不切换底部 Tab
      Get.to(() => const ColibriSearchScreen(), opaque: false);
      return;
    }
    HapticManager.shared.selection();
    if (!_isGuest) {
      if (i == 2) _refreshNotifUnread(); // 进入「通知」时刷新未读
      if (i == 3) {
        ChatUnreadStore.i.refreshNow(); // 底部红点对账
        // 同时静默刷新会话列表：新会话频道首次拉取前无法收到实时推送，
        // 可能出现「有红点但列表无会话」，进 Tab 主动拉一次兜底（内部 2s 节流）
        if (Get.isRegistered<ColibriChatsController>()) {
          Get.find<ColibriChatsController>().refreshIfStale();
        }
      }
    }
    _selectPage(i > 1 ? i - 1 : i);
  }

  void _selectPage(int pageIndex) {
    if (_index == pageIndex) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _tabDirection = pageIndex > _index ? 1 : -1;
      _index = pageIndex;
      _visitedTabs.add(pageIndex);
    });
  }

  /// 搜索为独立路由，不占用主页的 Tab 索引。
  int get _navIndex => _index >= 1 ? _index + 1 : 0;

  Widget _buildShell(
    BuildContext context, {
    required Widget content,
    required int notificationUnread,
    required int chatUnread,
    required bool showCreateButton,
  }) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // 完整预留系统导航区域，并留出悬浮导航栏与手势条之间的间距。
    final bottomOffset = bottomInset + _navBarBottomMargin;
    return Scaffold(
      backgroundColor: cWhite,
      body: Stack(
        fit: StackFit.expand,
        children: [
          content,
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomOffset,
            child: ColibriHomeNavigation(
              index: _navIndex,
              notificationUnread: notificationUnread,
              chatUnread: chatUnread,
              onSelected: _onTab,
            ),
          ),
          if (showCreateButton)
            Positioned(
              right: 20,
              bottom: bottomOffset + _navBarHeight + _createButtonGap,
              child: ColibriCreateButton(onPressed: _openCreatePost),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 访客态变化（登录转化/登出回退）时整体重建 Tab 内容。
    // isGuest 读取 GuestSession.active（Rx），Obx 据此自动重建。
    return Obx(() {
      final guest = GuestSession.i.isGuest;
      final pages = <Widget>[
        ColibriFeedScreen(key: _feedKey),
        if (_visitedTabs.contains(1))
          guest
              ? const GuestLockedView(kind: GuestLockedKind.notifications)
              : const ColibriNotificationsScreen(asTab: true)
        else
          const SizedBox.shrink(),
        if (_visitedTabs.contains(2))
          guest
              ? const GuestLockedView(kind: GuestLockedKind.chats)
              : const ColibriChatsScreen()
        else
          const SizedBox.shrink(),
        if (_visitedTabs.contains(3) || !guest)
          guest
              ? GuestMePage(onBrowse: () => _selectPage(0))
              : ColibriProfileScreen(
                  key: _profileKey,
                  active: _index == 3,
                )
        else
          const SizedBox.shrink(),
      ];
      final content = Stack(
        fit: StackFit.expand,
        children: [
          for (var i = 0; i < pages.length; i++)
            ColibriHomeTab(
              active: _index == i,
              direction: _tabDirection,
              child: pages[i],
            ),
        ],
      );
      return guest
          ? _buildShell(
              context,
              content: content,
              notificationUnread: 0,
              chatUnread: 0,
              showCreateButton: false,
            )
          : Obx(
              () => _buildShell(
                context,
                content: content,
                notificationUnread: _notifUnread,
                chatUnread: ChatUnreadStore.i.total.value,
                showCreateButton: _index == 0 || _index == 3,
              ),
            );
    });
  }
}

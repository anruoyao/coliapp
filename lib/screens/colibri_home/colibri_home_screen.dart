import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:untitled/common/api_service/colibri_social_service.dart';
import 'package:untitled/common/managers/app_command_handler.dart';
import 'package:untitled/common/managers/bookmark_store.dart';
import 'package:untitled/common/managers/chat_unread_store.dart';
import 'package:untitled/common/managers/guest_session.dart';
import 'package:untitled/common/managers/haptic_manager.dart';
import 'package:untitled/common/managers/reverb_service.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/widgets/guest_auth_sheet.dart';
import 'package:untitled/screens/colibri_chat/chats_screen.dart';
import 'package:untitled/screens/colibri_feed/colibri_create_post_screen.dart';
import 'package:untitled/screens/colibri_feed/colibri_feed_screen.dart';
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
  int _index = 0;
  int _notifUnread = 0; // 社交通知未读
  final Set<int> _visitedTabs = {0};

  bool get _isGuest => GuestSession.i.isGuest;

  /// WS 回调固定引用（dispose 才能真正 off；旧写法闭包每次新建导致监听泄漏，
  /// 一条通知触发 N 次拉取，和聊天页叠加会拖垮限流）。
  late final void Function(dynamic) _onNotification = _handleNotification;

  void _handleNotification(dynamic _) => _refreshNotifUnread();

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
    await Get.to(() => const CreatePostScreen(), opaque: false);
    if (Get.isRegistered<ColibriFeedController>()) {
      Get.find<ColibriFeedController>().refreshActive();
    }
  }

  void _onTab(int i) {
    if (i == 1) {
      HapticManager.shared.selection();
      // 访客：搜索/发现为登录后能力，弹引导而不打开搜索页
      if (_isGuest) {
        AuthGate.requireLogin(() {}, feature: '搜索与发现');
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
    final pageIndex = i > 1 ? i - 1 : i;
    setState(() {
      _index = pageIndex;
      _visitedTabs.add(pageIndex);
    });
  }

  /// 导航项索引 = 栈索引偏移（第 2 项为搜索，不入 IndexedStack）。
  int get _navIndex => _index >= 1 ? _index + 1 : 0;

  Widget _buildNavigation(int notificationUnread, int chatUnread) {
    return LiquidGlassBottomNavBar(
      items: [
        const LiquidGlassTabBarItem(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
          label: '首页',
        ),
        const LiquidGlassTabBarItem(
          icon: Icons.search_outlined,
          selectedIcon: Icons.search_rounded,
          label: '搜索',
        ),
        _notificationNavItem(notificationUnread),
        _chatNavItem(chatUnread),
        const LiquidGlassTabBarItem(
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
          label: '我的',
        ),
      ],
      selectedIndex: _navIndex,
      onChanged: _onTab,
      width: 360,
      height: 68,
      margin: const EdgeInsets.only(bottom: 10),
      itemPadding: 6,
      style: const LiquidGlassStyle(
        shape: LiquidGlassShape.continuousRoundedRectangle(
          cornerRadius: 34,
          clipQuality: LiquidGlassClipQuality.exact,
          borderWidth: 0,
          lightIntensity: 1.0,
          lightDirection: 80,
        ),
        // The bar is the quiet frosted substrate. The selected pill
        // supplies the live refraction above it.
        appearance: LiquidGlassAppearance(
          color: Color(0xD9FFFFFF),
          blur: LiquidGlassBlur(sigmaX: 12, sigmaY: 12),
        ),
        refraction: LiquidGlassRefraction(
          distortion: 0,
          distortionWidth: 1,
          chromaticAberration: 0,
        ),
      ),
      itemStyle: const LiquidGlassNavItemStyle(
        selectedColor: cPrimary,
        unselectedColor: cLightText,
        iconSize: 23,
        labelFontSize: 10.5,
        selectedFontWeight: FontWeight.w700,
      ),
      pillStyle: LiquidGlassNavPillStyle(
        mode: LiquidGlassPillMode.both,
        animated: true,
        keepGlassPillAtRest: true,
        growHeight: 10,
        travelStiffness: 280,
        travelDamping: 31.4,
        glassStyle: LiquidGlassStyle(
          shape: LiquidGlassShape.continuousRoundedRectangle(
            cornerRadius: 30,
            clipQuality: LiquidGlassClipQuality.exact,
            borderWidth: 0,
          ),
          appearance: const LiquidGlassAppearance(
            color: Color(0x241D1D1F),
            blur: LiquidGlassBlur(sigmaX: 0, sigmaY: 0),
            enableInnerRadiusTransparent: true,
          ),
          refraction: const LiquidGlassRefraction(
            magnification: 1.04,
            refractionType: OpticalRefraction(
              refraction: 0.14,
              refractionWidth: 6,
              depth: 0.08,
            ),
            chromaticAberration: 0,
          ),
        ),
        rest: LiquidGlassStyle(
          shape: LiquidGlassShape.continuousRoundedRectangle(
            cornerRadius: 25,
            clipQuality: LiquidGlassClipQuality.exact,
          ),
          appearance: LiquidGlassAppearance(color: cPrimarySoft),
        ),
      ),
    );
  }

  LiquidGlassTabBarItem _notificationNavItem(int unread) {
    return LiquidGlassTabBarItem.custom(
      label: '通知',
      iconBuilder: (context, glyph) => _navGlyph(
        glyph: glyph,
        unread: unread,
        icon: glyph.selected
            ? Icons.notifications_rounded
            : Icons.notifications_none_rounded,
      ),
    );
  }

  LiquidGlassTabBarItem _chatNavItem(int unread) {
    return LiquidGlassTabBarItem.custom(
      label: '聊天',
      iconBuilder: (context, glyph) => _navGlyph(
        glyph: glyph,
        unread: unread,
        icon: glyph.selected
            ? Icons.chat_bubble_rounded
            : Icons.chat_bubble_outline_rounded,
      ),
    );
  }

  Widget _navGlyph({
    required IconData icon,
    required LiquidGlassGlyph glyph,
    required int unread,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: glyph.size, color: glyph.color),
        if (unread > 0)
          Positioned(
            right: -8,
            top: -6,
            child: _UnreadBadge(count: unread, child: const SizedBox()),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 访客态变化（登录转化/登出回退）时整体重建 Tab 内容。
    // isGuest 读取 GuestSession.active（Rx），Obx 据此自动重建。
    return Obx(() {
      final guest = GuestSession.i.isGuest;
      final content = IndexedStack(
        index: _index,
        children: [
          const ColibriFeedScreen(),
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
          if (_visitedTabs.contains(3))
            guest
                ? GuestMePage(onBrowse: () => setState(() => _index = 0))
                : const ColibriProfileScreen()
          else
            const SizedBox.shrink(),
        ],
      );
      return guest
          ? LiquidGlassScaffold(
              backgroundColor: cWhite,
              body: content,
              bottomNavigationBar: _buildNavigation(0, 0),
            )
          : Obx(
              () => LiquidGlassScaffold(
                backgroundColor: cWhite,
                body: content,
                useImpellerBackdrop: false,
                realTimeCapture: false,
                bottomNavigationBar: _buildNavigation(
                  _notifUnread,
                  ChatUnreadStore.i.total.value,
                ),
                lenses: [
                  Positioned(
                    right: 20,
                    bottom: 96,
                    child: GlassCreateButton(onPressed: _openCreatePost),
                  ),
                ],
              ),
            );
    });
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;
  final Widget child;

  const _UnreadBadge({required this.count, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            right: -8,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16),
              decoration: BoxDecoration(
                color: cRed,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 未读消息角标（红色小圆点 + 数字）。

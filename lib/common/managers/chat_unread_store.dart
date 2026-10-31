import 'dart:async';

import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_messenger_service.dart';
import 'package:untitled/common/managers/reverb_service.dart';
import 'package:untitled/common/managers/session_manager.dart';

/// 全局聊天未读数唯一真相（permanent 单例）。
///
/// 修复历史问题：
/// - 底部 Tab 红点时有时无：未读数原来在主页/会话列表各自拉取，WS 事件抖动
///   或 429 时各页面状态不一致。统一到本 store，所有红点观察同一个 [total]。
/// - 进入聊天红点不消：打开聊天页时服务端标记已读后立即 [refreshNow]，
///   无需切换 Tab 才刷新；[activeChatId] 期间收到的消息不计入角标。
/// - 请求风暴：WS 事件高频到达时，服务端对账走 800ms 防抖合并，避免一次消息
///   爆发触发大量 /unread/count 请求打爆限流（429 连锁导致发消息/删会话失败）。
class ChatUnreadStore extends GetxController {
  static ChatUnreadStore get i => Get.find<ChatUnreadStore>();

  /// 全局未读消息总数（底部「聊天」Tab 红点唯一数据源）。
  final RxInt total = 0.obs;

  /// 当前正在前台查看的会话 id（详情页打开期间）；该会话的新消息即时已读。
  String activeChatId = '';

  Timer? _debounce;
  bool _everLoaded = false;
  bool _refreshing = false;

  /// WS 事件回调（同一引用，off 才能真正移除——单例生命周期内只注册一次）。
  late final void Function(dynamic) _onMessageRead = (_) => _onChatChanged();
  late final void Function(dynamic) _onMessageDeleted = (_) => _onChatChanged();

  /// 新消息事件：当前正在查看的会话不计入（详情页会立即标记已读，
  /// 随后的 read 回执事件再触发对账，避免红点闪烁/误增）。
  late final void Function(dynamic) _onMessageReceived = (payload) {
    final chatUuid = _extractChatUuid(payload);
    if (chatUuid != null && chatUuid == activeChatId) return;
    _onChatChanged();
  };

  String? _extractChatUuid(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is Map<String, dynamic>) return data['chat_uuid']?.toString();
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    ReverbService.shared
        .on(ReverbService.eventMessageReceived, _onMessageReceived);
    ReverbService.shared.on(ReverbService.eventMessageRead, _onMessageRead);
    ReverbService.shared
        .on(ReverbService.eventMessageDeleted, _onMessageDeleted);
  }

  @override
  void onClose() {
    _debounce?.cancel();
    ReverbService.shared
        .off(ReverbService.eventMessageReceived, _onMessageReceived);
    ReverbService.shared.off(ReverbService.eventMessageRead, _onMessageRead);
    ReverbService.shared
        .off(ReverbService.eventMessageDeleted, _onMessageDeleted);
    super.onClose();
  }

  /// 首次进入聊天 Tab / 登录后初始化。
  Future<void> ensureLoaded() async {
    if (!_everLoaded) await refreshNow();
  }

  /// 任何会话变化（新消息/删除/已读回执）：防抖合并后与服务端对账。
  void _onChatChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), refreshNow);
  }

  /// 立即与服务端对账（进入/退出聊天页、切 Tab、前后台恢复时调用）。
  /// 并发调用自动合并，避免同一时刻多个页面各发一次请求。
  Future<void> refreshNow() async {
    // 未登录（含访客）不拉取：无 token 请求会触发全局 401 登出流程
    if (!SessionManager.shared.isLogin()) {
      total.value = 0;
      return;
    }
    if (_refreshing) return;
    _refreshing = true;
    _debounce?.cancel();
    try {
      total.value = await ColibriMessengerService.shared.fetchUnreadCount();
      _everLoaded = true;
    } catch (_) {
      // 失败保留旧值；下次事件/切页/回前台再试，不弹错误打扰
    } finally {
      _refreshing = false;
    }
  }

  /// 详情页打开：登记当前会话。该会话内收到的消息不再计入红点。
  void enterChat(String chatId) {
    activeChatId = chatId;
  }

  /// 详情页关闭：清空登记并对账一次（兜底服务端已读状态）。
  Future<void> leaveChat() async {
    activeChatId = '';
    await refreshNow();
  }

  /// 本地乐观归零（服务端标记已读成功后立刻消除角标，零等待）。
  /// [chatUnread] 为该会话进入前的未读数；拿不到时直接以服务端对账为准。
  void applyRead({required int chatUnread}) {
    if (chatUnread > 0) {
      total.value = (total.value - chatUnread).clamp(0, 1 << 31);
    }
  }

  /// 登出/401：重置状态。
  void reset() {
    _debounce?.cancel();
    total.value = 0;
    activeChatId = '';
    _everLoaded = false;
  }
}

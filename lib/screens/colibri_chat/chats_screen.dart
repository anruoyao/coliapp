import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_messenger_service.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
import 'package:untitled/common/managers/chat_unread_store.dart';
import 'package:untitled/common/managers/haptic_manager.dart';
import 'package:untitled/common/managers/reverb_service.dart';
import 'package:untitled/common/widgets/colibri_ui.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/models/colibri_chat_models.dart';
import 'package:untitled/screens/colibri_chat/chat_detail_screen.dart';
import 'package:untitled/screens/colibri_chat/chat_requests_screen.dart';
import 'package:untitled/screens/colibri_chat/create_group_screen.dart';
import 'package:untitled/utilities/const.dart';

class ColibriChatsController extends GetxController {
  final RxList<ColibriChatSummary> chats = <ColibriChatSummary>[].obs;
  final RxBool loading = true.obs;
  final RxInt requestsCount = 0.obs;

  Timer? _refreshDebounce;

  /// 自动刷新最小间隔：WS 事件合并 + 频繁点 Tab 时共同节流，防止打爆限流。
  /// 手动下拉刷新不受此限制。
  DateTime? _lastAutoRefreshAt;
  static const Duration _autoRefreshMinInterval = Duration(seconds: 2);
  bool _autoRefreshInFlight = false;

  /// WS 回调必须持有同一引用，off 才能真正移除（旧写法每次 new 闭包，
  /// 监听随页面进出不断累积，一条消息触发 N 次重拉，是 429 风暴的根源之一）。
  late final void Function(dynamic) _onMessageReceived =
      (_) => _scheduleRefresh();
  late final void Function(dynamic) _onMessageDeleted =
      (_) => _scheduleRefresh();

  @override
  void onInit() {
    super.onInit();
    ReverbService.shared.connect();
    loadChats();
    ReverbService.shared
        .on(ReverbService.eventMessageReceived, _onMessageReceived);
    ReverbService.shared
        .on(ReverbService.eventMessageDeleted, _onMessageDeleted);
  }

  /// WS 高频事件（对方连续发消息）合并为一次静默刷新。
  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce =
        Timer(const Duration(milliseconds: 400), () => refreshSilently());
  }

  /// 点击「聊天」Tab 时调用：静默自动刷新（节流）。
  /// 新会话的私有频道在首次拉到列表前无法订阅，实时事件推不过来，
  /// 因此红点出现但列表不更新——进 Tab 时主动拉一次是可靠兜底。
  Future<void> refreshIfStale() async {
    final now = DateTime.now();
    if (_autoRefreshInFlight) return;
    if (_lastAutoRefreshAt != null &&
        now.difference(_lastAutoRefreshAt!) < _autoRefreshMinInterval) {
      return;
    }
    _lastAutoRefreshAt = now;
    await refreshSilently();
  }

  /// 静默刷新：不切换全屏 loading，列表/空状态保持可见（自动刷新与下拉共用）。
  Future<void> refreshSilently() => loadChats(silent: true);

  /// [silent]：自动刷新/下拉时为 true，保留当前内容不闪全屏转圈（仅首次为 false）。
  Future<void> loadChats({bool silent = false}) async {
    if (!silent) {
      loading.value = true;
    } else {
      if (_autoRefreshInFlight) return;
      _autoRefreshInFlight = true;
    }
    try {
      final list = await ColibriMessengerService.shared.fetchChats();
      chats.assignAll(list);
      // 订阅所有会话的实时频道（新消息/已读/删除）；subscribeChat 内部按频道去重。
      // 新会话本次拉到后即订阅，后续消息实时到达不再依赖手动刷新。
      for (final c in list) {
        ReverbService.shared.subscribeChat(c.chatId);
      }
      // 全局未读角标由 ChatUnreadStore 统一对账（防抖/并发合并）
      ChatUnreadStore.i.refreshNow();
      _refreshRequests();
    } catch (e) {
      // 网络异常静默，下次刷新重试
    } finally {
      if (!silent) loading.value = false;
      if (silent) _autoRefreshInFlight = false;
    }
  }

  /// 进入聊天页时本地即时清掉该会话红点（服务端已读请求同时进行，无需等列表重拉）。
  void markReadLocally(String chatId) {
    var changed = false;
    for (final c in chats) {
      if (c.chatId == chatId && c.unreadCount != 0) {
        c.unreadCount = 0;
        changed = true;
      }
    }
    if (changed) chats.refresh();
  }

  Future<void> _refreshRequests() async {
    try {
      requestsCount.value =
          await ColibriMessengerService.shared.fetchChatRequestsCount();
    } catch (_) {}
  }

  @override
  void onClose() {
    _refreshDebounce?.cancel();
    ReverbService.shared
        .off(ReverbService.eventMessageReceived, _onMessageReceived);
    ReverbService.shared
        .off(ReverbService.eventMessageDeleted, _onMessageDeleted);
    super.onClose();
  }
}

class ColibriChatsScreen extends StatelessWidget {
  const ColibriChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ColibriChatsController());

    return Scaffold(
      backgroundColor: cWhite,
      appBar: AppBar(
        backgroundColor: cWhite,
        surfaceTintColor: cWhite,
        elevation: 0,
        title: const Text('聊天',
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 17, color: cMainText)),
        actions: [
          // 群邀请 / 陌生人请求入口（带未处理数 badge）
          GestureDetector(
            onTap: () async {
              await Get.to(() => ChatRequestsScreen(), opaque: false);
              controller.refreshSilently();
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Obx(() => Badge(
                    isLabelVisible: controller.requestsCount.value > 0,
                    label: Text('${controller.requestsCount.value}'),
                    backgroundColor: cRed,
                    child: const Icon(Icons.person_add_alt_rounded,
                        color: cMainText),
                  )),
            ),
          ),
          // 创建群聊
          IconButton(
            icon: const Icon(Icons.group_add_rounded, color: cMainText),
            onPressed: () async {
              await Get.to(() => const CreateGroupScreen(), opaque: false);
              controller.refreshSilently();
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(
              child: CircularProgressIndicator(color: cPrimary));
        }
        if (controller.chats.isEmpty) {
          // 空状态同样可下拉刷新：新消息到达但列表未实时更新（如新会话频道尚未订阅）时可手动拉取
          return RefreshIndicator(
            color: cPrimary,
            onRefresh: controller.refreshSilently,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                ColibriEmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: '暂无会话',
                  subtitle: '从个人主页发起私信，或创建群聊',
                  topSpacing: 70,
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: cPrimary,
          onRefresh: controller.refreshSilently,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: controller.chats.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: cLightBg),
            itemBuilder: (context, index) {
              final c = controller.chats[index];
              return _ChatTile(
                chat: c,
                onTap: () async {
                  await Get.to(
                      () => ChatDetailScreen(
                            chatId: c.chatId,
                            title: c.chatInfoName,
                            avatarUrl: c.chatInfoAvatarUrl,
                            isGroup: c.isGroup,
                            peerUsername: c.isGroup ? null : c.chatInfoUsername,
                            peerId: c.isGroup ? null : c.chatInfoId,
                            unreadBeforeRead: c.unreadCount,
                          ),
                      opaque: false);
                  controller.refreshSilently();
                },
                onLongPress: () {
                  HapticManager.shared.medium();
                  _showChatMenu(context, controller, c);
                },
              );
            },
          ),
        );
      }),
    );
  }

  /// 会话长按菜单：删除 / 归档 / 清空。
  void _showChatMenu(BuildContext context, ColibriChatsController controller,
      ColibriChatSummary chat) {
    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
        controller.refreshSilently();
      } catch (e) {
        showColibriToast('操作失败',
            message: e.toString(),
            backgroundColor: cRed,
            colorText: Colors.white);
      }
    }

    showColibriSheet(
      context,
      title: '会话操作',
      items: [
        ColibriSheetItem(
          icon: Icons.archive_outlined,
          label: '归档',
          subtitle: '从列表移出，归档后可恢复',
          onTap: () => run(
              () => ColibriMessengerService.shared.archiveChat(chat.chatId)),
        ),
        ColibriSheetItem(
          icon: Icons.delete_sweep_outlined,
          label: '清空聊天记录',
          onTap: () => run(() =>
              ColibriMessengerService.shared.clearConversation(chat.chatId)),
        ),
        ColibriSheetItem(
          icon: Icons.delete_outline_rounded,
          label: '删除会话',
          danger: true,
          onTap: () =>
              run(() => ColibriMessengerService.shared.deleteChat(chat.chatId)),
        ),
      ],
    );
  }
}

class _ChatTile extends StatelessWidget {
  final ColibriChatSummary chat;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ChatTile(
      {required this.chat, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final unread = chat.unreadCount > 0;
    return GestureDetector(
      // opaque：整条可点击（默认 deferToChild 只响应有内容的区域，空白处点击无效）
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // 无头像时用群/人软绿圆底图标
            Container(
              width: 52,
              height: 52,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: cLightBg),
              child: chat.chatInfoAvatarUrl != null &&
                      chat.chatInfoAvatarUrl!.isNotEmpty
                  ? ClipOval(
                      child: MyCachedImage(
                        imageUrl: chat.chatInfoAvatarUrl,
                        width: 52,
                        height: 52,
                        cornerRadius: 26,
                      ),
                    )
                  : Icon(
                      chat.isGroup ? Icons.group_rounded : Icons.person_rounded,
                      color: cLightIcon,
                      size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.chatInfoName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                      color: cMainText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    chat.lastMessage ?? (chat.isDeleted ? '消息已删除' : ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                      color: unread ? cMainText : cLightText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  chat.lastActivityTimeAgo,
                  style: const TextStyle(fontSize: 11.5, color: cLightText),
                ),
                const SizedBox(height: 6),
                if (unread)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                        color: cPrimary,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      chat.unreadCountFormatted,
                      style: const TextStyle(
                          fontSize: 11,
                          color: cBlack,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

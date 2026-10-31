import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled/common/api_service/colibri_messenger_service.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
import 'package:untitled/common/managers/chat_unread_store.dart';
import 'package:untitled/common/managers/haptic_manager.dart';
import 'package:untitled/common/managers/reverb_service.dart';
import 'package:untitled/common/managers/upload_limits_service.dart';
import 'package:untitled/common/widgets/colibri_ui.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/models/colibri_chat_models.dart';
import 'package:untitled/screens/colibri_chat/chats_screen.dart';
import 'package:untitled/screens/colibri_chat/group_members_screen.dart';
import 'package:untitled/screens/colibri_social/colibri_profile_screen.dart';
import 'package:untitled/screens/profile_screen/full_image_screen.dart';
import 'package:untitled/utilities/const.dart';
import 'package:video_player/video_player.dart';

class ColibriChatDetailController extends GetxController {
  final String chatId;

  /// 进入前该会话的未读数（用于本地即时扣减底部红点）。
  final int unreadBeforeRead;
  final RxList<ColibriMessage> messages = <ColibriMessage>[].obs;
  final RxBool loading = true.obs;
  final RxBool loadFailed = false.obs;
  final RxBool sending = false.obs;
  final RxString peerName = ''.obs;
  final RxString peerAvatar = ''.obs;
  final RxString peerUsername = ''.obs;
  final RxBool isGroup = false.obs;
  final RxBool isBlocked = false.obs; // 单聊且双方任一被屏蔽时禁发

  /// 对方（单聊）或所有其他参与人（群聊）已读到的最大消息 id。
  /// 我发的消息 id <= 该值时显示「双勾已读」，否则「单勾已发送」。
  final RxInt peerLastReadMessageId = 0.obs;
  bool _participantsLoaded = false;

  /// 媒体消息缺少 media 数据（历史脏数据/竞态）时的补拉防抖。
  Timer? _mediaRepairTimer;
  int _mediaRepairAttempts = 0;
  static const int _maxMediaRepairAttempts = 3;

  /// 标记已读节流：WS 连续收到多条消息时合并为一次 /read 请求，
  /// 避免对方连发消息瞬间打爆限流（曾因此导致后续 send/delete 全部 429）。
  Timer? _readThrottle;
  bool _readInFlight = false;

  /// WS 回调同一引用，off 才能真正注销（旧写法 tear-off 每次是新实例导致泄漏）。
  late final void Function(dynamic) _onMessageReceived = _handleReceived;
  late final void Function(dynamic) _onMessageDeleted = _handleDeleted;
  late final void Function(dynamic) _onMessageRead = _handleReadReceipt;

  ColibriChatDetailController({
    required this.chatId,
    String? title,
    String? avatarUrl,
    String? username,
    bool? group,
    this.unreadBeforeRead = 0,
  }) {
    peerName.value = title ?? '';
    peerAvatar.value = avatarUrl ?? '';
    peerUsername.value = username ?? '';
    isGroup.value = group ?? false;
  }

  @override
  void onInit() {
    super.onInit();
    ChatUnreadStore.i.enterChat(chatId);
    _load();
    ReverbService.shared
        .on(ReverbService.eventMessageReceived, _onMessageReceived);
    ReverbService.shared
        .on(ReverbService.eventMessageDeleted, _onMessageDeleted);
    ReverbService.shared.on(ReverbService.eventMessageRead, _onMessageRead);
  }

  Future<void> _load() async {
    loading.value = true;
    loadFailed.value = false;
    try {
      // 会话信息（群聊名称、头像等）
      final data = await ColibriMessengerService.shared.fetchChatData(chatId);
      final info = data['chat_info'];
      if (info is Map<String, dynamic>) {
        if (peerName.value.isEmpty)
          peerName.value = info['name']?.toString() ?? '';
        if (peerAvatar.value.isEmpty)
          peerAvatar.value = info['avatar_url']?.toString() ?? '';
        // 单聊对方用户名（头部点击跳转个人主页）
        final username = info['username']?.toString() ?? '';
        if (username.isNotEmpty) peerUsername.value = username;
        isGroup.value = data['is_group'] == true;
        // 解析 BLOCKING：单聊且任一方屏蔽则禁发
        if (!isGroup.value) {
          final meta = info['meta'] is Map<String, dynamic>
              ? info['meta'] as Map<String, dynamic>
              : const <String, dynamic>{};
          final rel = meta['relationship'] is Map<String, dynamic>
              ? meta['relationship'] as Map<String, dynamic>
              : const <String, dynamic>{};
          final block = rel['block'] is Map<String, dynamic>
              ? rel['block'] as Map<String, dynamic>
              : const <String, dynamic>{};
          isBlocked.value = block['blocking'] == true;
        }
      }

      final list = await ColibriMessengerService.shared.fetchMessages(chatId);
      _assignSorted(list);

      // 解析对方已读位置：relations.participants 已排除自己，取最大 last_read_message_id
      if (!_participantsLoaded) {
        final rels = data['relations'];
        if (rels is Map<String, dynamic> && rels['participants'] is List) {
          var maxRead = 0;
          for (final p in rels['participants'] as List) {
            if (p is Map<String, dynamic>) {
              final v = int.tryParse('${p['last_read_message_id']}') ?? 0;
              if (v > maxRead) maxRead = v;
            }
          }
          peerLastReadMessageId.value = maxRead;
        }
        _participantsLoaded = true;
      }

      // 列表存在「媒体类型但无媒体数据」的消息（历史失败残留/竞态）：延迟补拉一次
      _scheduleMediaRepair(list);

      // 订阅实时频道
      ReverbService.shared.subscribeChat(chatId);
      // 进入会话即已读：本地角标立即清零 + 节流标记服务端
      _applyLocalRead();
      _markAsReadThrottled(immediate: true);
    } catch (_) {
      // 曾出现首屏请求被限流（429）导致消息空白，标记失败态让用户下拉重试
      loadFailed.value = true;
    } finally {
      loading.value = false;
    }
  }

  /// 本地即时清除红点（底部 Tab + 会话列表），零网络等待。
  void _applyLocalRead() {
    ChatUnreadStore.i.applyRead(chatUnread: unreadBeforeRead);
    if (Get.isRegistered<ColibriChatsController>()) {
      Get.find<ColibriChatsController>().markReadLocally(chatId);
    }
  }

  DateTime? _lastReadAt;
  static const Duration _readWindow = Duration(seconds: 3);

  /// 已读节流（前缘立即 + 尾请求）：窗口外的调用立即发，窗口内的连续消息
  /// 在窗口结束时合并补发一次——既保证秒级已读，又不会被消息风暴打爆限流。
  void _markAsReadThrottled({bool immediate = false}) {
    final now = DateTime.now();
    final elapsed = _lastReadAt == null ? null : now.difference(_lastReadAt!);
    if (immediate || elapsed == null || elapsed >= _readWindow) {
      _readThrottle?.cancel();
      _lastReadAt = now;
      _doMarkAsRead();
      return;
    }
    _readThrottle?.cancel();
    _readThrottle = Timer(_readWindow - elapsed, () {
      _lastReadAt = DateTime.now();
      _doMarkAsRead();
    });
  }

  Future<void> _doMarkAsRead() async {
    if (_readInFlight) return;
    _readInFlight = true;
    try {
      await ColibriMessengerService.shared.markAsRead(chatId);
    } catch (_) {
      // 已读失败静默：下次消息事件或退出页面会再对账
    } finally {
      _readInFlight = false;
    }
  }

  void _handleReceived(dynamic payload) {
    Map<String, dynamic>? msgJson;
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is Map<String, dynamic>) {
        msgJson = data;
      }
    }
    if (msgJson == null) return;
    final msg = ColibriMessage.fromJson(msgJson);
    if (msg.chatUuid != chatId) return;

    final idx = messages.indexWhere((m) => m.id == msg.id);
    if (idx == -1) {
      // 严格按 id 升序插入（列表正序展示）：不能无脑追加到末尾，
      // 弱网下 WS 帧乱序到达会导致消息位置颠倒。
      var insertAt = messages.length;
      for (var i = 0; i < messages.length; i++) {
        if (messages[i].id > msg.id) {
          insertAt = i;
          break;
        }
      }
      messages.insert(insertAt, msg);
      _scheduleMediaRepair([msg]);
    } else {
      // 同一消息二次推送（如媒体晚到）：用完整数据原位替换
      messages[idx] = msg;
    }
    // 正在查看本会话：收到即已读（本地角标保持 0，服务端标记走节流）
    ChatUnreadStore.i.applyRead(chatUnread: 1);
    _markAsReadThrottled();
  }

  /// 对方已读回执：推进已读水位（取最大值，乱序到达也安全）。
  void _handleReadReceipt(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is Map<String, dynamic>) {
        final v = int.tryParse('${data['last_read_message_id']}') ?? 0;
        if (v > peerLastReadMessageId.value) peerLastReadMessageId.value = v;
      }
    }
  }

  /// 按 id 升序写入消息（后端已按 created_at,id 双键排序，客户端再兜底一次）。
  void _assignSorted(List<ColibriMessage> list) {
    final sorted = [...list]..sort((a, b) => a.id.compareTo(b.id));
    messages.assignAll(sorted);
  }

  /// 检测到「图片/视频/语音类型但没有可用媒体」的消息时，短延迟重拉列表补齐。
  /// 正常路径不会出现（后端上传完成才广播）；用于兜底历史脏数据与极端竞态，
  /// 避免界面停留在空白气泡。
  void _scheduleMediaRepair(List<ColibriMessage> incoming) {
    final hasBrokenMedia = incoming.any((m) => m.isMediaWithoutData);
    if (!hasBrokenMedia || _mediaRepairAttempts >= _maxMediaRepairAttempts)
      return;
    _mediaRepairTimer?.cancel();
    _mediaRepairAttempts++;
    _mediaRepairTimer = Timer(const Duration(seconds: 2), () async {
      try {
        final list = await ColibriMessengerService.shared.fetchMessages(chatId);
        final stillBroken = list.any((m) => m.isMediaWithoutData);
        _assignSorted(list);
        // 仍缺媒体且未到上限：再等一轮（后端处理可能较慢）
        if (stillBroken) _scheduleMediaRepair(list);
      } catch (_) {}
    });
  }

  void _handleDeleted(dynamic payload) {
    int? messageId;
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is Map<String, dynamic>) {
        messageId = data['message_id'] is int
            ? data['message_id'] as int
            : int.tryParse('${data['message_id']}');
      }
    }
    if (messageId == null) return;
    messages.removeWhere((m) => m.id == messageId);
  }

  /// 发送文本。
  Future<void> sendText(String content) async {
    final text = content.trim();
    if (text.isEmpty || sending.value) return;
    // 点击发送瞬间振动（不等待网络/重拉，避免振动延迟）
    HapticManager.shared.light();
    sending.value = true;
    try {
      await ColibriMessengerService.shared
          .sendText(chatId: chatId, content: text);
      // 发送成功后重拉（服务端不返回消息对象），按 id 严格排序
      final list = await ColibriMessengerService.shared.fetchMessages(chatId);
      _assignSorted(list);
    } catch (e) {
      // 展示服务端错误（如对方关闭私信/仅粉丝可私信）
      showColibriToast('发送失败',
          message: e.toString(),
          backgroundColor: cRed,
          colorText: Colors.white);
    } finally {
      sending.value = false;
    }
  }

  /// 发送图片。
  Future<void> sendImage() async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null || sending.value) return;

    // 本地预检测：超出后台配置的图片大小限制时立即提示
    final msg = await UploadLimitsService.shared
        .check(File(file.path).lengthSync(), 'image');
    if (msg != null) {
      showColibriToast('图片过大',
          message: msg, backgroundColor: cRed, colorText: Colors.white);
      return;
    }

    sending.value = true;
    // 真正开始上传时立即振动（不等待网络）
    HapticManager.shared.light();
    try {
      await ColibriMessengerService.shared.sendMedia(
        chatId: chatId,
        filePath: file.path,
        mediaType: 'image',
      );
      final list = await ColibriMessengerService.shared.fetchMessages(chatId);
      _assignSorted(list);
    } catch (e) {
      showColibriToast('发送失败',
          message: e.toString(),
          backgroundColor: cRed,
          colorText: Colors.white);
    } finally {
      sending.value = false;
    }
  }

  /// 删除消息。
  Future<void> deleteMessage(ColibriMessage message) async {
    try {
      await ColibriMessengerService.shared
          .deleteMessage(message.id, deleteForAll: message.isMine);
      messages.removeWhere((m) => m.id == message.id);
    } catch (_) {}
  }

  @override
  void onClose() {
    _readThrottle?.cancel();
    _mediaRepairTimer?.cancel();
    ReverbService.shared
        .off(ReverbService.eventMessageReceived, _onMessageReceived);
    ReverbService.shared
        .off(ReverbService.eventMessageDeleted, _onMessageDeleted);
    ReverbService.shared.off(ReverbService.eventMessageRead, _onMessageRead);
    // 退出会话：注销活跃会话并用服务端未读数兜底对账一次
    ChatUnreadStore.i.leaveChat();
    super.onClose();
  }
}

class ChatDetailScreen extends StatelessWidget {
  final String chatId;
  final String? title;
  final String? avatarUrl;
  final bool isGroup;

  /// 单聊对方用户名/uid（头部点击跳转个人主页）。
  final String? peerUsername;
  final int? peerId;

  /// 进入前未读数（本地即时扣红点用）。
  final int unreadBeforeRead;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    this.title,
    this.avatarUrl,
    this.isGroup = false,
    this.peerUsername,
    this.peerId,
    this.unreadBeforeRead = 0,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      ColibriChatDetailController(
        chatId: chatId,
        title: title,
        avatarUrl: avatarUrl,
        username: peerUsername,
        group: isGroup,
        unreadBeforeRead: unreadBeforeRead,
      ),
      tag: chatId,
    );

    return Scaffold(
      backgroundColor: cWhite,
      appBar: AppBar(
        backgroundColor: cWhite,
        surfaceTintColor: cWhite,
        elevation: 0,
        titleSpacing: 0,
        title: Obx(() {
          final row = Row(
            children: [
              if (controller.peerAvatar.value.isNotEmpty) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: cLightBg,
                  backgroundImage: NetworkImage(controller.peerAvatar.value),
                  onBackgroundImageError: (_, __) {},
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  controller.peerName.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: cMainText),
                ),
              ),
              // 单聊：头部整体可点，右侧轻提示箭头
              if (!controller.isGroup.value &&
                  controller.peerUsername.value.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 4, right: 2),
                  child: Icon(Icons.chevron_right_rounded,
                      size: 18, color: cLightIcon),
                ),
            ],
          );
          // 单聊点头部（头像/名称）跳转对方个人主页；群聊不响应
          if (!controller.isGroup.value &&
              controller.peerUsername.value.isNotEmpty) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Get.to(
                  () => ColibriProfileScreen(
                      username: controller.peerUsername.value),
                  opaque: false),
              child: row,
            );
          }
          return row;
        }),
        leading: BackButton(color: cBlack, onPressed: () => Get.back()),
        actions: [
          // 群聊：成员管理入口
          Obx(() => controller.isGroup.value
              ? IconButton(
                  icon: const Icon(Icons.people_alt_rounded, color: cMainText),
                  onPressed: () => Get.to(
                      () => GroupMembersScreen(chatId: controller.chatId),
                      opaque: false),
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const Center(
                    child: CircularProgressIndicator(color: cPrimary));
              }
              // 下拉刷新：首屏失败（如 429）或消息异常空白时可手动重试
              final list = controller.messages.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        controller.loadFailed.value
                            ? ColibriEmptyState(
                                icon: Icons.cloud_off_rounded,
                                title: '消息加载失败',
                                subtitle: '下拉重新加载，或点击重试',
                                topSpacing: 60,
                                action: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: controller._load,
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 16),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 22, vertical: 9),
                                    decoration: BoxDecoration(
                                      color: cPrimary,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text('重试',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: cWhite)),
                                  ),
                                ),
                              )
                            : const ColibriEmptyState(
                                icon: Icons.waving_hand_rounded,
                                title: '开始聊天吧',
                                subtitle: '打个招呼，发送第一条消息',
                                topSpacing: 60,
                              ),
                      ],
                    )
                  : ListView.builder(
                      reverse: false,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      itemCount: controller.messages.length,
                      itemBuilder: (context, index) {
                        final msg = controller.messages[index];
                        // 空白消息（历史上传失败残留：无文本无媒体）不渲染气泡
                        if (msg.isEmptyBubble) return const SizedBox.shrink();
                        final isRead = msg.isMine &&
                            controller.peerLastReadMessageId.value >= msg.id;
                        return GestureDetector(
                          onLongPress: () {
                            HapticManager.shared.medium();
                            _confirmDelete(context, controller, msg);
                          },
                          child: _MessageBubble(
                            message: msg,
                            showSenderName: !controller.isGroup.value,
                            isRead: isRead,
                          ),
                        );
                      },
                    );
              return RefreshIndicator(
                color: cPrimary,
                onRefresh: controller._load,
                child: list,
              );
            }),
          ),
          Obx(() => controller.isBlocked.value
              ? _BlockedBar()
              : _MessageInputBar(controller: controller)),
        ],
      ),
    );
  }

  /// 消息长按：删除确认。
  void _confirmDelete(BuildContext context,
      ColibriChatDetailController controller, ColibriMessage msg) {
    showColibriSheet(
      context,
      title: '消息操作',
      items: [
        ColibriSheetItem(
          icon: Icons.delete_outline_rounded,
          label: msg.isMine ? '删除消息' : '从我的视角删除',
          subtitle: msg.isMine ? '所有人将不再看到这条消息' : '仅从你的设备移除',
          danger: true,
          onTap: () => controller.deleteMessage(msg),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ColibriMessage message;
  final bool showSenderName;

  /// 仅自己的消息使用：对方已读到该消息（双勾）与否（单勾）。
  final bool isRead;

  const _MessageBubble(
      {required this.message,
      required this.showSenderName,
      this.isRead = false});

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine;
    final hasMedia = message.hasUsableMedia;
    final mediaType = message.media?.type ?? '';

    Widget bubbleContent;
    if (hasMedia && mediaType == 'image') {
      // 图片消息：点击打开全屏查看
      bubbleContent = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Get.to(
            () => FullImageScreen(
                  image: message.media!.sourceUrl,
                  tag: 'chat_img_${message.id}',
                ),
            opaque: false),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: MyCachedImage(
              imageUrl: message.media!.sourceUrl,
              width: 210,
              height: 270,
              cornerRadius: 12),
        ),
      );
    } else if (hasMedia && mediaType == 'audio') {
      // 录音消息：点击播放/暂停
      bubbleContent = _AudioBubble(message: message, mine: mine);
    } else if (hasMedia) {
      // 视频/其他媒体：缩略图 + 播放占位
      final thumb = message.media!.thumbnailUrl;
      bubbleContent = Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: thumb != null && thumb.isNotEmpty
                ? MyCachedImage(
                    imageUrl: thumb, width: 200, height: 150, cornerRadius: 12)
                : Container(width: 200, height: 150, color: Colors.black26),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
                color: Colors.black45, shape: BoxShape.circle),
            child: const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 30),
          ),
        ],
      );
    } else {
      bubbleContent = Text(
        message.content,
        style: TextStyle(fontSize: 15, color: mine ? cWhite : cMainText),
      );
    }

    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 260),
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: hasMedia
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: mine ? cPrimary : cLightBg,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(mine ? 16 : 4),
          bottomRight: Radius.circular(mine ? 4 : 16),
        ),
      ),
      child: bubbleContent,
    );

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!mine && showSenderName && message.senderName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 2),
              child: Text(message.senderName,
                  style: const TextStyle(fontSize: 11, color: cLightText)),
            ),
          bubble,
          // 时间 + 已读回执（与网页端一致：自己的消息单勾=已发送，双勾=对方已读）
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.timeAgo.isNotEmpty)
                  Text(message.timeAgo,
                      style:
                          const TextStyle(fontSize: 10.5, color: cLightText)),
                if (mine) ...[
                  const SizedBox(width: 5),
                  Icon(
                    isRead ? Icons.done_all_rounded : Icons.check_rounded,
                    size: 14,
                    color: isRead ? cGreen : cLightIcon,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockedBar extends StatelessWidget {
  const _BlockedBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
            color: cWhite, border: Border(top: BorderSide(color: cLightBg))),
        child: const Column(
          children: [
            Icon(Icons.block_rounded, color: cLightIcon, size: 20),
            SizedBox(height: 6),
            Text('屏蔽状态',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cLightText)),
          ],
        ),
      ),
    );
  }
}

class _MessageInputBar extends StatefulWidget {
  final ColibriChatDetailController controller;

  const _MessageInputBar({required this.controller});

  @override
  State<_MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<_MessageInputBar> {
  final TextEditingController _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send() {
    if (_text.text.trim().isEmpty) return;
    widget.controller.sendText(_text.text);
    _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: const BoxDecoration(
            color: cWhite, border: Border(top: BorderSide(color: cLightBg))),
        child: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.controller.sendImage,
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                    color: cPrimarySoft, shape: BoxShape.circle),
                child: const Icon(Icons.image_rounded, color: cGreen, size: 23),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _text,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: '输入消息...',
                  hintStyle: const TextStyle(color: cLightText, fontSize: 14.5),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  filled: true,
                  fillColor: cLightBg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: cPrimary, width: 1.4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                    color: cPrimary, shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded, color: cWhite, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 录音消息气泡：点击播放/暂停（video_player 播放音频 URL）。
class _AudioBubble extends StatefulWidget {
  final ColibriMessage message;
  final bool mine;

  const _AudioBubble({required this.message, required this.mine});

  @override
  State<_AudioBubble> createState() => _AudioBubbleState();
}

class _AudioBubbleState extends State<_AudioBubble> {
  VideoPlayerController? _controller;
  bool _loading = false;
  bool _playing = false;

  /// 后端 metadata.duration 是 {hours, minutes, seconds}，格式化为 mm:ss。
  String get _durationText {
    final d = widget.message.media?.metadata['duration'];
    if (d is Map) {
      final m = int.tryParse('${d['minutes'] ?? 0}') ?? 0;
      final s = int.tryParse('${d['seconds'] ?? 0}') ?? 0;
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '';
  }

  /// 播放状态监听：播放结束（isPlaying 变 false）时自动把按钮复位为"播放"。
  void _onPlayerStatus() {
    final c = _controller;
    if (c == null || !mounted) return;
    final playing = c.value.isPlaying;
    if (playing != _playing) {
      setState(() => _playing = playing);
    }
  }

  Future<void> _toggle() async {
    final url = widget.message.media!.sourceUrl;
    if (_controller == null) {
      setState(() => _loading = true);
      try {
        final c = VideoPlayerController.networkUrl(Uri.parse(url));
        _controller = c;
        c.addListener(_onPlayerStatus);
        await c.initialize();
        await c.play();
      } catch (_) {
        // 播放失败静默
      }
      _loading = false;
      if (mounted) setState(() {});
      return;
    }

    final c = _controller!;
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      // 播放完后重播：先回到开头
      if (c.value.isCompleted) {
        await c.seekTo(Duration.zero);
      }
      await c.play();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.mine ? cWhite : cPrimary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggle,
      child: Container(
        width: 180,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            _loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: color))
                : Icon(_playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: color, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('语音',
                      style: TextStyle(
                          fontSize: 14,
                          color: widget.mine ? cWhite : cMainText)),
                  if (_durationText.isNotEmpty)
                    Text(_durationText,
                        style: TextStyle(
                            fontSize: 12,
                            color: widget.mine
                                ? cWhite.withValues(alpha: 0.72)
                                : cLightText)),
                ],
              ),
            ),
            Icon(Icons.graphic_eq_rounded, color: color, size: 22),
          ],
        ),
      ),
    );
  }
}

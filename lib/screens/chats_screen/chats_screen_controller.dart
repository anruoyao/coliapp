import 'dart:async';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/chat_service.dart';
import 'package:untitled/common/controller/cupertino_controller.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/managers/ws_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/chat.dart';
import 'package:untitled/screens/sheets/confirmation_sheet.dart';

/// 会话列表控制器（替代 Firestore users/{me}/userList + chats 集合监听）。
///
/// - 列表数据来自 /api/chat/fetchConversations
/// - 实时更新：监听 WS 用户频道 conversation.updated 事件（防抖刷新）
class ChatsScreensController extends CupertinoController {
  List<ChatUserRoom> chats = [];
  List<ChatUserRoom> roomChats = [];
  bool isSearching = false;
  List<ChatUserRoom> filterChats = [];
  List<ChatUserRoom> filterRoomChats = [];
  TextEditingController textEditingController = TextEditingController();

  Timer? _refreshDebounce;
  bool _disposed = false;

  /// 底部 Tab 红点：排除当前正在查看的会话（聊天中收到新消息不算未读）。
  bool get isNewMessage {
    final activeConversationId = SessionManager.shared.getStoredConversation();
    return (chats + roomChats).any((chat) =>
        chat.conversationId != activeConversationId &&
        ((chat.newMsgCount ?? 0) > 0 || chat.newMsgCount == -1));
  }

  var myUser = SessionManager.shared.getUser();

  void onChange(String keyword) {
    filterChats = chats.where((element) {
      return element.title?.toLowerCase().contains(keyword.toLowerCase()) ??
          false;
    }).toList();

    filterRoomChats = roomChats.where((element) {
      return element.title?.toLowerCase().contains(keyword.toLowerCase()) ??
          false;
    }).toList();

    update();
  }

  @override
  void onReady() {
    // 静默加载：会话列表在主页（Tab 预加载）时就拉取，不弹全屏加载框，
    // 否则会与主页帖子加载动画叠加出现两个加载圆圈。
    fetchChats(showLoading: false);
    super.onReady();
  }

  @override
  void onInit() {
    WsManager.shared
        .addListener('conversation.updated', _onConversationUpdated);
    super.onInit();
  }

  /// WS 收到会话变更事件：防抖 300ms 后整表刷新（简单可靠）。
  void _onConversationUpdated(Map<String, dynamic> data) {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!_disposed) fetchChats(showLoading: false);
    });
  }

  void fetchChats({bool showLoading = true}) {
    if (showLoading) startLoading();
    ChatService.shared.fetchConversations(
      completion: (conversations) {
        if (showLoading) stopLoading();
        chats = conversations.where((c) => c.type != 2).toList();
        roomChats = conversations.where((c) => c.type == 2).toList();
        onChange(textEditingController.text);
      },
      onError: (error) {
        if (showLoading) stopLoading();
      },
    );
  }

  void clearChat(ChatUserRoom chatUserRoom) {
    showColibriBottomSheet(
      ConfirmationSheet(
        desc: LKeys.clearChatDesc,
        buttonTitle: LKeys.clearChat,
        onTap: () {
          ChatService.shared.clearChat(
              conversationId: chatUserRoom.conversationId ?? '',
              completion: () {
                chatUserRoom.lastMsg = '';
                update();
              });
          Get.back();
        },
      ),
    );
  }

  /// 本地清除指定会话的未读红点（进入/退出聊天页时调用，立即生效不等网络）。
  /// filterChats/filterRoomChats 与 chats/roomChats 持有同一批对象实例，一并生效。
  void clearUnreadBadge(String? conversationId) {
    if (conversationId == null || conversationId.isEmpty) return;
    var changed = false;
    for (final chat in [...chats, ...roomChats]) {
      if (chat.conversationId == conversationId && chat.newMsgCount != 0) {
        chat.newMsgCount = 0;
        changed = true;
      }
    }
    if (changed) update();
  }

  void markToggle(ChatUserRoom chatUserRoom) {
    // -1 = 标记未读红点，0 = 取消（对齐原 Firestore 行为）
    final value = (chatUserRoom.newMsgCount == 0) ? -1 : 0;
    ChatService.shared.setUnread(
        conversationId: chatUserRoom.conversationId ?? '', value: value);
    chatUserRoom.newMsgCount = value;
    update();
  }

  void deleteChat(ChatUserRoom chatUserRoom) {
    showColibriBottomSheet(
      ConfirmationSheet(
        desc: LKeys.deleteChatDesc,
        buttonTitle: LKeys.delete,
        onTap: () {
          ChatService.shared.deleteChat(
              conversationId: chatUserRoom.conversationId ?? '',
              completion: () {});
          chats.removeWhere((element) =>
              element.conversationId == chatUserRoom.conversationId);
          roomChats.removeWhere((element) =>
              element.conversationId == chatUserRoom.conversationId);
          onChange(textEditingController.text);
          Get.back();
        },
      ),
    );
  }

  @override
  void onClose() {
    _disposed = true;
    _refreshDebounce?.cancel();
    WsManager.shared
        .removeListener('conversation.updated', _onConversationUpdated);
    super.onClose();
  }
}

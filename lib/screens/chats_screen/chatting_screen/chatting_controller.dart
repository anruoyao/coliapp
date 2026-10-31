import 'dart:async';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';

import 'package:detectable_text_field/detectable_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/chat_service.dart';
import 'package:untitled/common/api_service/moderator_service.dart';
import 'package:untitled/common/api_service/room_service.dart';
import 'package:untitled/common/api_service/user_service.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/managers/logger.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/managers/ws_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/chat.dart';
import 'package:untitled/models/invitations_model.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/models/room_model.dart';
import 'package:untitled/models/story.dart';
import 'package:untitled/screens/chats_screen/chats_screen_controller.dart';
import 'package:untitled/screens/chats_screen/chatting_screen/block_user_controller.dart';
import 'package:untitled/screens/chats_screen/chatting_screen/image_video_chat_picker.dart';
import 'package:untitled/screens/rooms_screen/room_controller.dart';
import 'package:untitled/screens/sheets/confirmation_sheet.dart';
import 'package:untitled/utilities/const.dart';
import 'package:untitled/utilities/firebase_const.dart';

/// 本地化聊天控制器（替代 Firestore 实时读写）。
///
/// - 消息收发走自建 /api/chat/* 接口
/// - 实时更新通过 WsManager 订阅会话频道 conv.{id}.{key}
/// - 分页：fetchMessages(before_id) 游标式拉取更早消息
class ChattingController extends BlockUserController {
  ScrollController scrollController = ScrollController();
  List<ChatMessage> messages = [];
  ChatUserRoom? chatUserRoom;
  Room? room;
  User? user;
  User? myUser = SessionManager.shared.getUser();
  bool hasMore = true;
  bool isLoadingOld = false;
  bool shouldCallAPI = true;
  bool conversationLoaded = false;

  DetectableTextEditingController messageTextController =
      DetectableTextEditingController(
    detectedStyle: MyTextStyle.gilroySemiBold(size: 16, color: cPrimary)
        .copyWith(height: 1.2),
    regExp: detectionRegExp(atSign: false, url: true, hashtag: false)!,
  );

  ChattingController(
      {this.room, this.user, ChatUserRoom? chatUserRoom, bool? shouldCallAPI}) {
    if (chatUserRoom != null) {
      this.chatUserRoom = chatUserRoom;
    } else if (room != null) {
      this.chatUserRoom = ChatUserRoom(
          conversationId: null,
          title: room?.title ?? '',
          profileImage: room?.photo ?? '',
          userIdOrRoomId: room?.id,
          type: 2);
    } else if (user != null) {
      this.chatUserRoom = ChatUserRoom(
          conversationId: null,
          title: user?.fullName ?? '',
          profileImage: user?.profile ?? '',
          userIdOrRoomId: user?.id,
          type: 1);
    }
    this.shouldCallAPI = shouldCallAPI ?? true;
    stopNotification();
    print('In Chat Room: ${chatUserRoom?.conversationId}');
  }

  @override
  void onReady() {
    if (shouldCallAPI) {
      fetchDetailWithAPI();
    }
    super.onReady();
  }

  @override
  void onInit() {
    scrollController.addListener(() {
      // reverse 列表：offset == 0 表示滚到了顶部（更早消息方向）
      if (scrollController.offset <= 0 && !isLoading.value && !isLoadingOld) {
        loadOldData();
      }
    });

    // 实时新消息
    WsManager.shared.addListener('message.new', _onWsMessage);

    super.onInit();
  }

  /// WS 推来的新消息（可能是自己发的，去重后插入）。
  void _onWsMessage(Map<String, dynamic> data) {
    final eventConversationId = data['conversationId']?.toString();
    if (eventConversationId != null &&
        eventConversationId != '${chatUserRoom?.conversationId}') {
      return;
    }
    var message = ChatMessage.fromJson(data);
    if (message.id == null) return;
    if (messages.any((m) => m.id == message.id)) return; // 自己发的已通过响应插入

    messages.insert(0, message);
    update();
  }

  void fetchDetailWithAPI() {
    startLoading();
    ChatService.shared.getOrCreateConversation(
      peerId: user?.id,
      roomId: room?.id,
      conversationId: chatUserRoom?.conversationId,
      completion: (conversation) {
        // 保留本地已知的 type（新会话时后端可能返回 0/1）
        chatUserRoom = conversation;
        if (chatUserRoom?.type == null || chatUserRoom?.type == 0) {
          if (room != null) {
            chatUserRoom?.type = 2;
          } else if (user != null) {
            chatUserRoom?.type = 1;
          }
        }
        conversationLoaded = true;

        // 订阅会话频道，接收实时消息
        if (chatUserRoom?.conversationKey != null) {
          WsManager.shared.subscribeConversation(
              chatUserRoom?.conversationId ?? '',
              chatUserRoom!.conversationKey!);
        }

        // 进入会话即视为已读：清除列表红点并同步服务端
        if ((chatUserRoom?.newMsgCount ?? 0) != 0) {
          markAsRead();
        }

        fetchMessages();
        update();
        stopLoading();

        // 单聊：拉取对方与自己资料（头像/关注状态/屏蔽状态展示用）
        if (chatUserRoom?.type != 2) {
          UserService.shared
              .fetchProfile(chatUserRoom?.userIdOrRoomId?.toInt() ?? 0, (user) {
            this.user = user;
            update();
          });
          UserService.shared.fetchMyProfile(
              userID: myUser?.id ?? 0,
              myUserId: chatUserRoom?.userIdOrRoomId?.toInt(),
              completion: (user) {
                myUser = user;
                update();
              });
        } else {
          // 房间：拉取房间详情（成员列表用于显示发言人名字）
          this.room = Room(id: chatUserRoom?.userIdOrRoomId?.toInt() ?? 0);
          RoomService.shared.fetchRoom(
              chatUserRoom?.userIdOrRoomId?.toInt() ?? 0,
              shouldShowMembers: true, (room) {
            this.room = room;
            update();
          });
        }
      },
      onError: (error) {
        stopLoading();
      },
    );
  }

  void sendStoryReply({required Story story, required String reply}) {
    messageTextController.text = reply;
    commonSend(
        type: MessageType.storyReply,
        content: '',
        thumbnail: story.thumbnailForReply ?? '',
        storyId: story.id);
  }

  void sendMsg({MessageType type = MessageType.text}) {
    if (messageTextController.text.isEmpty) {
      return;
    }
    commonSend(type: MessageType.text);
  }

  void commonSend(
      {required MessageType type,
      String content = '',
      String thumbnail = '',
      num? storyId}) {
    if (chatUserRoom?.iAmBlocked == true) {
      return;
    }
    if (chatUserRoom?.iBlocked == true) {
      unblockUser(user, () {});
      return;
    }

    final text = messageTextController.text;
    final conversationId = chatUserRoom?.conversationId;
    if (conversationId == null || conversationId.isEmpty) {
      return; // 会话尚未就绪
    }

    ChatService.shared.sendMessage(
      conversationId: conversationId,
      msgType: type.value,
      msg: text, // 图片/视频的附言也放在 msg
      content: content,
      thumbnail: thumbnail,
      storyId: storyId,
      completion: (message) {
        if (message.id != null && !messages.any((m) => m.id == message.id)) {
          messages.insert(0, message);
          update();
        }
        // 自己的消息也同步会话列表状态
        chatUserRoom?.lastMsg = text.isEmpty
            ? (type == MessageType.image ? 'Image' : 'Video')
            : text;
        chatUserRoom?.time = DateTime.now();
        chatUserRoom?.newMsgCount = 0;
      },
      onError: (error) {
        Loggers.warning('send failed: $error');
      },
    );

    messageTextController.text = "";
  }

  /// 拉取最新一页消息（desc：最新在前）。
  void fetchMessages() {
    if (chatUserRoom?.conversationId == null) return;
    ChatService.shared.fetchMessages(
      conversationId: chatUserRoom!.conversationId!,
      completion: (list, more) {
        messages = list;
        hasMore = more;
        update();
      },
      onError: (error) {
        Loggers.warning('fetch messages failed: $error');
      },
    );
  }

  /// 上滑加载更早的消息。
  void loadOldData() {
    if (!hasMore || isLoadingOld || messages.isEmpty) {
      return;
    }
    isLoadingOld = true;
    ChatService.shared.fetchMessages(
      conversationId: chatUserRoom!.conversationId!,
      beforeId: messages.last.id,
      completion: (list, more) {
        isLoadingOld = false;
        hasMore = more;
        messages.addAll(list); // 更早的追加到尾部（reverse 列表顶部）
        update();
      },
      onError: (error) {
        isLoadingOld = false;
      },
    );
  }

  void removeStoryFromMessage({required ChatMessage message}) {
    message.thumbnail = '';
    update();
  }

  void markAsRead() {
    var conversationId = chatUserRoom?.conversationId;
    if (conversationId != null && conversationId.isNotEmpty) {
      // 先本地清除列表红点与底部 Tab 红点（立即生效，不等网络返回），
      // 再同步服务端 unread_count = 0（覆盖退出页面时才调用的旧逻辑残留）
      chatUserRoom?.newMsgCount = 0;
      if (Get.isRegistered<ChatsScreensController>()) {
        Get.find<ChatsScreensController>().clearUnreadBadge(conversationId);
      }
      ChatService.shared.markAsRead(conversationId: conversationId);
    }
  }

  void rejectMessageRequest() {
    var conversationId = chatUserRoom?.conversationId;
    if (conversationId == null) return;
    showColibriBottomSheet(ConfirmationSheet(
      desc: LKeys.rejectChatRequest,
      buttonTitle: LKeys.reject,
      onTap: () {
        ChatService.shared
            .rejectRequest(conversationId: conversationId, completion: () {});
        Get.back();
      },
    ));
  }

  void acceptMessageRequest() {
    var conversationId = chatUserRoom?.conversationId;
    if (conversationId == null) return;
    ChatService.shared
        .acceptRequest(conversationId: conversationId, completion: () {});
    chatUserRoom?.type = 1;
    update();
  }

  void leaveRoom() {
    startLoading();
    RoomService.shared.leaveThisRoom(room?.id ?? 0, () {
      stopLoading();
      room?.userRoomStatus = GroupUserAccessType.none.value;
      room?.totalMember = (room?.totalMember ?? 0) - 1;
      Get.back(result: room);
      update();
    });
  }

  List<Invitation> joinRequests = [];

  void fetchRequests() {
    startLoading();
    RoomService.shared.fetchRoomRequestList(room?.id ?? 0, (invitations) {
      stopLoading();
      joinRequests = invitations;
      update();
    });
  }

  void acceptRequest(Invitation invitation) {
    startLoading();
    RoomService.shared
        .acceptRoomRequest(invitation.userId ?? 0, invitation.roomId ?? 0, () {
      stopLoading();
      room?.totalMember = (room?.totalMember ?? 0) + 1;
      joinRequests.removeWhere((element) => element.id == invitation.id);
      update();
    });
  }

  void rejectRequest(Invitation invitation) {
    RoomService.shared
        .rejectRoomRequest(invitation.userId ?? 0, invitation.roomId ?? 0, () {
      stopLoading();
      joinRequests.removeWhere((element) => element.id == invitation.id);
      update();
    });
  }

  /// 房间通知静默开关：服务器按 room_users.is_mute 过滤推送，
  /// 客户端不再需要订阅/退订 FCM topic。
  void muteUnMuteNotification() {
    var type = (room?.isMute ?? 0) == 0 ? 1 : 0;
    RoomService.shared.muteUnmuteNotification(type, room?.id ?? 0, () {
      room?.isMute = type;
      update();
    });
  }

  void deleteRoom() async {
    startLoading();
    RoomService.shared.deleteRoom(room?.id ?? 0, () {
      stopLoading();
      Get.back();
    });
  }

  void deleteRoomByModerator() {
    showColibriBottomSheet(
      ConfirmationSheet(
        desc: LKeys.deleteRoomByModeratorDesc,
        buttonTitle: LKeys.deleteThisRoom,
        onTap: () {
          startLoading();
          ModeratorService.shared.deleteRoom(
              roomId: room?.id?.toInt() ?? 0,
              completion: () {
                stopLoading();
                Get.back();
              });
        },
      ),
    );
  }

  void stopNotification() {
    SessionManager.shared
        .setStoredConversation(chatUserRoom?.conversationId ?? '');
  }

  void startNotification() {
    SessionManager.shared.setStoredConversation('');
  }

  @override
  void onClose() {
    startNotification();
    WsManager.shared.removeListener('message.new', _onWsMessage);
    if (chatUserRoom?.conversationKey != null &&
        chatUserRoom?.conversationId != null) {
      WsManager.shared.unsubscribeConversation(
          chatUserRoom!.conversationId!, chatUserRoom!.conversationKey!);
    }
    markAsRead();
    super.onClose();
    startNotification();
  }
}

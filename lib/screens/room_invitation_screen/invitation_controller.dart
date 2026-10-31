import 'package:flutter/material.dart';
import 'package:untitled/common/api_service/room_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/models/invitations_model.dart';

/// 房间邀请控制器。
///
/// 本地化聊天后，接受邀请加入房间的会话由服务端自动同步
/// （/api/chat/fetchConversations 每次都会同步 room_users），
/// 不再需要客户端往 Firestore 写入 chats 数据。
class InvitationController extends BaseController {
  List<Invitation> invitations = [];
  ScrollController scrollController = ScrollController();

  @override
  void onReady() {
    getInvitations();
    scrollController.addListener(
      () {
        if (scrollController.offset ==
            scrollController.position.maxScrollExtent) {
          if (!isLoading.value) {
            getInvitations();
          }
        }
      },
    );
    super.onReady();
  }

  void getInvitations() {
    if (invitations.isEmpty) {
      startLoading();
    }
    isLoading.value = true;
    RoomService.shared.getInvitationList(
      invitations.length,
      (invitations) {
        if (this.invitations.isEmpty) {
          stopLoading();
        }
        isLoading.value = false;
        this.invitations.addAll(invitations);
        update();
      },
    );
  }

  void acceptInvitation(Invitation invitation) {
    startLoading();
    RoomService.shared.acceptInvitation(invitation.roomId ?? 0, () {
      stopLoading();
      removeFromList(invitation);
    });
  }

  void rejectInvitation(Invitation invitation) {
    startLoading();
    RoomService.shared.rejectInvitation(invitation.roomId ?? 0, () {
      stopLoading();
      removeFromList(invitation);
    });
  }

  void removeFromList(Invitation invitation) {
    invitations.removeWhere((element) => element.id == invitation.id);
    update();
  }
}

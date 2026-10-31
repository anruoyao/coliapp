import 'package:get/get.dart';
import 'package:untitled/common/api_service/room_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/models/room_model.dart';
import 'package:untitled/screens/chats_screen/chatting_screen/chatting_view.dart';

/// 房间操作控制器。
///
/// 本地化聊天后，成员加入房间时会话由服务端自动同步
/// （/api/chat/fetchConversations 每次都会同步 room_users），
/// 客户端不再需要往 Firestore chats 集合写数据。
class RoomController extends BaseController {
  Room room;

  RoomController(this.room);

  void joinOrRequestOrAccept() {
    if (room.getUserAccessType() == GroupUserAccessType.invited) {
      startLoading();
      RoomService.shared.acceptInvitation(room.id ?? 0, () {
        stopLoading();
        Get.back();
        room.userRoomStatus = GroupUserAccessType.member.value;
        room.totalMember = (room.totalMember ?? 0) + 1;
        update();
        Get.to(() => ChattingView(room: room), opaque: false)?.then(onBack);
      });
      return;
    }
    if (room.getUserAccessType() != GroupUserAccessType.none) {
      return;
    }
    startLoading();
    RoomService.shared.joinRoomRequest(room.id ?? 0, (member) {
      stopLoading();
      Get.back();
      if (member != null) {
        room.userRoomStatus = member.type;
        if (room.getUserAccessType() == GroupUserAccessType.member) {
          room.totalMember = (room.totalMember ?? 0) + 1;
          Get.to(() => ChattingView(room: room), opaque: false)?.then(onBack);
        }
        update();
      }
    });
  }

  void onBack(dynamic value) {
    if (value is Room?) {
      if (value != null) {
        room.totalMember = value.totalMember;
        room.userRoomStatus = value.userRoomStatus;
        update();
      }
    }
  }
}

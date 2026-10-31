import 'package:untitled/common/api_service/room_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/models/room_model.dart';

class RoomsByInterestController extends BaseController {
  List<Room> rooms = [];
  int? interestId;

  RoomsByInterestController({this.interestId});

  @override
  void onReady() {
    if (interestId != null) {
      fetchRooms((interestId ?? 0).toInt());
    } else {
      fetchRandomRooms();
    }
    super.onReady();
  }

  Future<void> fetchRandomRooms() async {
    isLoading.value = true;
    await RoomService.shared.fetchRooms((rooms) {
      isLoading.value = false;
      this.rooms = rooms;
      update();
    });
  }

  Future<void> fetchRooms(int interestId) async {
    if (rooms.isEmpty) {
      startLoading();
    }

    await RoomService.shared.fetchRoomByInterest(interestId, rooms.length,
        (rooms) {
      stopLoading();
      this.rooms.addAll(rooms);
      update();
    });
  }
}

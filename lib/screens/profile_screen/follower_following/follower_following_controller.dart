import 'package:untitled/common/api_service/user_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/models/registration.dart';

class FollowerFollowingController extends BaseController {
  final bool isForFollowing;
  final num userId;
  List<User> users = [];

  FollowerFollowingController(this.isForFollowing, this.userId);

  @override
  void onReady() {
    fetchUsers();
    super.onReady();
  }

  Future<void> fetchUsers() async {
    if (users.isEmpty) {
      startLoading();
    }
    if (isForFollowing) {
      await UserService.shared.fetchFollowingList(userId, users.length,
          (users) {
        stopLoading();
        this.users.addAll(users);
        update();
      });
    } else {
      await UserService.shared.fetchFollowerList(userId, users.length, (users) {
        stopLoading();
        this.users.addAll(users);
        update();
      });
    }
  }
}

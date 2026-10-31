import 'package:get/get.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/logger.dart';
import 'package:untitled/models/registration.dart';

import '../../common/api_service/user_service.dart';

class FollowController extends BaseController {
  Rx<User> user;

  FollowController(this.user);

  Future<User?> followUnFollowUser() async {
    num userId = user.value.id ?? -1;
    if (userId == -1) {
      Loggers.error('Invalid User id :$userId');
      return null; // Return early to prevent further execution if the user ID is invalid
    }

    bool isFollowing = user.value.followStatus == FollowStatus.iFollowHim;

    user.update((val) {
      if (val != null)
        val.followingStatus =
            (isFollowing ? FollowStatus.noFollowNo : FollowStatus.iFollowHim)
                .value;
      if (val != null)
        val.followers = (isFollowing
            ? (user.value.followers ?? 0) - 1
            : (user.value.followers ?? 0) + 1);
    });

    if (isFollowing) {
      await UserService.shared.unfollowUser(user.value.id ?? 0, () {});
    } else {
      await UserService.shared.followUser(user.value.id ?? 0, () {});
    }

    return user.value;
  }

  static User? unfollow(User? userData) {
    num userId = userData?.id ?? -1;

    if (userId == -1) {
      Loggers.error('Invalid User id :$userId');
      return null; // Return early to prevent further execution if the user ID is invalid
    }

    FollowController followController;
    if (Get.isRegistered<FollowController>(tag: userId.toString())) {
      followController = Get.find<FollowController>(tag: userId.toString());
    } else {
      followController = Get.put(FollowController((userData ?? User()).obs),
          tag: userId.toString());
    }

    followController.user.update((val) {
      if (val != null) val.followingStatus = (FollowStatus.noFollowNo).value;
      if (val != null)
        val.followers = (followController.user.value.followers ?? 0) - 1;
    });

    return followController.user.value;
  }
}

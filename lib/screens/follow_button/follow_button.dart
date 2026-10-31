import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/screens/follow_button/follow_controller.dart';

import '../../models/registration.dart';

class FollowButton extends StatelessWidget {
  final User? user;
  final Widget Function(bool isFollowing) child;
  final Function(User?)? onChange;

  const FollowButton(
      {super.key, required this.user, this.onChange, required this.child});

  @override
  Widget build(BuildContext context) {
    if (user?.id == SessionManager.shared.getUserID()) return Container();
    FollowController controller = Get.put(
        FollowController((user ?? User()).obs),
        tag: user?.id.toString());
    return Obx(
      () {
        bool isFollow =
            controller.user.value.followStatus == FollowStatus.iFollowHim ||
                controller.user.value.followStatus ==
                    FollowStatus.weFollowEachOther;
        return InkWell(
          onTap: () {
            controller.followUnFollowUser();
            onChange?.call(controller.user.value);
          },
          child: child(isFollow),
        );
      },
    );
  }
}

import 'dart:async';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/reel_service.dart';
import 'package:untitled/common/api_service/user_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/haptic_manager.dart';
import 'package:untitled/common/managers/logger.dart';
import 'package:untitled/common/managers/my_debouncer.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/managers/share_manager.dart';
import 'package:untitled/models/reel_model.dart';
import 'package:untitled/models/reel_model_extension.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/screens/profile_screen/profile_screen.dart';
import 'package:untitled/screens/reels_screen/comments/reel_comment_screen.dart';
import 'package:untitled/screens/reels_screen/music/music_reels_screen.dart';
import 'package:untitled/screens/report_screen/report_sheet.dart';
import 'package:untitled/utilities/const.dart';

class ReelController extends BaseController {
  Rx<Reel?> reel = Rx<Reel?>(null);

  int get reelId => reel.value?.id?.toInt() ?? -1;

  bool get isPreviewReel => reelId == -1;

  bool get isMyReel =>
      reel.value?.user?.id == SessionManager.shared.getUserID();

  ReelController(this.reel);

  init({Reel? post}) {
    reel.update((val) {
      val = post;
    });
  }

  void onProfileTap() {
    FocusManager.instance.primaryFocus?.unfocus();
    Get.to(() => ProfileScreen(userId: reel.value?.userId ?? 0), opaque: false);
  }

  void onLikeTap() {
    FocusManager.instance.primaryFocus?.unfocus();

    HapticManager.shared.light();
    reel.update((val) {
      val?.isLike = reel.value?.isLike == 1 ? 0 : 1;
      val?.likesCount = reel.value?.isLike == 1
          ? (reel.value?.likesCount ?? 0) + 1
          : (reel.value?.likesCount ?? 0) - 1;
    });

    MyDebouncer.shared.run(() async {
      if (reel.value == null) return Loggers.error('Reel value not found');
      if (reelId != -1) {
        await ReelService.shared.likeDislikeReel(reelId: reelId);
      }
    });
  }

  void likeWithDoubleTap() {
    FocusManager.instance.primaryFocus?.unfocus();
    HapticManager.shared.light();
    if (reel.value?.isLike == 1) return;
    reel.update((val) {
      val?.isLike = 1;
      val?.likesCount = (reel.value?.likesCount ?? 0) + 1;
    });

    MyDebouncer.shared.run(() async {
      if (reel.value == null) return Loggers.error('Reel value not found');
      if (reelId != -1) {
        await ReelService.shared.likeDislikeReel(reelId: reelId);
      }
    });
  }

  Future<void> onCommentTap() async {
    FocusManager.instance.primaryFocus?.unfocus();

    showColibriBottomSheet(
      ReelCommentScreen(reelController: this),
      isScrollControlled: true,
      ignoreSafeArea: false,
    ).then((value) {});
  }

  void onSaved() {
    FocusManager.instance.primaryFocus?.unfocus();

    HapticManager.shared.light();

    reel.update((val) {
      val?.saveToggle();
    });
    reel.refresh();

    if (isPreviewReel) return;
    MyDebouncer.shared.run(() async {
      UserService.shared.editProfile(
          savedReelsIds: SessionManager.shared.getUser()?.getSavedReelIdsList(),
          completion: (p0) {});
    });
  }

  void onShareTap() {
    FocusManager.instance.primaryFocus?.unfocus();
    String title =
        '${reel.value?.user?.fullName ?? ''} on ${appName} : ${reel.value?.description ?? ''}';
    ShareManager.shared
        .shareTheContent(key: ShareKeys.reel, value: reel.value?.id ?? 0);
  }

  void reportReel() {
    showColibriBottomSheet(ReportSheet(reel: reel.value),
        isScrollControlled: true);
  }

  void onAudioTap() async {
    FocusManager.instance.primaryFocus?.unfocus();
    Get.to(() => MusicReelsScreen(music: reel.value?.music), opaque: false);
  }

// Future<void> followUnFollowUser(Reel? value) async {
//   bool isFollowing = value?.user?.followStatus == FollowStatus.iFollowHim;
//   reel.update((val) {
//     val?.user?.followingStatus = (isFollowing ? FollowStatus.noFollowNo : FollowStatus.iFollowHim).value;
//   });
//   reel.refresh();
//   MyDebouncer.shared.run(() {
//     if (isFollowing) {
//       UserService.shared.unfollowUser(value?.userId ?? 0, () {});
//     } else {
//       UserService.shared.followUser(value?.userId ?? 0, () {});
//     }
//   });
// }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_timeline_service.dart';
import 'package:untitled/common/api_service/moderator_service.dart';
import 'package:untitled/common/api_service/reel_service.dart';
import 'package:untitled/common/api_service/user_service.dart';
import 'package:untitled/common/managers/guest_session.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/managers/share_manager.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
import 'package:untitled/common/widgets/functions.dart';
import 'package:untitled/common/widgets/guest_auth_sheet.dart';
import 'package:untitled/common/widgets/colibri_ui.dart';
import 'package:untitled/localization/allLanguages.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/reel_model.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/screens/feed_screen/feed_screen_controller.dart';
import 'package:untitled/screens/follow_button/follow_controller.dart';
import 'package:untitled/utilities/const.dart';

class ProfileController extends FeedScreenController {
  User? user;
  final int userID;
  String followBtnID = "follow_btn";

  double maxExtent = 250.0;
  double currentExtent = 250.0;
  final bool isFromTabBar;
  final idForImage = '${DateTime.now().microsecondsSinceEpoch}';

  RxInt selectedPage = 0.obs;
  RxList<Reel> reels = RxList();
  bool isTranslatingBio = false;
  bool isBioTranslated = false;
  String? translatedBio;
  String? bioSourceLanguage;
  String? _bioTranslationTarget;
  int _bioTranslationRequest = 0;

  String get _currentTranslationTarget =>
      ColibriTimelineService.translationTarget(
        Get.locale?.languageCode ??
            SessionManager.shared.getLang().language.languageCode,
      );

  void resetBioTranslation() {
    _bioTranslationRequest++;
    isTranslatingBio = false;
    isBioTranslated = false;
    translatedBio = null;
    bioSourceLanguage = null;
    _bioTranslationTarget = _currentTranslationTarget;
  }

  void replaceProfile(User profile) {
    if (user?.id != profile.id || user?.bio != profile.bio) {
      resetBioTranslation();
    }
    user = profile;
  }

  Future<void> toggleBioTranslation() async {
    final profile = user;
    final bio = profile?.bio ?? '';
    final profileId = profile?.id?.toInt();
    if (profile == null || bio.trim().isEmpty || profileId == null) return;

    final target = _currentTranslationTarget;
    if (_bioTranslationTarget != target) resetBioTranslation();
    if (isTranslatingBio) return;

    if (GuestSession.i.isGuest) {
      AuthGate.requireLogin(() {}, feature: LKeys.translate.tr);
      return;
    }

    if (translatedBio != null) {
      isBioTranslated = !isBioTranslated;
      update();
      return;
    }

    final request = ++_bioTranslationRequest;
    isTranslatingBio = true;
    update();
    bool isCurrent() =>
        request == _bioTranslationRequest &&
        user?.id == profile.id &&
        user?.bio == profile.bio &&
        target == _currentTranslationTarget;

    try {
      final result = await ColibriTimelineService.shared.translateBio(
        profileId: profileId,
        text: bio,
        target: target,
      );
      if (isCurrent()) {
        translatedBio = result.translatedText;
        bioSourceLanguage = result.sourceLanguage;
        isBioTranslated = true;
      }
    } catch (error) {
      if (isCurrent()) {
        showColibriToast(LKeys.translationFailed.tr,
            message: error.toString(),
            backgroundColor: cRed,
            colorText: Colors.white);
      }
    } finally {
      if (isCurrent()) {
        isTranslatingBio = false;
        update();
      }
    }
  }

  PageController pageController = PageController(initialPage: 0);

  // ScrollController newScrollController = ScrollController();

  ProfileController(this.userID, this.isFromTabBar);

  void updateEverything() {
    update([scrollID]);
    update();
  }

  void updateMyProfile() {
    if (user?.id == SessionManager.shared.getUserID()) {
      user = SessionManager.shared.getUser();
      update();
      update([scrollID]);
    }
  }

  void getStories() {
    UserService.shared.fetchProfile(userID, (user) {
      replaceProfile(user);

      if (user.id == SessionManager.shared.getUserID()) {
        SessionManager.shared.setUser(user);
      }
      update();
      update([scrollID]);
    });
  }

  Future<void> getProfile({bool isForRefresh = false}) async {
    if (!isForRefresh && !isFromTabBar) {
      startLoading();
    }
    await UserService.shared.fetchProfile(userID, (user) {
      replaceProfile(user);

      if (Get.isRegistered<FollowController>(tag: '${user.id}')) {
        var controller = Get.find<FollowController>(tag: '${user.id}');
        controller.user.value = user;
      }

      if (user.id == SessionManager.shared.getUserID()) {
        SessionManager.shared.setUser(user);
      }
      update();
      update([scrollID]);
      stopLoading();
    });
  }

  @override
  void onReady() {
    super.onReady();
    user = User(id: userID);
    getProfile();
    if (!(user?.isBlockedByMe() ?? false)) {
      fetchUserPosts(userID: userID);
      fetchReels();
    }
    scrollController?.addListener(() {
      currentExtent = maxExtent - scrollController!.offset;
      if (currentExtent < 0) currentExtent = 0.0;
      if (currentExtent > maxExtent) currentExtent = maxExtent;
      update([scrollID]);
    });
  }

  bool isAllReelsFetched = false;

  Future<void> fetchReels({bool shouldRefresh = false}) async {
    if (shouldRefresh) {
      isAllReelsFetched = false;
      reels.clear();
    }
    if (isAllReelsFetched) return;
    var newReels = await ReelService.shared
        .fetchReelsByUser(userId: userId, start: reels.length);
    reels.addAll(newReels);
    if (newReels.length < Limits.pagination) {
      isAllReelsFetched = true;
    }
  }

  void blockByModerator() {
    showColibriConfirmDialog(
      Get.context!,
      icon: Icons.block_rounded,
      title: LKeys.block.tr,
      message: LKeys.blockUserGloballyByModeratorDesc.tr,
      confirmText: LKeys.block.tr,
      onConfirm: () async {
        ModeratorService.shared.blockUser(
            userId: userId,
            completion: () async {
              user?.followingStatus =
                  await FollowController.unfollow(user)?.followingStatus;
              posts.clear();
              updateEverything();
            });
        return true;
      },
    );
  }

  void blockUnblock() {
    if (user?.isBlockedByMe() ?? false) {
      unblockUser(user, () {
        fetchUserPosts(userID: (user?.id ?? 0).toInt());
        updateEverything();
      });
    } else {
      blockUser(user, () async {
        user = await FollowController.unfollow(user);
        posts.clear();
        updateEverything();
      });
    }
  }

  @override
  void onClose() {
    Functions.changStatusBar(StatusBarStyle.white);
  }

  void shareProfile() {
    ShareManager.shared
        .shareTheContent(key: ShareKeys.user, value: user?.id?.toInt() ?? 0);
  }

  void onChangeSegment(int value) {
    selectedPage.value = value;
    // controller.jumpToPage(value);
  }

  void deleteReel(Reel reel) {
    showColibriConfirmDialog(
      Get.context!,
      icon: Icons.delete_outline_rounded,
      title: LKeys.delete.tr,
      message: LKeys.deleteReelDesc.tr,
      confirmText: LKeys.delete.tr,
      onConfirm: () async {
        reels.removeWhere((element) => element.id == reel.id);
        await ReelService.shared.deleteReel(reelId: reel.id ?? 0);
        return true;
      },
    );
  }

  void deleteReelByModerator(Reel reel) {
    showColibriConfirmDialog(
      Get.context!,
      icon: Icons.delete_outline_rounded,
      title: LKeys.delete.tr,
      message: LKeys.deleteReelDesc.tr,
      confirmText: LKeys.delete.tr,
      onConfirm: () async {
        reels.removeWhere((element) => element.id == reel.id);
        await ModeratorService.shared.deleteReel(reelId: reel.id ?? 0);
        return true;
      },
    );
  }
}

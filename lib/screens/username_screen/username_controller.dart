import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/user_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/interests_screen/interests_controller.dart';
import 'package:untitled/screens/profile_picture_screen/profile_picture_screen.dart';

class UsernameController extends InterestsController {
  TextEditingController textController = TextEditingController();

  void checkForUsername({Function(bool)? completion}) {
    String username = textController.text;

    if (username.contains(' ')) {
      completion?.call(false);
      return;
    }

    // Check if username is current user's username
    if (username.isNotEmpty &&
        SessionManager.shared.getUser()?.username == username) {
      completion?.call(true);
      return;
    }

    if (!GetUtils.isUsername(username)) {
      completion?.call(false);
    }

    // Check if username is in restricted list
    if (SessionManager.shared
            .getSettings()
            ?.restrictedUsernames
            ?.firstWhereOrNull((element) =>
                element.title?.toLowerCase() == username.toLowerCase()) !=
        null) {
      completion?.call(false);
      return;
    }

    // API call to check username availability
    UserService.shared.checkForUsername(username, (isAvailable) {
      stopLoading();
      completion?.call(isAvailable);
    });
  }

  void updateUsername() {
    FocusManager.instance.primaryFocus?.unfocus();
    startLoading();
    checkForUsername(
      completion: (isAvailable) {
        if (!isAvailable) {
          showSnackBar(LKeys.thisUsernameIsNotAvailable.tr,
              type: SnackBarType.error);
        } else {
          UserService.shared.editProfile(
            username: textController.text,
            completion: (success) {
              stopLoading();
              Get.offAll(() => const ProfilePictureScreen());
            },
          );
        }
      },
    );
  }
}

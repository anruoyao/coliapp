import 'package:get/get.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:untitled/common/api_service/notification_service.dart';
import 'package:untitled/common/api_service/user_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/firebase_notification_manager.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/login_screen/login_screen.dart';
import 'package:untitled/screens/room_invitation_screen/room_invitation_screen.dart';
import 'package:untitled/screens/rooms_you_own/rooms_you_own_screen.dart';
import 'package:untitled/screens/sheets/confirmation_sheet.dart';
import 'package:untitled/utilities/const.dart';

class SettingController extends BaseController {
  bool isNotification =
      SessionManager.shared.getUser()?.isPushNotifications == 1 ? true : false;
  bool isGetInvited =
      SessionManager.shared.getUser()?.isInvitedToRoom == 1 ? true : false;
  String notificationID = "notificationID";
  String getInvitedID = "getInvitedID";
  String version = "";

  @override
  void onReady() {
    PackageInfo.fromPlatform().then((packageInfo) {
      String version = packageInfo.version;
      String buildNumber = packageInfo.buildNumber;
      print("$version $buildNumber");
      this.version = "$version ($buildNumber)";
      update(['version']);
    });
    super.onReady();
  }

  void changeOfNotification(bool value) {
    isNotification = value;
    update([notificationID]);
    UserService.shared.editProfile(
      isPushNotifications: isNotification,
      completion: (p0) {},
    );
    if (value) {
      NotificationService.shared.subscribeToAllMyRoom();
      FirebaseNotificationManager.shared.subscribeToTopic(notificationTopic);
    } else {
      NotificationService.shared.unsubscribeToAllMyRoom();
      FirebaseNotificationManager.shared.unsubscribeToTopic(notificationTopic);
    }
  }

  void changeOfGetInvited(bool value) {
    isGetInvited = value;
    update([getInvitedID]);
    UserService.shared.editProfile(
      isInvitedToRoom: isGetInvited,
      completion: (p0) {},
    );
  }

  void tapRoomsYouOwn() {
    Get.to(() => const RoomsYouOwnScreen(), opaque: false);
  }

  void tapRoomInvitation() {
    Get.to(() => const RoomInvitationScreen(), opaque: false);
  }

  void deleteAccount() {
    showColibriBottomSheet(ConfirmationSheet(
        desc: LKeys.deleteAccDesc,
        buttonTitle: LKeys.delete,
        onTap: () {
          startLoading();
          UserService.shared.deleteUser(() {
            cleanAllSession();
            Get.offAll(() => const LoginScreen());
          });
        }));
  }

  void logout() {
    showColibriBottomSheet(ConfirmationSheet(
        desc: LKeys.logoutDesc,
        buttonTitle: LKeys.logOut,
        onTap: () {
          startLoading();
          UserService.shared.logOut(() {
            cleanAllSession();
            Get.offAll(() => const LoginScreen());
          });
        }));
  }

  void cleanAllSession() {
    SessionManager.shared.setLogin(false);

    FirebaseNotificationManager.shared.subscribeToTopic(notificationTopic);
    NotificationService.shared.unsubscribeToAllMyRoom();
    SessionManager.shared.setUser(null);
    stopLoading();
  }
}

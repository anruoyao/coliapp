import 'package:flutter/material.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/notification_service.dart';
import 'package:untitled/common/api_service/user_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/firebase_notification_manager.dart';
import 'package:untitled/common/managers/logger.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/managers/ws_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/block_by_admin_screen/block_by_admin_screen.dart';
import 'package:untitled/screens/interests_screen/interests_screen.dart';
import 'package:untitled/screens/login_screen/sign_in_with_email_screen.dart';
import 'package:untitled/screens/profile_picture_screen/profile_picture_screen.dart';
import 'package:untitled/screens/tabbar/tabbar_screen.dart';
import 'package:untitled/screens/username_screen/username_screen.dart';
import 'package:untitled/utilities/const.dart';

class LoginController extends BaseController {
  @override
  void onReady() {
    Loggers.info("TRYING NOTIFICATION");
    FirebaseNotificationManager.shared.init();

    super.onReady();
  }

  void emailLogin() {
    showColibriBottomSheet(const SignInWithEmailScreen(),
        isScrollControlled: true, ignoreSafeArea: false);
  }

  void registerUser(
      {String? fullName,
      required String identity,
      required LoginType loginType}) {
    startLoading();

    // 不等待 FCM token（无 Google 服务的设备上 getToken 会一直挂起）：
    // 优先用启动时已缓存的 token，没有就用占位符立即登录，登录后再异步补传。
    final cachedToken = FirebaseNotificationManager.shared.cachedFcmToken;
    final deviceToken = cachedToken ?? 'No Token';

    UserService.shared.registration(
        name: fullName,
        identity: identity,
        deviceToken: deviceToken,
        loginType: loginType,
        completion: (p0) {
          var user = p0.data;
          if (user == null) {
            // addUser 失败（网络异常 / 响应缺 data）：停止转圈并提示，不进入主界面
            stopLoading();
            showSnackBar(p0.message ?? LKeys.someThingWentWrong.tr,
                type: SnackBarType.error);
            return;
          }

          SessionManager.shared.setLogin(true);

          Widget w = InterestScreen();
          // 连接自建 WebSocket（实时消息 + 在线推送，不依赖 Google 服务）
          WsManager.shared.connect();
          if (user.isPushNotifications == 1) {
            FirebaseNotificationManager.shared
                .subscribeToTopic(notificationTopic);
          }
          if (user.isBlock == 1) {
            w = const BlockedByAdminScreen();
          } else if (user.interestIds == null) {
            w = InterestScreen();
          } else if (user.username == null) {
            w = const UserNameScreen();
          } else if (user.profile == null) {
            w = const ProfilePictureScreen();
          } else {
            w = TabBarScreen();
          }
          Get.offAll(() => w);
          stopLoading();

          // 登录时未带上真实推送 token：后台异步获取并补传，不阻塞界面
          if (cachedToken == null) {
            FirebaseNotificationManager.shared.getNotificationToken((token) {
              if (token != 'No Token') {
                UserService.shared
                    .editProfile(deviceToken: token, completion: (_) {});
              }
            });
          }
        });
  }
}

enum LoginType {
  google(0),
  apple(1),
  email(2);

  const LoginType(this.value);

  final int value;
}

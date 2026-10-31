import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/logger.dart';
import 'package:untitled/common/managers/guest_session.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/managers/version_check_manager.dart';
import 'package:untitled/screens/colibri_home/colibri_home_screen.dart';
import 'package:untitled/screens/login_screen/login_screen.dart';

class SplashController extends BaseController {
  @override
  void onInit() {
    Loggers.info('startup.splash.controller.init');
    fetchSettings();
    // 启动后异步检测 App 更新（不阻塞导航；检测失败静默）
    Future.delayed(const Duration(milliseconds: 800), () {
      VersionCheckManager.shared.checkAndShow();
    });
    super.onInit();
  }

  Future<void> fetchSettings() async {
    Loggers.info('startup.splash.route.start');
    try {
      final view = await gotoView();
      Loggers.info('startup.splash.route.target ${view.runtimeType}');
      Get.offAll(() => view);
      Loggers.info('startup.splash.route.offAll.done');
    } catch (error, stackTrace) {
      Loggers.error('startup.splash.route.error $error\\n$stackTrace');
      Get.offAll(() => const LoginScreen());
    }
  }

  Future<Widget> gotoView() async {
    // ColibriPlus：有 token 即已登录，进入主界面；
    // 未登录时检测后台访客总开关：开启 → 以访客身份进入主界面浏览；
    // 关闭/网络异常 → 登录页（保守策略，维持旧行为）。
    final logged = SessionManager.shared.isLogin() &&
        (SessionManager.shared.getToken()?.isNotEmpty ?? false);
    Loggers.info('startup.splash.session logged=$logged');
    if (logged) {
      return const ColibriHomeScreen();
    }
    Loggers.info('startup.splash.guest.start');
    final guestAllowed = await GuestSession.i.detectForUnauthenticated();
    Loggers.info('startup.splash.guest.done allowed=$guestAllowed');
    if (guestAllowed) {
      return const ColibriHomeScreen();
    }
    return const LoginScreen();
  }
}

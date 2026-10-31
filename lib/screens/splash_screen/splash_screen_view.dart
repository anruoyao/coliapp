import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/managers/logger.dart';
import 'package:untitled/screens/splash_screen/splash_controller.dart';
import 'package:untitled/utilities/const.dart';

import '../extra_views/logo_tag.dart';

class SplashScreenView extends StatelessWidget {
  const SplashScreenView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Loggers.info('startup.splash.build');
    final _ = Get.put(SplashController());
    return Scaffold(
      body: Container(
        color: cBlack,
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        child: LogoTag(
          isWhite: true,
          width: Get.width / 2,
        ),
      ),
    );
  }
}

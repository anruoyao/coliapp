import 'dart:io';

import 'package:flutter/material.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/extra_views/buttons.dart';
import 'package:untitled/utilities/const.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateAppScreen extends StatelessWidget {
  const UpdateAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Spacer(),
          Padding(
            padding: EdgeInsetsGeometry.all(40),
            child: Image.asset(
              MyImages.update,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  'Update the App',
                  style: MyTextStyle.gilroyBold(size: 24),
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  'This update is required to continue using the app. Please update now for security, stability, and performance improvements.',
                  textAlign: TextAlign.center,
                  style: MyTextStyle.gilroyRegular(size: 16, color: cLightText),
                ),
              ],
            ),
          ),
          Spacer(),
          CommonButton(
              text: LKeys.update,
              onTap: () {
                if (Platform.isAndroid) {
                  launchUrl(
                      Uri.parse(SessionManager.shared
                              .getSettings()
                              ?.playStoreDownloadLink ??
                          ''),
                      mode: LaunchMode.externalApplication);
                } else {
                  launchUrl(
                      Uri.parse(SessionManager.shared
                              .getSettings()
                              ?.appStoreDownloadLink ??
                          ''),
                      mode: LaunchMode.externalApplication);
                }
              })
        ],
      ),
    );
  }
}

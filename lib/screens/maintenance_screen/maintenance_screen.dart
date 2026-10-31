import 'package:flutter/material.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/utilities/const.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsetsGeometry.all(40),
            child: Image.asset(
              MyImages.maintenance,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  'Under Maintenance',
                  style: MyTextStyle.gilroyBold(size: 24),
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  SessionManager.shared.getSettings()?.maintenanceMessage ?? '',
                  textAlign: TextAlign.center,
                  style: MyTextStyle.gilroyRegular(size: 16, color: cLightText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

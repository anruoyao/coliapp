import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/utilities/const.dart';

/// 账号认证：展示当前认证状态。申请/认证由外部权威服务完成（服务未配置时为占位）。
class ColibriVerificationScreen extends StatelessWidget {
  const ColibriVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SessionManager.shared.getColibriUser();
    final verified = user?['verified'] == true;
    return Scaffold(
      backgroundColor: cWhite,
      appBar: AppBar(
        backgroundColor: cWhite,
        elevation: 0,
        title: Text(LKeys.settingsVerification.tr,
            style:
                const TextStyle(fontWeight: FontWeight.bold, color: cMainText)),
        leading: BackButton(color: cBlack, onPressed: () => Get.back()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Icon(
                verified
                    ? Icons.verified_rounded
                    : Icons.check_circle_outline_rounded,
                size: 64,
                color: verified ? cBlueTick : cLightIcon),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
                verified
                    ? LKeys.settingsVerifiedAccount.tr
                    : LKeys.settingsNotVerified.tr,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cMainText)),
          ),
          const SizedBox(height: 8),
          Text(
            verified
                ? LKeys.settingsVerificationApprovedDescription.tr
                : LKeys.settingsVerificationDescription.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: cLightText),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: cLightBg, borderRadius: BorderRadius.circular(12)),
            child: Text(
              LKeys.settingsVerificationUnavailable.tr,
              style: const TextStyle(fontSize: 12, color: cLightText),
            ),
          ),
        ],
      ),
    );
  }
}

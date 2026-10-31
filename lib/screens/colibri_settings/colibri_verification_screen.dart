import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/managers/session_manager.dart';
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
        title: const Text('账号认证',
            style: TextStyle(fontWeight: FontWeight.bold, color: cMainText)),
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
            child: Text(verified ? '已认证账号' : '尚未认证',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cMainText)),
          ),
          const SizedBox(height: 8),
          Text(
            verified
                ? '你的账号已通过身份认证，名字旁会显示蓝色认证标识。'
                : '认证账号会获得名字旁的蓝色认证标识，用于证明你的身份。认证由第三方权威身份服务完成。',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: cLightText),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: cLightBg, borderRadius: BorderRadius.circular(12)),
            child: const Text(
              '当前服务器尚未接入认证服务（VERIFICATION_SERVICE_URL 未配置），暂无法在线申请。可稍后在网页端查看认证入口。',
              style: TextStyle(fontSize: 12, color: cLightText),
            ),
          ),
        ],
      ),
    );
  }
}

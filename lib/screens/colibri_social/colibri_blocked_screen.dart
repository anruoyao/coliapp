import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/managers/app_command_handler.dart';
import 'package:untitled/common/managers/bookmark_store.dart';
import 'package:untitled/common/managers/chat_unread_store.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/screens/login_screen/login_screen.dart';
import 'package:untitled/utilities/const.dart';
import 'package:url_launcher/url_launcher.dart';

/// 账号封禁页（全屏阻断）。
///
/// 由两种方式进入：
/// 1. 推：后端封号 → Reverb `main.command(banned/suspended)` 秒级推送；
/// 2. 拉：任一 API 请求返回 `X-User-Status` 头 / 登录返回 403 user_status 时兜底。
///
/// 展示封禁原因，提供联系客服与退出登录。不可返回、不可忽略。
class ColibriBlockedScreen extends StatelessWidget {
  final String status; // blocked / suspended
  final String? reason;

  const ColibriBlockedScreen({super.key, required this.status, this.reason});

  bool get _isSuspended => status == 'suspended';

  String get _title => _isSuspended ? '账号已被停用' : '账号已被封禁';

  String get _defaultDesc => _isSuspended
      ? '您的账号因违反社区规范已被停用。如有疑问，请联系客服申诉。'
      : '您的账号因违反社区规范已被封禁。如有疑问，请联系客服申诉。';

  void _logout() {
    // 复位封禁状态（用户手动退出，之后回登录页重新走认证流程）
    AppCommandHandler.shared.resetBlocked();
    SessionManager.shared.setToken('');
    SessionManager.shared.setLogin(false);
    SessionManager.shared.setColibriUser(null);
    if (Get.isRegistered<BookmarkStore>()) BookmarkStore.i.reset();
    if (Get.isRegistered<ChatUnreadStore>()) ChatUnreadStore.i.reset();
    Get.offAll(() => const LoginScreen());
  }

  @override
  Widget build(BuildContext context) {
    final supportEmail =
        SessionManager.shared.getSettings()?.supportEmail ?? '';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: cBlack,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 红色警示图标区
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.6, end: 1),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutBack,
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cRed.withValues(alpha: 0.12),
                          border: Border.all(
                            color: cRed.withValues(alpha: 0.45),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.gpp_bad_rounded,
                          color: cRed,
                          size: 60,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    Text(
                      _title,
                      textAlign: TextAlign.center,
                      style: MyTextStyle.gilroyExtraBold(
                          size: 24, color: Colors.white),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      reason?.isNotEmpty == true ? reason! : _defaultDesc,
                      textAlign: TextAlign.center,
                      style:
                          MyTextStyle.gilroyRegular(size: 15, color: cLightText)
                              .copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 32),

                    // 联系客服
                    if (supportEmail.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final uri = Uri(
                              scheme: 'mailto',
                              path: supportEmail,
                              queryParameters: {
                                'subject': '账号申诉 - $_title',
                              },
                            );
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.16)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: const Icon(Icons.mail_outline_rounded,
                              color: cLightIcon, size: 20),
                          label: Text('联系客服申诉',
                              style: MyTextStyle.gilroyBold(
                                  size: 15, color: Colors.white)),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // 退出登录
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _logout,
                        style: FilledButton.styleFrom(
                          backgroundColor: cRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text('退出登录',
                            style: MyTextStyle.gilroyBold(
                                size: 16, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text(
                      '如有疑问请联系平台客服',
                      style: MyTextStyle.gilroyRegular(
                          size: 12, color: cLightText),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

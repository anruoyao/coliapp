import 'package:flutter/material.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/managers/guest_session.dart';
import 'package:untitled/common/managers/haptic_manager.dart';
import 'package:untitled/screens/login_screen/sign_in_with_email_screen.dart';
import 'package:untitled/utilities/const.dart';

/// 统一的访客操作拦截器。
///
/// 访客（未登录 + 访客开关开启）触发任何需要身份的写/互动能力时，
/// 不发业务请求，直接弹出 [showGuestLoginSheet] 登录引导；
/// 已登录用户则原样执行 [action]。
class AuthGate {
  /// [feature] 为被拦截功能的中文名（如「点赞」「评论」「关注」），用于弹窗文案。
  static void requireLogin(VoidCallback action, {String? feature}) {
    if (GuestSession.i.isGuest) {
      HapticManager.shared.selection();
      showGuestLoginSheet(feature: feature);
      return;
    }
    action();
  }

  /// 不执行动作、仅打开登录引导（如「我的」页/受限 Tab 的独立登录按钮场景可直接用）。
  static void prompt({String? feature}) {
    HapticManager.shared.selection();
    showGuestLoginSheet(feature: feature);
  }
}

/// 底部中央登录提示弹窗。
///
/// 视觉：品牌绿软底图标 + 标题/说明 + 主按钮「登录」+ 次按钮「创建账号」+「继续看看」。
Future<bool?> showGuestLoginSheet({String? feature}) {
  return showColibriBottomSheetBuilder<bool>(
    context: Get.overlayContext ?? Get.context!,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    useSafeArea: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxHeight: 620),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: _GuestAuthCard(feature: feature),
    ),
  );
}

/// 打开登录/注册面板（复用现有邮箱认证底部弹层）。
/// [initialSignUp]=true 时直接展开注册表单。
void openAuthSheet({bool initialSignUp = false}) {
  showColibriBottomSheet(
    SignInWithEmailScreen(
        initialType:
            initialSignUp ? EmailSignInType.signUp : EmailSignInType.signIn),
    isScrollControlled: true,
    ignoreSafeArea: false,
  );
}

class _GuestAuthCard extends StatelessWidget {
  final String? feature;

  const _GuestAuthCard({this.feature});

  String get _subtitle {
    if (feature != null && feature!.isNotEmpty) {
      return '$feature需要登录账号。登录后还可评论、关注作者、私信与发布动态。';
    }
    return '登录后即可点赞、评论、关注作者、私信与发布动态，体验完整社区。';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cWhite,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 36,
              offset: const Offset(0, 14)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 顶部品牌绿柔光晕（装饰，提升质感）
          Positioned(
            top: -40,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    cPrimary.withValues(alpha: 0.22),
                    cPrimary.withValues(alpha: 0.0)
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 图标：软绿圆底 + 锁形
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cPrimarySoft,
                    border: Border.all(
                        color: cPrimary.withValues(alpha: 0.35), width: 1.2),
                  ),
                  child: const Icon(Icons.lock_outline_rounded,
                      color: cGreen, size: 30),
                ),
                const SizedBox(height: 14),
                Text(
                  '该功能需登录后使用',
                  style: MyTextStyle.gilroyBold(size: 19, color: cMainText),
                ),
                const SizedBox(height: 8),
                Text(
                  _subtitle,
                  textAlign: TextAlign.center,
                  style: MyTextStyle.gilroyLight(color: cLightText, size: 13.5),
                ),
                const SizedBox(height: 20),
                // 主操作：登录
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    openAuthSheet();
                  },
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cPrimary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: cPrimary.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.login_rounded,
                            color: cWhite, size: 19),
                        const SizedBox(width: 8),
                        Text('登 录',
                            style: MyTextStyle.gilroyBold(
                                size: 15.5, color: cWhite)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // 次操作：创建账号（描边）
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    openAuthSheet(initialSignUp: true);
                  },
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: cPrimary.withValues(alpha: 0.55), width: 1.4),
                    ),
                    child: Text('创建新账号',
                        style: MyTextStyle.gilroySemiBold(
                            size: 15, color: cGreen)),
                  ),
                ),
                const SizedBox(height: 6),
                // 关闭：继续浏览
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(foregroundColor: cLightText),
                  child: Text('继续看看',
                      style: MyTextStyle.gilroyMedium(
                          size: 13.5, color: cLightText)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

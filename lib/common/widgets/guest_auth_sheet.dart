import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'package:untitled/common/managers/guest_session.dart';
import 'package:untitled/common/managers/haptic_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/login_screen/sign_in_with_email_screen.dart';
import 'package:untitled/utilities/const.dart';

class AuthGate {
  static void requireLogin(VoidCallback action, {String? feature}) {
    if (GuestSession.i.isGuest) {
      HapticManager.shared.selection();
      showGuestLoginSheet(feature: feature);
      return;
    }
    action();
  }

  static void prompt({String? feature}) {
    HapticManager.shared.selection();
    showGuestLoginSheet(feature: feature);
  }
}

Future<bool?> showGuestLoginSheet({String? feature}) {
  return showColibriBottomSheetBuilder<bool>(
    context: Get.overlayContext ?? Get.context!,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxHeight: 620),
    builder: (_) => _GuestAuthSheet(feature: feature),
  );
}

void openAuthSheet({bool initialSignUp = false}) {
  showColibriBottomSheet(
    SignInWithEmailScreen(
      initialType:
          initialSignUp ? EmailSignInType.signUp : EmailSignInType.signIn,
    ),
    isScrollControlled: true,
    ignoreSafeArea: false,
  );
}

class _GuestAuthSheet extends StatelessWidget {
  const _GuestAuthSheet({this.feature});

  final String? feature;

  String get _subtitle {
    if (feature != null && feature!.isNotEmpty) {
      return LKeys.commonFeatureRequiresLogin.trParams({'p1': '${feature}'});
    }
    return LKeys.commonGuestSignInDesc.tr;
  }

  @override
  Widget build(BuildContext context) {
    return ColibriSheetSurface(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ColibriSheetHeader(
            title: LKeys.commonLoginChatter.tr,
            trailing: const ColibriSheetCloseButton(),
          ),
          const SizedBox(height: 12),
          const Icon(Icons.lock_outline_rounded,
              size: 32, color: Color(0xFF007AFF)),
          const SizedBox(height: 8),
          Text(
            LKeys.commonLoginRequired.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1C1C1E),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF636366),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAuthSheet();
              },
              style: FilledButton.styleFrom(
                backgroundColor: cPrimary,
                foregroundColor: cWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(LKeys.commonSignIn.tr),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAuthSheet(initialSignUp: true);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF007AFF),
              minimumSize: const Size.fromHeight(44),
            ),
            child: Text(LKeys.commonCreateAccount.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8E8E93),
              minimumSize: const Size.fromHeight(40),
            ),
            child: Text(LKeys.commonContinueBrowsing.tr),
          ),
        ],
      ),
    );
  }
}

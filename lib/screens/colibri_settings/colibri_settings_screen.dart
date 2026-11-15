import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_api.dart';
import 'package:untitled/common/managers/guest_session.dart';
import 'package:untitled/common/managers/haptic_manager.dart';
import 'package:untitled/common/managers/reverb_service.dart';
import 'package:untitled/common/widgets/colibri_ui.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/colibri_settings/colibri_authorship_screen.dart';
import 'package:untitled/screens/colibri_settings/colibri_credentials_screen.dart';
import 'package:untitled/screens/colibri_settings/colibri_language_screen.dart';
import 'package:untitled/screens/colibri_settings/colibri_notifications_screen.dart';
import 'package:untitled/screens/colibri_settings/colibri_privacy_screen.dart';
import 'package:untitled/screens/colibri_settings/colibri_social_media_screen.dart';
import 'package:untitled/screens/colibri_settings/colibri_verification_screen.dart';
import 'package:untitled/screens/colibri_feed/colibri_feed_screen.dart';
import 'package:untitled/screens/colibri_home/colibri_home_screen.dart';
import 'package:untitled/screens/colibri_social/colibri_block_list_screen.dart';
import 'package:untitled/screens/login_screen/login_screen.dart';
import 'package:untitled/utilities/const.dart';

/// 设置中心：分组卡片式布局（浅灰底 + 白卡片 + 图标 chip 行）。
class ColibriSettingsScreen extends StatelessWidget {
  const ColibriSettingsScreen({super.key});

  Future<void> _logout() async {
    ReverbService.shared.disconnect();
    await ColibriApi.shared.logout();
    // 登出后重新检测访客开关：开启 → 回到访客主界面继续浏览；关闭 → 登录页
    final guestAllowed = await GuestSession.i.detectForUnauthenticated();
    if (guestAllowed) {
      if (Get.isRegistered<ColibriFeedController>()) {
        Get.delete<ColibriFeedController>();
      }
      Get.offAll(() => const ColibriHomeScreen());
    } else {
      Get.offAll(() => const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBG,
      appBar: AppBar(
        backgroundColor: cBG,
        surfaceTintColor: cBG,
        elevation: 0,
        title: Text(LKeys.settingsTitle.tr,
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 17, color: cMainText)),
        leading: BackButton(color: cBlack, onPressed: () => Get.back()),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ColibriSectionLabel(LKeys.settingsSectionAccount.tr),
          _SettingsCard(children: [
            _SettingsRow(
                Icons.badge_outlined,
                LKeys.settingsAuthorship.tr,
                () => openColibriSettingPage(
                    context, const ColibriAuthorshipScreen())),
            _SettingsRow(
                Icons.lock_person_outlined,
                LKeys.settingsCredentials.tr,
                () => openColibriSettingPage(
                    context, const ColibriCredentialsScreen())),
          ]),
          ColibriSectionLabel(LKeys.settingsSectionNotificationsPrivacy.tr),
          _SettingsCard(children: [
            _SettingsRow(
                Icons.notifications_none_rounded,
                LKeys.commonNotifications.tr,
                () => openColibriSettingPage(
                    context, const ColibriSettingsNotificationsScreen())),
            _SettingsRow(
                Icons.visibility_outlined,
                LKeys.settingsAccountPrivacy.tr,
                () => openColibriSettingPage(
                    context, const ColibriPrivacyScreen())),
          ]),
          ColibriSectionLabel(LKeys.settingsSectionGeneral.tr),
          _SettingsCard(children: [
            _SettingsRow(
                Icons.language_rounded,
                LKeys.settingsLanguage.tr,
                () => openColibriSettingPage(
                    context, const ColibriLanguageScreen())),
            _SettingsRow(
                Icons.link_rounded,
                LKeys.settingsSocialMedia.tr,
                () => openColibriSettingPage(
                    context, const ColibriSocialMediaScreen())),
            _SettingsRow(
                Icons.verified_user_outlined,
                LKeys.settingsVerification.tr,
                () => openColibriSettingPage(
                    context, const ColibriVerificationScreen())),
          ]),
          ColibriSectionLabel(LKeys.settingsSectionOther.tr),
          _SettingsCard(children: [
            Obx(() => _SettingsSwitchRow(
                  icon: Icons.vibration_rounded,
                  label: LKeys.settingsVibrationFeedback.tr,
                  subtitle: LKeys.settingsVibrationFeedbackDescription.tr,
                  value: HapticManager.shared.enabled.value,
                  onChanged: (v) => HapticManager.shared.setEnabled(v),
                )),
          ]),
          ColibriSectionLabel(LKeys.settingsSectionAccountManagement.tr),
          _SettingsCard(children: [
            _SettingsRow(
                Icons.block_rounded,
                LKeys.settingsBlockList.tr,
                () => openColibriSettingPage(
                    context, const ColibriBlockListScreen())),
            _SettingsRow(
                Icons.notifications_off_outlined,
                LKeys.settingsMuteList.tr,
                () => openColibriSettingPage(
                    context, const ColibriBlockListScreen(isMutedList: true))),
            _SettingsRow(Icons.logout_rounded, LKeys.settingsLogOut.tr, _logout,
                danger: true),
          ]),
        ],
      ),
    );
  }
}

/// 分组卡片容器（白底圆角）。
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Divider(
                  height: 1, indent: 68, endIndent: 0, color: cLightBg),
          ],
        ],
      ),
    );
  }
}

/// 设置行：图标 chip + 标题 + 右箭头。
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _SettingsRow(this.icon, this.label, this.onTap, {this.danger = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            ColibriIconChip(icon: icon, danger: danger, size: 40, iconSize: 21),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: danger ? cRed : cMainText),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: cLightIcon, size: 22),
          ],
        ),
      ),
    );
  }
}

/// 设置卡片内的开关行：图标 chip + 标题/副标题 + Switch（与 _SettingsRow 同风格）。
class _SettingsSwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchRow({
    required this.icon,
    required this.label,
    this.subtitle = '',
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        children: [
          ColibriIconChip(icon: icon, size: 40, iconSize: 21),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cMainText)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style:
                          const TextStyle(fontSize: 11.5, color: cLightText)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: cPrimary,
          ),
        ],
      ),
    );
  }
}

/// 通用设置页单行（图标 + 标题 + 说明）。
class ColibriSettingToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ColibriSettingToggleRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: cLightIcon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 15, color: cMainText)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 11, color: cLightText)),
                ],
              ],
            ),
          ),
          Switch(
              value: value, onChanged: onChanged, activeThumbColor: cPrimary),
        ],
      ),
    );
  }
}

/// 设置页通用「保存」按钮。
class ColibriSettingsSaveButton extends StatelessWidget {
  final String? text;
  final bool loading;
  final VoidCallback onTap;

  const ColibriSettingsSaveButton(
      {super.key, required this.onTap, this.text, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 50,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
            color: loading ? cLightText.withValues(alpha: 0.4) : cPrimary,
            borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: Colors.white))
            : Text(text ?? LKeys.settingsSaveChanges.tr,
                style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
      ),
    );
  }
}

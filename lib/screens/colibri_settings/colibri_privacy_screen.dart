import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_settings_service.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/colibri_settings/colibri_settings_screen.dart';
import 'package:untitled/utilities/const.dart';

/// 账号隐私：谁可以 @提及 / 关注我 / 私信 / 回复故事 / 加群 / 转账。
class ColibriPrivacyScreen extends StatefulWidget {
  const ColibriPrivacyScreen({super.key});

  @override
  State<ColibriPrivacyScreen> createState() => _ColibriPrivacyScreenState();
}

class _ColibriPrivacyScreenState extends State<ColibriPrivacyScreen> {
  final _fields = [
    (
      'mentions',
      LKeys.settingsPrivacyMentions.tr,
      const ['all', 'followers', 'nobody', 'approved'],
      {
        'all': LKeys.settingsPrivacyEveryone.tr,
        'followers': LKeys.settingsPrivacyFollowers.tr,
        'nobody': LKeys.settingsPrivacyNobody.tr,
        'approved': LKeys.settingsPrivacyApproved.tr
      }
    ),
    (
      'followers',
      LKeys.settingsPrivacyWhoCanFollowMe.tr,
      const ['all', 'approved'],
      {
        'all': LKeys.settingsPrivacyEveryone.tr,
        'followers': LKeys.settingsPrivacyFollowers.tr,
        'nobody': LKeys.settingsPrivacyNobody.tr,
        'approved': LKeys.settingsPrivacyRequiresApproval.tr
      }
    ),
    (
      'direct_messages',
      LKeys.settingsPrivacyWhoCanMessageMe.tr,
      const ['all', 'followers', 'nobody', 'approved'],
      {
        'all': LKeys.settingsPrivacyEveryone.tr,
        'followers': LKeys.settingsPrivacyFollowers.tr,
        'nobody': LKeys.settingsPrivacyNobody.tr,
        'approved': LKeys.settingsPrivacyApproved.tr
      }
    ),
    (
      'story_replies',
      LKeys.settingsPrivacyWhoCanReplyToStories.tr,
      const ['all', 'followers', 'nobody', 'approved'],
      {
        'all': LKeys.settingsPrivacyEveryone.tr,
        'followers': LKeys.settingsPrivacyFollowers.tr,
        'nobody': LKeys.settingsPrivacyNobody.tr,
        'approved': LKeys.settingsPrivacyApproved.tr
      }
    ),
    (
      'group_invites',
      LKeys.settingsPrivacyWhoCanInviteToGroups.tr,
      const ['all', 'followers', 'nobody', 'approved'],
      {
        'all': LKeys.settingsPrivacyEveryone.tr,
        'followers': LKeys.settingsPrivacyFollowers.tr,
        'nobody': LKeys.settingsPrivacyNobody.tr,
        'approved': LKeys.settingsPrivacyApproved.tr
      }
    ),
    (
      'payment_transfers',
      LKeys.settingsPrivacyWhoCanSendMoney.tr,
      const ['all', 'followers', 'nobody', 'approved'],
      {
        'all': LKeys.settingsPrivacyEveryone.tr,
        'followers': LKeys.settingsPrivacyFollowers.tr,
        'nobody': LKeys.settingsPrivacyNobody.tr,
        'approved': LKeys.settingsPrivacyApproved.tr
      }
    ),
  ];

  Map<String, dynamic>? _settings;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ColibriSettingsService.shared.fetchPrivacySettings();
      if (mounted) setState(() => _settings = data);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ColibriSettingsService.shared.updatePrivacySettings(_settings!);
      showColibriToast(LKeys.settingsSaved.tr,
          message: '', backgroundColor: cGreen, colorText: Colors.white);
    } catch (e) {
      showColibriToast(LKeys.settingsSaveFailed.tr,
          message: e.toString(),
          backgroundColor: cRed,
          colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cWhite,
      appBar: AppBar(
        backgroundColor: cWhite,
        elevation: 0,
        title: Text(LKeys.settingsAccountPrivacy.tr,
            style:
                const TextStyle(fontWeight: FontWeight.bold, color: cMainText)),
        leading: BackButton(color: cBlack, onPressed: () => Get.back()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: cPrimary))
          : ListView(
              children: [
                const SizedBox(height: 8),
                ..._fields.map((f) {
                  final key = f.$1;
                  final title = f.$2;
                  final cur = _settings?[key]?.toString() ?? 'all';
                  final labels = f.$4;
                  return Column(
                    children: [
                      _segmented(title, key, cur, f.$3, labels),
                      const Divider(height: 1, color: cLightBg),
                    ],
                  );
                }),
                const SizedBox(height: 12),
                ColibriSettingsSaveButton(loading: _saving, onTap: _save),
              ],
            ),
    );
  }

  Widget _segmented(String title, String key, String cur, List<String> options,
      Map allowedTitle) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, color: cMainText)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((o) {
              final selected = o == cur;
              return GestureDetector(
                onTap: () => setState(() => _settings![key] = o),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? cPrimary : cLightBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    allowedTitle[o] ?? o,
                    style: TextStyle(
                        color: selected ? Colors.white : cMainText,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

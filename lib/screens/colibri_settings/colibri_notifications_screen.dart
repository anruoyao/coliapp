import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_settings_service.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/colibri_settings/colibri_settings_screen.dart';
import 'package:untitled/utilities/const.dart';

/// 通知设置（设置页）：推送 / 邮件 两类，各自 7 个开关。
class ColibriSettingsNotificationsScreen extends StatefulWidget {
  const ColibriSettingsNotificationsScreen({super.key});

  @override
  State<ColibriSettingsNotificationsScreen> createState() =>
      _ColibriSettingsNotificationsScreenState();
}

class _ColibriSettingsNotificationsScreenState
    extends State<ColibriSettingsNotificationsScreen> {
  final _keys = [
    'direct_messages',
    'reactions',
    'comments',
    'shared_posts',
    'followers',
    'follow_request',
    'mentions',
    'platform_notifications'
  ];
  final _labels = {
    'direct_messages': (
      LKeys.settingsDirectMessages.tr,
      LKeys.settingsNotifyDirectMessages.tr
    ),
    'reactions': (LKeys.feedReaction.tr, LKeys.settingsNotifyReactions.tr),
    'comments': (LKeys.feedComment.tr, LKeys.settingsNotifyComments.tr),
    'shared_posts': (LKeys.feedShare.tr, LKeys.settingsNotifyShares.tr),
    'followers': (
      LKeys.settingsNewFollowers.tr,
      LKeys.settingsNotifyNewFollowers.tr
    ),
    'follow_request': (
      LKeys.settingsFollowRequests.tr,
      LKeys.settingsNotifyFollowRequests.tr
    ),
    'mentions': (LKeys.settingsMentions.tr, LKeys.settingsNotifyMentions.tr),
    'platform_notifications': (
      LKeys.settingsPlatformNotifications.tr,
      LKeys.settingsPlatformNotificationsDescription.tr
    ),
  };

  Map<String, dynamic>? _push;
  Map<String, dynamic>? _email;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final push =
          await ColibriSettingsService.shared.fetchPushNotificationSettings();
      final email =
          await ColibriSettingsService.shared.fetchEmailNotificationSettings();
      if (mounted)
        setState(() {
          _push = push;
          _email = email;
        });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _savePush(String key, bool v) async {
    final cur = Map<String, dynamic>.from(_push!);
    cur[key] = v;
    setState(() => _push = cur);
    try {
      // 后端每个字段缺省为 false，必须提交完整状态，否则未勾选的项会被重置
      await ColibriSettingsService.shared.updatePushNotificationSettings(cur);
      showColibriToast(LKeys.settingsSaved.tr,
          message: '', backgroundColor: cGreen, colorText: Colors.white);
    } catch (e) {
      cur[key] = !v;
      setState(() => _push = cur);
      showColibriToast(LKeys.settingsSaveFailed.tr,
          message: e.toString(),
          backgroundColor: cRed,
          colorText: Colors.white);
    }
  }

  Future<void> _saveEmail(String key, bool v) async {
    final cur = Map<String, dynamic>.from(_email!);
    cur[key] = v;
    setState(() => _email = cur);
    try {
      // 后端每个字段缺省为 false，必须提交完整状态，否则未勾选的项会被重置
      await ColibriSettingsService.shared.updateEmailNotificationSettings(cur);
      showColibriToast(LKeys.settingsSaved.tr,
          message: '', backgroundColor: cGreen, colorText: Colors.white);
    } catch (e) {
      cur[key] = !v;
      setState(() => _email = cur);
      showColibriToast(LKeys.settingsSaveFailed.tr,
          message: e.toString(),
          backgroundColor: cRed,
          colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: cWhite,
        appBar: AppBar(
          backgroundColor: cWhite,
          elevation: 0,
          title: Text(LKeys.commonNotifications.tr,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: cMainText)),
          leading: BackButton(color: cBlack, onPressed: () => Get.back()),
          bottom: TabBar(
            labelColor: cPrimary,
            unselectedLabelColor: cLightText,
            indicatorColor: cPrimary,
            tabs: [
              Tab(text: LKeys.settingsPushNotifications.tr),
              Tab(text: LKeys.settingsEmailNotifications.tr)
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: cPrimary))
            : TabBarView(
                children: [
                  ListView(
                    children: _keys.map((k) {
                      final info = _labels[k]!;
                      return ColibriSettingToggleRow(
                        icon: Icons.notifications_none_rounded,
                        title: info.$1,
                        subtitle: info.$2,
                        value: _push![k] == true,
                        onChanged: (v) => _savePush(k, v),
                      );
                    }).toList(),
                  ),
                  ListView(
                    children: _keys.map((k) {
                      final info = _labels[k]!;
                      return ColibriSettingToggleRow(
                        icon: Icons.email_outlined,
                        title: info.$1,
                        subtitle: info.$2,
                        value: _email![k] == true,
                        onChanged: (v) => _saveEmail(k, v),
                      );
                    }).toList(),
                  ),
                ],
              ),
      ),
    );
  }
}

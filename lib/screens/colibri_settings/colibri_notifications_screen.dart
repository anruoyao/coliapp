import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_settings_service.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
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
    'direct_messages': ('私信', '收到新私信时通知'),
    'reactions': ('表情反应', '有人给动态点表情时通知'),
    'comments': ('评论', '有人评论你的内容时通知'),
    'shared_posts': ('分享', '你的内容被分享时通知'),
    'followers': ('新粉丝', '有人关注你时通知'),
    'follow_request': ('关注请求', '收到关注请求时通知'),
    'mentions': ('提及', '有人 @ 你时通知'),
    'platform_notifications': ('平台通知', '接收平台官方活动与营销相关通知'),
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
      showColibriToast('已保存',
          message: '', backgroundColor: cGreen, colorText: Colors.white);
    } catch (e) {
      cur[key] = !v;
      setState(() => _push = cur);
      showColibriToast('保存失败',
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
      showColibriToast('已保存',
          message: '', backgroundColor: cGreen, colorText: Colors.white);
    } catch (e) {
      cur[key] = !v;
      setState(() => _email = cur);
      showColibriToast('保存失败',
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
          title: const Text('通知',
              style: TextStyle(fontWeight: FontWeight.bold, color: cMainText)),
          leading: BackButton(color: cBlack, onPressed: () => Get.back()),
          bottom: const TabBar(
            labelColor: cPrimary,
            unselectedLabelColor: cLightText,
            indicatorColor: cPrimary,
            tabs: [Tab(text: '推送通知'), Tab(text: '邮件通知')],
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

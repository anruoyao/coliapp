import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_settings_service.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
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
      '谁能 @ 提及我',
      const ['all', 'followers', 'nobody', 'approved'],
      {'all': '所有人', 'followers': '仅粉丝', 'nobody': '没有人', 'approved': '我批准的人'}
    ),
    (
      'followers',
      '谁能关注我',
      const ['all', 'approved'],
      {'all': '所有人', 'followers': '仅粉丝', 'nobody': '没有人', 'approved': '需我批准'}
    ),
    (
      'direct_messages',
      '谁能私信我',
      const ['all', 'followers', 'nobody', 'approved'],
      {'all': '所有人', 'followers': '仅粉丝', 'nobody': '没有人', 'approved': '我批准的人'}
    ),
    (
      'story_replies',
      '谁能回复我的故事',
      const ['all', 'followers', 'nobody', 'approved'],
      {'all': '所有人', 'followers': '仅粉丝', 'nobody': '没有人', 'approved': '我批准的人'}
    ),
    (
      'group_invites',
      '谁能邀请我加群',
      const ['all', 'followers', 'nobody', 'approved'],
      {'all': '所有人', 'followers': '仅粉丝', 'nobody': '没有人', 'approved': '我批准的人'}
    ),
    (
      'payment_transfers',
      '谁能给我转账',
      const ['all', 'followers', 'nobody', 'approved'],
      {'all': '所有人', 'followers': '仅粉丝', 'nobody': '没有人', 'approved': '我批准的人'}
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
      showColibriToast('已保存',
          message: '', backgroundColor: cGreen, colorText: Colors.white);
    } catch (e) {
      showColibriToast('保存失败',
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
        title: const Text('账号隐私',
            style: TextStyle(fontWeight: FontWeight.bold, color: cMainText)),
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

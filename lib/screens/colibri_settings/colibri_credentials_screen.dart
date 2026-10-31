import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_settings_service.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
import 'package:untitled/screens/colibri_settings/colibri_settings_screen.dart';
import 'package:untitled/utilities/const.dart';

/// 账号凭证：展示邮箱 / 手机号 / 登录通知开关。
class ColibriCredentialsScreen extends StatefulWidget {
  const ColibriCredentialsScreen({super.key});

  @override
  State<ColibriCredentialsScreen> createState() =>
      _ColibriCredentialsScreenState();
}

class _ColibriCredentialsScreenState extends State<ColibriCredentialsScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ColibriSettingsService.shared.fetchCredentials();
      if (mounted) setState(() => _data = data);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleLoginNotification(bool v) async {
    setState(() => _saving = true);
    try {
      await ColibriSettingsService.shared.updateLoginNotification(v);
      if (mounted && _data != null) {
        final sec =
            Map<String, dynamic>.from(_data!['security_settings'] as Map);
        sec['login_notification'] = v;
        setState(() => _data!['security_settings'] = sec);
      }
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
        title: const Text('账号凭证',
            style: TextStyle(fontWeight: FontWeight.bold, color: cMainText)),
        leading: BackButton(color: cBlack, onPressed: () => Get.back()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: cPrimary))
          : ListView(
              children: [
                const SizedBox(height: 8),
                _infoRow(Icons.email_outlined, '邮箱',
                    _data?['email']?.toString() ?? ''),
                const Divider(height: 1, color: cLightBg),
                _infoRow(Icons.phone_android_rounded, '手机号',
                    _data?['phone']?.toString() ?? '未绑定'),
                const Divider(height: 1, color: cLightBg),
                if (_data?['security_settings'] is Map) ...[
                  ColibriSettingToggleRow(
                    icon: Icons.notifications_active_outlined,
                    title: '登录通知',
                    subtitle: '有新的登录活动时提醒我',
                    value: ((_data!['security_settings']
                            as Map)['login_notification']) ==
                        true,
                    onChanged: _saving ? (_) {} : _toggleLoginNotification,
                  ),
                ],
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('管理你的登录凭证与安全通知。邮箱用于登录与找回密码。',
                      style: TextStyle(fontSize: 12, color: cLightText)),
                ),
              ],
            ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: cLightIcon),
      title:
          Text(label, style: const TextStyle(fontSize: 13, color: cLightText)),
      subtitle:
          Text(value, style: const TextStyle(fontSize: 16, color: cMainText)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_settings_service.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
import 'package:untitled/screens/colibri_settings/colibri_settings_screen.dart';
import 'package:untitled/utilities/const.dart';

/// 社交媒体：填写各平台主页链接（留空不保存）。
class ColibriSocialMediaScreen extends StatefulWidget {
  const ColibriSocialMediaScreen({super.key});

  @override
  State<ColibriSocialMediaScreen> createState() =>
      _ColibriSocialMediaScreenState();
}

class _ColibriSocialMediaScreenState extends State<ColibriSocialMediaScreen> {
  List<Map<String, dynamic>>? _links;
  final Map<String, TextEditingController> _controllers = {};
  bool _loading = true;
  bool _saving = false;

  final _platformMap = {
    'youtube': (Icons.play_circle_outline, 'YouTube'),
    'twitter': (Icons.alternate_email, 'Twitter'),
    'instagram': (Icons.camera_alt_outlined, 'Instagram'),
    'whatsapp': (Icons.chat_bubble_outline, 'WhatsApp'),
    'telegram': (Icons.send_outlined, 'Telegram'),
    'facebook': (Icons.thumb_up_outlined, 'Facebook'),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await ColibriSettingsService.shared.fetchSocialLinks();
      for (final l in list) {
        final p = l['platform']?.toString() ?? '';
        _controllers[p] =
            TextEditingController(text: l['url']?.toString() ?? '');
      }
      if (mounted) setState(() => _links = list);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final links = (_links ?? []).map((l) {
        return {
          'platform': l['platform'],
          'url': _controllers[l['platform']]?.text.trim() ?? ''
        };
      }).toList();
      await ColibriSettingsService.shared.updateSocialLinks(links);
      showColibriToast('已保存',
          message: '社交媒体链接已更新',
          backgroundColor: cGreen,
          colorText: Colors.white);
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
        title: const Text('社交媒体',
            style: TextStyle(fontWeight: FontWeight.bold, color: cMainText)),
        leading: BackButton(color: cBlack, onPressed: () => Get.back()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: cPrimary))
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text('填写各平台的个人主页链接，会显示在你的个人简介中。',
                      style: const TextStyle(fontSize: 13, color: cLightText)),
                ),
                ...(_links ?? []).map((l) {
                  final p = l['platform']?.toString() ?? '';
                  final meta =
                      _platformMap[p] ?? (Icons.link_rounded, p.toUpperCase());
                  return ListTile(
                    leading: Icon(meta.$1, color: cLightIcon, size: 26),
                    title: Text(meta.$2,
                        style: const TextStyle(fontSize: 15, color: cMainText)),
                    subtitle: TextField(
                      controller: _controllers[p],
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                          hintText: 'https://...',
                          border: InputBorder.none,
                          isDense: true),
                      style: const TextStyle(fontSize: 13, color: cLightText),
                    ),
                  );
                }),
                ColibriSettingsSaveButton(loading: _saving, onTap: _save),
              ],
            ),
    );
  }
}

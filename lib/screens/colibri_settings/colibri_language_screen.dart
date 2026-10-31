import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_settings_service.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
import 'package:untitled/utilities/const.dart';

/// 语言设置（Beta）：切换界面语言。App 尚未接入完整多语言，属预留入口。
class ColibriLanguageScreen extends StatefulWidget {
  const ColibriLanguageScreen({super.key});

  @override
  State<ColibriLanguageScreen> createState() => _ColibriLanguageScreenState();
}

class _ColibriLanguageScreenState extends State<ColibriLanguageScreen> {
  List<Map<String, dynamic>>? _languages;
  String? _current;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await ColibriSettingsService.shared.fetchLanguages();
      String? cur;
      for (final l in list) {
        if (l['current'] == true) cur = l['code']?.toString();
      }
      if (mounted)
        setState(() {
          _languages = list;
          _current = cur;
        });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _switch(String code) async {
    if (code == _current) return;
    setState(() => _saving = true);
    try {
      await ColibriSettingsService.shared.switchLanguage(code);
      if (mounted)
        setState(() {
          _current = code;
          for (final l in _languages!) {
            l['current'] = l['code'] == code;
          }
        });
      showColibriToast('已切换',
          message: '界面语言已切换（部分文案将在后续版本逐步生效）',
          backgroundColor: cGreen,
          colorText: Colors.white);
    } catch (e) {
      showColibriToast('切换失败',
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
        title: const Text('语言',
            style: TextStyle(fontWeight: FontWeight.bold, color: cMainText)),
        leading: BackButton(color: cBlack, onPressed: () => Get.back()),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: cPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10)),
            child: const Text('Beta',
                style: TextStyle(
                    fontSize: 11,
                    color: cPrimary,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: cPrimary))
          : ListView(
              children: [
                const SizedBox(height: 8),
                ...(_languages ?? []).map((l) {
                  final code = l['code']?.toString() ?? '';
                  final name = l['name']?.toString() ?? code;
                  final selected = code == _current;
                  return ListTile(
                    onTap: _saving ? null : () => _switch(code),
                    leading: Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.language_rounded,
                        color: selected ? cPrimary : cLightIcon),
                    title: Text(name,
                        style: const TextStyle(fontSize: 15, color: cMainText)),
                    trailing: selected
                        ? Text('当前',
                            style:
                                const TextStyle(fontSize: 12, color: cPrimary))
                        : null,
                  );
                }),
                const Divider(height: 1, color: cLightBg),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('App 多语言功能仍在开发中，切换后部分界面文字将在后续版本逐步生效。',
                      style: TextStyle(fontSize: 12, color: cLightText)),
                ),
              ],
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_settings_service.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
import 'package:untitled/localization/allLanguages.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/utilities/const.dart';

/// 语言设置：切换界面语言，立即生效并尽力同步到服务端。
class ColibriLanguageScreen extends StatelessWidget {
  const ColibriLanguageScreen({super.key});

  Future<void> _switch(Lang lang) async {
    final current = SessionManager.shared.getLang();
    if (lang.language == current.language) return;

    SessionManager.shared.setLang(lang);
    await Get.updateLocale(lang.language.local);

    showColibriToast(LKeys.settingsLanguageSwitched.tr,
        message: LKeys.settingsLanguageSwitchedDescription.tr,
        backgroundColor: cGreen,
        colorText: Colors.white);

    if (SessionManager.shared.isLogin()) {
      try {
        await ColibriSettingsService.shared
            .switchLanguage(lang.language.languageCode);
      } catch (_) {
        // 服务端语言仅影响服务端消息，同步失败不影响本地界面切换。
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = SessionManager.shared.getLang();
    final items = LANGUAGES
        .where((l) => supportedLanguageCodes.contains(l.language.languageCode))
        .toList();

    return Scaffold(
      backgroundColor: cWhite,
      appBar: AppBar(
        backgroundColor: cWhite,
        elevation: 0,
        title: Text(LKeys.settingsLanguage.tr,
            style:
                const TextStyle(fontWeight: FontWeight.bold, color: cMainText)),
        leading: BackButton(color: cBlack, onPressed: () => Get.back()),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ...items.map((l) {
            final selected = l.language == current.language;
            return ListTile(
              onTap: selected ? null : () => _switch(l),
              leading: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.language_rounded,
                  color: selected ? cPrimary : cLightIcon),
              title: Text(l.displayName,
                  style: const TextStyle(fontSize: 15, color: cMainText)),
              trailing: selected
                  ? Text(LKeys.settingsCurrent.tr,
                      style: const TextStyle(fontSize: 12, color: cPrimary))
                  : null,
            );
          }),
        ],
      ),
    );
  }
}

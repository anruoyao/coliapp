import 'package:get/get.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/allLanguages.dart';

class LanguagesController extends BaseController {
  List<Lang> languages = LANGUAGES;
  Lang selectedLan = SessionManager.shared.getLang();

  void setLang(Lang lang) {
    selectedLan = lang;
    SessionManager.shared.setLang(lang);
    Get.updateLocale(lang.language.local);
  }
}

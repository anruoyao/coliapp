import 'dart:io';
import 'dart:ui';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:untitled/localization/allLanguages.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/models/setting_model.dart';

class SessionManager {
  static var shared = SessionManager();
  var storage = GetStorage();
  var conversationId = '';
  final RxMap<String, dynamic> colibriUserRx = <String, dynamic>{}.obs;

  SessionManager() {
    final stored = storage.read(SessionKeys.colibriUser);
    if (stored is Map)
      colibriUserRx.assignAll(Map<String, dynamic>.from(stored));
  }

  void setLang(Lang lang) {
    storage.write("lang", lang.language.languageCode);
  }

  Lang getLang() {
    final stored = storage.read("lang");
    if (stored is String && stored.isNotEmpty) {
      try {
        return LANGUAGES
            .firstWhere((element) => element.language.languageCode == stored);
      } catch (_) {
        // 存储的值无效，回退到设备语言检测
      }
    }
    return _detectDeviceLanguage();
  }

  /// 根据设备 locale 自动匹配支持的语言，未匹配时回退到英文。
  Lang _detectDeviceLanguage() {
    final deviceLocale = PlatformDispatcher.instance.locale;
    final deviceLang = deviceLocale.languageCode; // 例如 "zh"、"en"
    final deviceScript = deviceLocale.scriptCode; // 例如 "Hans"、"Hant"

    // 1) 优先精确匹配 languageCode + scriptCode（处理中文简繁体等情况）
    if (deviceScript != null) {
      final composed = '$deviceLang-$deviceScript';
      try {
        return LANGUAGES
            .firstWhere((element) => element.language.languageCode == composed);
      } catch (_) {
        // 无精确匹配，继续后续策略
      }
    }

    // 2) 匹配 languageCode（例如 "zh-Hans" 中的基础 "zh"）
    try {
      return LANGUAGES.firstWhere((element) {
        final code = element.language.languageCode;
        final base = code.split(RegExp(r'[-_]')).first;
        return base == deviceLang;
      });
    } catch (_) {
      // 3) 对于中文繁体设备，回退到简体中文
      if (deviceLang == 'zh') {
        try {
          return LANGUAGES.firstWhere(
              (element) => element.language.languageCode == 'zh-Hans');
        } catch (_) {}
      }
    }

    // 4) 最终回退到英文
    return LANGUAGES.first;
  }

  String getStoredConversation() {
    return conversationId;
  }

  void setStoredConversation(String conversation) {
    conversationId = conversation;
  }

  DateTime? getLastMessageReadDate({required String spaceId}) {
    var date = storage.read(spaceId);
    if (date is DateTime)
      return date;
    else
      return null;
  }

  void setLastMessageReadDate({required String spaceId}) {
    storage.write(spaceId, DateTime.now());
  }

  bool isLogin() {
    return storage.read(SessionKeys.isLogin) ?? false;
  }

  // ===== ColibriPlus 认证（Sanctum Bearer token）=====

  int _sessionRevision = 0;
  int _userRevision = 0;

  void setToken(String token) {
    _sessionRevision++;
    _userRevision++;
    if (token.isEmpty) setColibriUser(null);
    storage.write(SessionKeys.colibriToken, token);
  }

  /// Only the newest refresh in the same authenticated session may update UI.
  Future<void> refreshColibriUser(
    Future<Map<String, dynamic>?> Function() fetch,
  ) async {
    final token = getToken();
    if (token == null || token.isEmpty) return;
    final session = _sessionRevision;
    final revision = ++_userRevision;
    final user = await fetch();
    if (session != _sessionRevision ||
        revision != _userRevision ||
        token != getToken()) return;
    if (user != null) setColibriUser(user);
  }

  String? getToken() {
    return storage.read(SessionKeys.colibriToken);
  }

  /// 当前登录用户的原始数据（来自 /api/bootstrap/bootstrap 或注册返回的 user）。
  void setColibriUser(Map<String, dynamic>? user) {
    _userRevision++;
    colibriUserRx.assignAll(user ?? const <String, dynamic>{});
    if (user == null) {
      storage.remove(SessionKeys.colibriUser);
    } else {
      storage.write(SessionKeys.colibriUser, Map<String, dynamic>.from(user));
    }
  }

  Map<String, dynamic>? getColibriUser() {
    return colibriUserRx.isEmpty
        ? null
        : Map<String, dynamic>.from(colibriUserRx);
  }

  void setUsersForGroup(
      {required String conversationId, required List<User> users}) {
    storage.write(conversationId, users);
  }

  List<User> getUsersForGroup({required String conversationId}) {
    var users = storage.read(conversationId);
    if (users is List<User>) {
      return users;
    } else if (users is List<dynamic>) {
      return users.map((user) => User.fromJson(user)).toList();
    }
    return [];
  }

  void setLogin(bool isLog) {
    storage.write(SessionKeys.isLogin, isLog);
  }

  void setUser(User? obj) {
    // 兜底：部分接口（老版本 fetchProfile、编辑资料等）的响应不含 ws_key，
    // 直接覆盖会导致 WsManager 冷启动时拿不到 key 而永不连接。
    if (obj != null && (obj.wsKey == null || obj.wsKey!.isEmpty)) {
      final old = getUser();
      if (old?.wsKey != null && old!.wsKey!.isNotEmpty) {
        obj.wsKey = old.wsKey;
      }
    }
    storage.write("user", obj);
  }

  User? getUser() {
    var user = storage.read("user");
    if (user is User?) {
      return user;
    } else {
      return User.fromJson(user);
    }
  }

  int getUserID() {
    return (getUser()?.id ?? 0).toInt();
  }

  void setSettings(Settings settings) {
    storage.write("setting", settings);
  }

  Settings? getSettings() {
    var data = storage.read("setting");
    if (data is Map<String, dynamic>) {
      return Settings.fromJson(data);
    } else if (data is Settings) {
      return data;
    }
    return null;
  }

  String getBannerAdId() {
    return (Platform.isAndroid
            ? (getSettings()?.adBannerAndroid)
            : (getSettings()?.adBannerIOs)) ??
        '';
  }

  String getInterstitialAdId() {
    return (Platform.isAndroid
            ? (getSettings()?.adInterstitialAndroid)
            : (getSettings()?.adInterstitialIOs)) ??
        '';
  }

  bool isAdMobOn() {
    return getSettings()?.isAdmobOn == 1 ? true : false;
  }

  void clear() {
    _sessionRevision++;
    setColibriUser(null);
    storage.erase();
  }
}

class SessionKeys {
  static const isLogin = "isLogin";
  static const colibriToken = "colibri_token";
  static const colibriUser = "colibri_user";
}

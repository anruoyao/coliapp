import 'package:untitled/common/api_service/colibri_api.dart';

/// ColibriPlus 账号设置 API（/settings/*）。
class ColibriSettingsService {
  static final shared = ColibriSettingsService();

  ColibriApi get _api => ColibriApi.shared;

  // ===================== 作者身份 =====================
  Future<String> fetchAuthorshipStatus() async {
    final resp = await _api.get('settings/authorship/settings');
    final data = resp['data'];
    if (data is Map<String, dynamic>)
      return data['status']?.toString() ?? 'not_requested';
    return 'not_requested';
  }

  Future<void> requestAuthorship() async {
    await _api.post('settings/authorship/request');
  }

  // ===================== 账号凭证 =====================
  Future<Map<String, dynamic>> fetchCredentials() async {
    final resp = await _api.get('settings/account/credentials/settings');
    return resp['data'] is Map<String, dynamic>
        ? resp['data'] as Map<String, dynamic>
        : <String, dynamic>{};
  }

  // ===================== 通知 =====================
  Future<Map<String, dynamic>> fetchPushNotificationSettings() async {
    final resp = await _api.get('settings/notifications/push/settings');
    return resp['data'] is Map<String, dynamic>
        ? resp['data'] as Map<String, dynamic>
        : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> fetchEmailNotificationSettings() async {
    final resp = await _api.get('settings/notifications/email/settings');
    return resp['data'] is Map<String, dynamic>
        ? resp['data'] as Map<String, dynamic>
        : <String, dynamic>{};
  }

  Future<void> updatePushNotificationSettings(
      Map<String, dynamic> settings) async {
    await _api.put('settings/notification/push/update', body: settings);
  }

  Future<void> updateEmailNotificationSettings(
      Map<String, dynamic> settings) async {
    await _api.put('settings/notification/email/update', body: settings);
  }

  Future<void> updateLoginNotification(bool enabled) async {
    await _api.put('settings/notifications/login/update',
        body: {'login_notification': enabled});
  }

  // ===================== 隐私 =====================
  Future<Map<String, dynamic>> fetchPrivacySettings() async {
    final resp = await _api.get('settings/privacy/settings');
    return resp['data'] is Map<String, dynamic>
        ? resp['data'] as Map<String, dynamic>
        : <String, dynamic>{};
  }

  Future<void> updatePrivacySettings(Map<String, dynamic> settings) async {
    await _api.put('settings/privacy/update', body: settings);
  }

  // ===================== 语言 =====================
  Future<List<Map<String, dynamic>>> fetchLanguages() async {
    final resp = await _api.get('settings/languages');
    final data = resp['data'];
    if (data is! List) return [];
    return data.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> switchLanguage(String code) async {
    await _api.put('settings/languages/switch', body: {'language': code});
  }

  // ===================== 社交媒体 =====================
  Future<List<Map<String, dynamic>>> fetchSocialLinks() async {
    final resp = await _api.get('settings/social/settings');
    final data = resp['data'];
    final links = data is Map<String, dynamic> ? data['links'] : null;
    if (links is! List) return [];
    return links.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> updateSocialLinks(List<Map<String, dynamic>> links) async {
    await _api.put('settings/social/update', body: {'links': links});
  }

  // ===================== 个人信息 =====================
  Future<Map<String, dynamic>> fetchPersonalInfo() async {
    final resp = await _api.get('settings/personal/settings');
    return resp['data'] is Map<String, dynamic>
        ? resp['data'] as Map<String, dynamic>
        : <String, dynamic>{};
  }

  /// 更新生日（含隐私开关）。birth_date: {day, month, year}。
  Future<void> updateBirthdate(
      {required int day,
      required int month,
      required int year,
      required bool privacy}) async {
    await _api.put('settings/personal/birthdate/update', body: {
      'birth_date': {'day': day, 'month': month, 'year': year},
      'birthdate_privacy': privacy,
    });
  }

  /// 更新国家（country 为两位大写代码，如 CN）。
  Future<void> updateCountry(
      {required String country, required bool privacy}) async {
    await _api.put('settings/personal/country/update', body: {
      'country': country,
      'country_privacy': privacy,
    });
  }

  /// 更新城市。
  Future<void> updateCity({required String city, required bool privacy}) async {
    await _api.put('settings/personal/city/update', body: {
      'city': city,
      'city_privacy': privacy,
    });
  }

  /// 获取国家列表（用于个人信息的国家选择）。
  Future<List<Map<String, dynamic>>> fetchCountries() async {
    final resp = await _api.get('settings/personal/country');
    final data = resp['data'];
    final countries = data is Map<String, dynamic> ? data['countries'] : null;
    if (countries is! List) return [];
    return countries.whereType<Map<String, dynamic>>().toList();
  }
}

import 'package:untitled/common/api_service/colibri_api.dart';

/// App 版本信息（对应后端 /api/system/version/check 返回的 latest）。
class ColibriVersionInfo {
  final String code;
  final String platform;
  final String downloadUrl;
  final String? notes;
  final bool forced;
  final DateTime? releasedAt;

  const ColibriVersionInfo({
    required this.code,
    required this.platform,
    required this.downloadUrl,
    required this.notes,
    required this.forced,
    required this.releasedAt,
  });

  factory ColibriVersionInfo.fromJson(Map<String, dynamic> json) {
    return ColibriVersionInfo(
      code: json['code']?.toString() ?? '',
      platform: json['platform']?.toString() ?? 'android',
      downloadUrl: json['download_url']?.toString() ?? '',
      notes: json['notes']?.toString(),
      forced: json['is_forced'] == true,
      releasedAt: DateTime.tryParse(json['released_at']?.toString() ?? ''),
    );
  }
}

/// 版本检测结果。
class ColibriVersionCheckResult {
  final bool hasUpdate;
  final bool forced;
  final ColibriVersionInfo? latest;

  const ColibriVersionCheckResult({
    required this.hasUpdate,
    required this.forced,
    required this.latest,
  });
}

/// ColibriPlus 版本检测 API（公共接口，无需登录）。
class ColibriVersionService {
  static final shared = ColibriVersionService();

  ColibriApi get _api => ColibriApi.shared;

  /// 请求后端检测指定平台/当前版本是否有新版本可用。
  /// 网络异常等静默失败场景由调用方处理（抛出 [ColibriApiException]）。
  Future<ColibriVersionCheckResult> checkUpdate({
    required String platform,
    required String currentCode,
  }) async {
    final resp = await _api.get(
      'system/version/check',
      query: {'platform': platform, 'code': currentCode},
      auth: false,
    );

    final data = resp['data'];
    if (data is! Map<String, dynamic>) {
      throw ColibriApiException('版本检测失败：响应缺少 data');
    }

    final latestJson = data['latest'];
    final latest = latestJson is Map<String, dynamic>
        ? ColibriVersionInfo.fromJson(latestJson)
        : null;

    return ColibriVersionCheckResult(
      hasUpdate: data['has_update'] == true,
      forced: data['forced'] == true,
      latest: latest,
    );
  }
}

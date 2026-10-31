import 'package:untitled/common/api_service/colibri_api.dart';

/// 媒体上传大小限制（上传前本地预检测）。
///
/// - 上传前从 `GET /api/system/upload/limits` 拉取后台配置的限制（KB），
///   本地用文件字节数与 `max * 1024` 对比，超限立即返回统一提示文案。
/// - 拉取结果内存缓存 5 分钟，避免每次上传都请求。
/// - 网络异常降级：拉取失败时使用内置默认值（与后端默认配置一致），
///   文案优先后端返回，失败时回退内置文案（与后端一致）。
class UploadLimitsService {
  static final shared = UploadLimitsService._();

  UploadLimitsService._();

  /// 内置默认限制（KB，与后端 database/settings 默认值一致）。
  static const Map<String, int> _defaultsKb = {
    'image': 128 * 1024,
    'video': 512 * 1024,
    'audio': 24 * 1024,
    'gif': 2 * 1024,
    'document': 24 * 1024,
  };

  /// 内置降级文案（与后端 lang/zh/api/upload.php 一致）。
  static const Map<String, String> _fallbackMessages = {
    'image': '图片文件大小不能超过 128 MB',
    'video': '视频文件大小不能超过 512 MB',
    'audio': '音频文件大小不能超过 24 MB',
    'gif': 'GIF 文件大小不能超过 2 MB',
    'document': '文档文件大小不能超过 24 MB',
  };

  Map<String, dynamic>? _limits;
  DateTime? _fetchedAt;
  static const _cacheTtl = Duration(minutes: 5);

  /// 拉取限制（带缓存）。失败时返回上次结果或 null（由调用方降级）。
  Future<Map<String, dynamic>?> _fetch() async {
    final now = DateTime.now();
    if (_limits != null &&
        _fetchedAt != null &&
        now.difference(_fetchedAt!) < _cacheTtl) {
      return _limits;
    }
    try {
      final resp =
          await ColibriApi.shared.get('system/upload/limits', auth: false);
      final data = resp['data'];
      if (data is Map<String, dynamic> && data.isNotEmpty) {
        _limits = data;
        _fetchedAt = now;
        return _limits;
      }
    } on ColibriApiException {
      // 网络异常 / 接口失败：使用缓存或内置默认值
    }
    return _limits;
  }

  /// 单个媒体类型的限制信息：{ max (KB), message }。
  /// 拉取失败且无缓存时返回内置默认值（message 为空，由 [check] 回退内置文案）。
  Future<({int max, String? message})> _limitFor(String type) async {
    final limits = await _fetch();
    final entry = limits?[type];
    if (entry is Map<String, dynamic> && entry['max'] is num) {
      final msg = entry['message']?.toString().trim();
      return (
        max: (entry['max'] as num).toInt(),
        message: (msg != null && msg.isNotEmpty) ? msg : null,
      );
    }
    return (max: _defaultsKb[type] ?? _defaultsKb['image']!, message: null);
  }

  /// 本地文件大小检测。
  ///
  /// [fileSizeBytes] 文件字节数；[type] 媒体类型：image / video / audio / gif / document。
  /// 超限返回提示文案（优先后端统一文案，降级内置文案）；未超限返回 null。
  Future<String?> check(int fileSizeBytes, String type) async {
    if (fileSizeBytes <= 0) return null;

    final limit = await _limitFor(type);
    if (fileSizeBytes > limit.max * 1024) {
      return limit.message ??
          (_fallbackMessages[type] ?? _fallbackMessages['image']!);
    }
    return null;
  }
}

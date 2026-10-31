import 'package:flutter/widgets.dart';
import 'package:untitled/common/api_service/colibri_api.dart';
import 'package:untitled/common/managers/session_manager.dart';

/// 在线状态管理器（P0 在线用户数）。
///
/// 职责：
///  1. 兜底生成并缓存设备标识 `colibri_client_id`（正式值由 [ColibriApi.clientId] 生成）；
///  2. 监听 App 前后台切换，调用后端心跳接口：
///     - 回到前台 → background=false（标记在线）
///     - 进入后台 → background=true（即刻离席，避免"幽灵在线"）
///
/// 常规请求本身已由后端 UserOnlineMiddleware + X-Client-Id 头覆盖在线上报，
/// 心跳只补充「前后台切换」的精确语义。
class PresenceManager with WidgetsBindingObserver {
  PresenceManager._();

  static final shared = PresenceManager._();

  bool _registered = false;

  /// 注册生命周期监听（main.dart 启动时调用一次即可）。
  void register() {
    if (_registered) return;
    _registered = true;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _heartbeat(background: false);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _heartbeat(background: true);
        break;
      default:
        break;
    }
  }

  Future<void> _heartbeat({required bool background}) async {
    final token = SessionManager.shared.getToken();
    if (token == null || token.isEmpty) return;

    try {
      await ColibriApi.shared.heartbeat(background: background);
    } catch (_) {
      // 心跳失败静默处理，不打扰用户（下次请求/前台切换重试）
    }
  }
}

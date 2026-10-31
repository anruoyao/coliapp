import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_api.dart';
import 'package:untitled/common/api_service/colibri_version_service.dart';
import 'package:untitled/common/managers/reverb_service.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/screens/colibri_home/colibri_home_screen.dart';
import 'package:untitled/screens/colibri_social/colibri_blocked_screen.dart';
import 'package:untitled/screens/colibri_social/colibri_maintenance_screen.dart';
import 'package:untitled/screens/login_screen/login_screen.dart';
import 'package:untitled/screens/update_screen/forced_update_screen.dart';

/// 服务端指令统一处理器（封禁 / 解封 / 维护模式）。
///
/// 推 + 拉结合：
/// - 推：Reverb `main.command`（用户私有频道收封禁指令；公共频道收维护指令）
/// - 拉：任一 API 请求返回 `X-User-Status` / `X-Maintenance` 头时由
///       [ColibriApi] 回调本处理器，兜底杀后台/断网用户。
///
/// 封禁/维护页均为全屏阻断页（不可返回），服务端解除后自动恢复主流程。
class AppCommandHandler {
  static final shared = AppCommandHandler();

  bool _registered = false;
  bool _inBlocked = false;
  bool _inMaintenance = false;
  bool _inForceUpdate = false;

  /// 在 App 启动时调用一次：注册 Reverb 监听 + 挂载 API 拉取兜底回调。
  /// 也可在重登/主界面重建后再次调用 —— WS 指令监听会安全重挂载。
  void register() {
    // WS 指令监听每次都重新挂载：ReverbService.disconnect() 会清空事件表
    // （登出/401 场景），若只依赖 _registered 守卫，重登后封禁/维护等
    // 指令将永久失聪（表现为不实时同步，只能重启 App）。off+on 幂等。
    ReverbService.shared.off(ReverbService.eventCommand, _onCommand);
    ReverbService.shared.on(ReverbService.eventCommand, _onCommand);

    if (_registered) return;
    _registered = true;

    // 拉兜底：API 层识别到封禁/维护/强制更新响应头时触发
    ColibriApi.onUserStatusBlocked =
        (status, reason) => enterBlocked(status, reason);
    ColibriApi.onMaintenance =
        (message, until) => enterMaintenance(message, until: until);
    ColibriApi.onRequireUpdate = (info) => enterForceUpdate(info);
  }

  void _onCommand(dynamic payload) {
    final map = _parsePayload(payload);
    if (map == null) return;

    final action = map['action']?.toString() ?? '';
    switch (action) {
      case 'blocked':
      case 'banned': // 兼容：个别后端版本以 banned 广播封禁
      case 'suspended':
        enterBlocked(action, map['reason']?.toString());
        break;
      case 'active':
        leaveBlocked();
        break;
      case 'maintenance_on':
        enterMaintenance(map['message']?.toString(),
            until: map['until']?.toString());
        break;
      case 'maintenance_off':
        leaveMaintenance();
        break;
    }
  }

  Map<String, dynamic>? _parsePayload(dynamic payload) {
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    if (payload is String) {
      try {
        final d = jsonDecode(payload);
        if (d is Map) return Map<String, dynamic>.from(d);
      } catch (_) {}
    }
    return null;
  }

  void enterBlocked(String status, String? reason) {
    if (_inBlocked) return;
    _inBlocked = true;
    _inMaintenance = false;
    // 保持 Reverb 连接：token 未被服务端删除（封禁由 user.status 中间件
    // 403 拦截），私有频道仍有效，需继续监听 main.command(active) 实时解封。
    Get.offAll(() => ColibriBlockedScreen(status: status, reason: reason));
  }

  void leaveBlocked() {
    if (!_inBlocked) return;
    _inBlocked = false;
    _restoreMainFlow();
  }

  /// 封禁页手动「退出登录」时调用：复位封禁状态（会话清理由页面负责）。
  void resetBlocked() => _inBlocked = false;

  void enterMaintenance(String? message, {String? until}) {
    if (_inMaintenance) return;
    _inMaintenance = true;
    // 维护期间保持连接，以接收 maintenance_off 恢复指令
    Get.offAll(() => ColibriMaintenanceScreen(message: message, until: until));
  }

  void leaveMaintenance() {
    if (!_inMaintenance) return;
    _inMaintenance = false;
    _restoreMainFlow();
  }

  /// 维护页「检查恢复状态」确认服务已恢复后调用：复位维护状态并回主流程。
  ///
  /// 维护页必须经由本方法恢复 —— 若页面自行 Get.offAll 跳回主界面，
  /// [_inMaintenance] 会一直卡在 true，之后任何 503 兜底再也无法拉起维护页
  /// （表现为：错误进入 App 后下拉刷新失效，只能重启 App）。
  void restoreFromMaintenance() {
    _inMaintenance = false;
    _restoreMainFlow();
  }

  /// 危险版本下线：服务端 426 强制更新（运行中的旧版本每次请求被拦截）。
  /// 使用后端返回的最新版本信息进入全屏强制更新页。
  void enterForceUpdate(Map<String, dynamic> info) {
    if (_inForceUpdate) return;
    _inForceUpdate = true;

    final version = ColibriVersionInfo(
      code: info['latest']?.toString() ?? '',
      platform: Platform.isIOS ? 'ios' : 'android',
      downloadUrl: info['download_url']?.toString() ?? '',
      notes: info['notes']?.toString(),
      forced: true,
      releasedAt: null,
    );

    Get.offAll(() => ForcedUpdateScreen(version: version));
  }

  /// 恢复主流程（登录态回主界面，未登录回登录页）。
  void _restoreMainFlow() {
    final loggedIn = SessionManager.shared.isLogin() &&
        (SessionManager.shared.getToken()?.isNotEmpty ?? false);
    Get.offAll(
        () => loggedIn ? const ColibriHomeScreen() : const LoginScreen());
  }
}

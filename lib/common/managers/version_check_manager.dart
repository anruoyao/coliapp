import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:untitled/common/api_service/colibri_version_service.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
import 'package:untitled/screens/update_screen/app_update_dialog.dart';
import 'package:untitled/screens/update_screen/forced_update_screen.dart';
import 'package:url_launcher/url_launcher.dart';

/// App 启动版本检测管理器。
///
/// 设计决策（安全优先）：
/// - 每次冷启动都向后端检测一次，**不做长时间节流**。版本检测接口只查
///   一张小表、成本极低；而一旦后端发布「强制更新」，客户端必须能及时
///   拦截，任何节流都会造成危险版本被继续使用的窗口期。
/// - 非强制更新的打扰由两个轻量记忆控制：
///   * 「忽略此版本」：跨会话持久（GetStorage），同一版本不再提示；
///     后端发布新版本代号后自动重新提示。
///   * 「下次再说」：仅本次会话不再提示，下次启动仍会检测。
/// - 强制更新：不受「忽略 / 下次再说」影响，直接进入全屏阻断页且不可返回。
class VersionCheckManager {
  static final shared = VersionCheckManager();

  static const String _kIgnoredKey = 'app_version_ignored';

  final GetStorage _storage = GetStorage();

  /// 本会话内是否已经展示过非强制更新弹窗（「下次再说」依据）。
  bool _sessionPrompted = false;

  /// 是否已在强制更新页（防止重复压栈）。
  bool _showingForcedScreen = false;

  /// 启动时检测版本：有更新则按规则弹窗/跳转；失败静默不打扰。
  Future<void> checkAndShow() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final platform = Platform.isIOS ? 'ios' : 'android';
      final currentCode = packageInfo.version.trim();
      if (currentCode.isEmpty) return;

      final result = await ColibriVersionService.shared.checkUpdate(
        platform: platform,
        currentCode: currentCode,
      );

      if (!result.hasUpdate || result.latest == null) return;

      final latest = result.latest!;

      // 用户已忽略该版本（后端发布新版本代号后才会再次提示）；
      // 强制更新不受忽略影响，保证重大漏洞时仍能强制拦截。
      final ignored = _storage.read(_kIgnoredKey)?.toString();
      if (ignored == latest.code && !result.forced) return;

      if (result.forced) {
        // 强制更新：全屏阻断页，不可忽略、不可返回
        if (_showingForcedScreen) return;
        _showingForcedScreen = true;
        await Get.to(() => ForcedUpdateScreen(version: latest), opaque: false);
        _showingForcedScreen = false;
        return;
      }

      // 非强制：本次会话只提示一次（「下次再说」后不再弹）
      if (_sessionPrompted) return;
      _sessionPrompted = true;

      final context = Get.context;
      if (context == null) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        barrierColor: Colors.black.withValues(alpha: 0.55),
        builder: (_) => AppUpdateDialog(
          version: latest,
          onLater: () => Get.back(),
          onIgnore: () {
            _storage.write(_kIgnoredKey, latest.code);
            Get.back();
          },
          onUpdate: () => _launchDownload(latest),
        ),
      );
    } catch (_) {
      // 检测失败（网络/接口异常等）静默处理，不打断用户启动流程
    }
  }

  /// 打开下载链接（跳转系统浏览器 / 应用商店）。
  Future<void> _launchDownload(ColibriVersionInfo version) async {
    final url = version.downloadUrl.trim();
    if (url.isEmpty) {
      showColibriToast('更新失败', message: '当前版本缺少下载链接，请稍后再试');
      return;
    }
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      showColibriToast('更新失败', message: '无法打开下载链接，请手动访问');
    }
  }
}

import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_api.dart';
import 'package:untitled/common/api_service/colibri_guest_service.dart';
import 'package:untitled/common/managers/logger.dart';

/// 访客会话（全局唯一，permanent）。
///
/// 职责：
/// - 启动阶段（未登录）调用访客 bootstrap 检测后台总开关，决定分流
///   （开关开 → 访客可进主界面浏览；关/网络异常 → 登录页，维持旧行为）；
/// - 持有访客能力矩阵/可见导航，作为「当前是否访客态」的唯一判断来源；
/// - 登录/登出时切换状态，配合 Get.offAll 重建主界面。
///
/// 与 [SessionManager] 的关系：是否登录仍以 token + isLogin 为准；
/// [active] 仅表示「未登录且访客开关开启，正在以访客身份浏览」。
class GuestSession extends GetxController {
  static GuestSession get i => Get.find<GuestSession>();

  /// 后台访客总开关（最近一次 bootstrap 结果）。
  final RxBool guestEnabled = false.obs;

  /// 当前正处于访客浏览态（未登录 + 开关开启）。
  final RxBool active = false.obs;

  /// 访客能力矩阵（guest.capabilities）。
  final RxMap<String, dynamic> capabilities = <String, dynamic>{}.obs;

  /// 访客可见导航（guest.visible_nav）。
  final RxList<String> visibleNav = <String>[].obs;

  /// 平台信息（访客页展示/欢迎语使用）。
  String platformVersion = '';
  String platformName = '';

  bool get isGuest => active.value;

  /// 启动分流：仅在未登录时调用。
  ///
  /// 返回 true  = 访客功能可用，应进入主界面（访客浏览态）；
  /// 返回 false = 开关关闭/请求被拒/网络异常，应去登录页（保守策略，旧行为不回归）。
  Future<bool> detectForUnauthenticated() async {
    final stopwatch = Stopwatch()..start();
    Loggers.info('startup.guest.bootstrap.request.start');
    try {
      final boot = await ColibriGuestService.shared
          .fetchBootstrap()
          .timeout(const Duration(seconds: 8));
      Loggers.info(
          'startup.guest.bootstrap.request.done ${stopwatch.elapsedMilliseconds}ms enabled=${boot.enabled}');
      guestEnabled.value = boot.enabled;
      capabilities.assignAll(boot.capabilities);
      visibleNav.assignAll(boot.visibleNav);
      platformVersion = boot.version;
      platformName = boot.name;
      active.value = boot.enabled;
      return boot.enabled;
    } on ColibriApiException catch (e) {
      Loggers.warning(
          'startup.guest.bootstrap.request.error status=${e.statusCode} message=${e.message} after=${stopwatch.elapsedMilliseconds}ms');
      // 403 = 开关关闭；其余（网络错误等）同样保守回落到登录页
      if (e.statusCode == 403) guestEnabled.value = false;
      active.value = false;
      return false;
    } catch (error, stackTrace) {
      Loggers.error(
          'startup.guest.bootstrap.unexpected $error after=${stopwatch.elapsedMilliseconds}ms\\n$stackTrace');
      active.value = false;
      return false;
    }
  }

  /// 登录/注册成功：退出访客态（主界面随后以登录态重建）。
  void markLoggedIn() {
    active.value = false;
  }
}

import 'package:flutter/material.dart';
import 'package:untitled/common/api_service/colibri_api.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/managers/app_command_handler.dart';
import 'package:untitled/utilities/const.dart';

/// 全局维护（应急）模式页（全屏阻断）。
///
/// 由两种方式进入：
/// 1. 推：后端开启维护 → Reverb 公共频道 `main.command(maintenance_on)` 全员广播；
/// 2. 拉：任一 API 请求返回 `X-Maintenance` 头（503）时兜底。
///
/// 「检查恢复状态」探测非白名单的公共接口（auth/config）：它真实经过
/// CheckMaintenance 中间件 —— 维护中 503，解除后 200，恢复判定不会被绕过。
class ColibriMaintenanceScreen extends StatefulWidget {
  final String? message;
  final String? until;

  const ColibriMaintenanceScreen({super.key, this.message, this.until});

  @override
  State<ColibriMaintenanceScreen> createState() =>
      _ColibriMaintenanceScreenState();
}

class _ColibriMaintenanceScreenState extends State<ColibriMaintenanceScreen> {
  bool _checking = false;

  /// 检查结果提示（服务端/网络异常、维护仍在进行等）。
  String? _status;

  /// 公告与预计恢复时间（检查后可被服务端最新值刷新）。
  late String? _message = widget.message;
  late String? _until = widget.until;

  String get _notice => (_message != null && _message!.trim().isNotEmpty)
      ? _message!.trim()
      : '系统正在维护中，请稍后再试。感谢您的耐心等待。';

  /// 预计恢复时间展示文案：ISO8601 → 本地时区 yyyy-MM-dd HH:mm。
  String? get _untilText {
    final raw = _until?.trim();
    if (raw == null || raw.isEmpty) return null;
    final d = DateTime.tryParse(raw)?.toLocal();
    if (d == null) return raw; // 非标准格式原样展示
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  Future<void> _retry() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _status = null;
    });
    try {
      // 恢复判定以「真实经过 CheckMaintenance 中间件的公共接口」为准：
      // auth/config 不在维护白名单内 —— 维护中返回 503 + X-Maintenance，
      // 解除后返回 200。白名单接口（version/check）维护中也返回 200，
      // 不能单独作为恢复依据，否则维护未解除也会被放行进 App。
      await ColibriApi.shared.get('auth/config', auth: false);
      if (!mounted) return;
      // 200 = 中间件放行 = 维护已解除。必须经 AppCommandHandler 复位
      // 维护状态，否则 _inMaintenance 卡死后 503 兜底再也无法拉起维护页。
      AppCommandHandler.shared.restoreFromMaintenance();
    } on ColibriApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 503) {
        // 维护未解除：同步最新公告/预计恢复时间，留在本页
        setState(() {
          _message = e.message;
          _until = e.data?['until']?.toString();
          _status = '维护仍在进行中，请稍后再试';
        });
      } else {
        setState(() => _status = '检查失败（HTTP ${e.statusCode ?? '-'}），请稍后重试');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = '网络异常，请检查网络后重试');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: cBlack,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.6, end: 1),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutBack,
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF3B3B45), Color(0xFF232329)],
                          ),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Icon(
                          Icons.construction_rounded,
                          color: cPrimary,
                          size: 56,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      '系统维护中',
                      textAlign: TextAlign.center,
                      style: MyTextStyle.gilroyExtraBold(
                          size: 24, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _notice,
                      textAlign: TextAlign.center,
                      style:
                          MyTextStyle.gilroyRegular(size: 15, color: cLightText)
                              .copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 18),
                    if (_untilText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.07)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 16, color: cPrimary),
                            const SizedBox(width: 6),
                            Text(
                              '预计恢复：$_untilText',
                              style: MyTextStyle.gilroyBold(
                                  size: 13, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _checking ? null : _retry,
                        style: FilledButton.styleFrom(
                          backgroundColor: cPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          disabledBackgroundColor:
                              cPrimary.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _checking
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text('检查恢复状态',
                                style: MyTextStyle.gilroyBold(
                                    size: 16, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_status != null) ...[
                      Text(
                        _status!,
                        textAlign: TextAlign.center,
                        style: MyTextStyle.gilroyRegular(size: 13, color: cRed),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Text(
                      '服务恢复后即可正常使用',
                      style: MyTextStyle.gilroyRegular(
                          size: 12, color: cLightText),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:untitled/common/api_service/colibri_version_service.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/utilities/const.dart';
import 'package:url_launcher/url_launcher.dart';

/// 强制更新页（全屏阻断）。
///
/// 用于后端标记强制更新的场景：不可返回、不可忽略，
/// 用户只能完成更新（跳转下载）才能继续使用应用。
class ForcedUpdateScreen extends StatelessWidget {
  final ColibriVersionInfo version;

  const ForcedUpdateScreen({super.key, required this.version});

  List<String> get _noteLines {
    final notes = version.notes ?? '';
    return notes
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _update(BuildContext context) async {
    final url = version.downloadUrl.trim();
    if (url.isEmpty) {
      showColibriToast('更新地址缺失，请稍后再试',
          context: context, status: ColibriToastStatus.error);
      return;
    }
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      showColibriToast('无法打开下载链接，请手动访问',
          context: context, status: ColibriToastStatus.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = _noteLines;

    return PopScope(
      canPop: false, // 强制更新期间禁止任何方式返回
      child: Scaffold(
        backgroundColor: cBlack,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 顶部渐变图标区
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.6, end: 1),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutBack,
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF40E378),
                              Color(0xFF0F9D49),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x5537D96D),
                              blurRadius: 40,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.system_update_alt_rounded,
                            color: Colors.white,
                            size: 56,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 34),

                    Text(
                      '需要更新才能继续使用',
                      textAlign: TextAlign.center,
                      style: MyTextStyle.gilroyExtraBold(
                          size: 24, color: Colors.white),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      '此版本已停止支持，请升级到 v${version.code} 以获得最新功能与安全修复。',
                      textAlign: TextAlign.center,
                      style:
                          MyTextStyle.gilroyRegular(size: 15, color: cLightText)
                              .copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 28),

                    // 更新公告面板
                    if (lines.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.07)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.auto_awesome_rounded,
                                    size: 15, color: cPrimary),
                                const SizedBox(width: 6),
                                Text('本次更新内容',
                                    style: MyTextStyle.gilroyBold(
                                        size: 13, color: cDarkText)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...lines.map(
                              (line) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 7),
                                      child: Container(
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: cPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        line,
                                        style: MyTextStyle.gilroyRegular(
                                                size: 13.5, color: cMainText)
                                            .copyWith(height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 34),

                    // 立即更新（唯一动作）
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: () => _update(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: cPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text('立即更新',
                            style: MyTextStyle.gilroyBold(
                                size: 17, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text(
                      '更新完成后即可正常使用',
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

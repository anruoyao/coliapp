import 'package:flutter/material.dart';
import 'package:untitled/common/api_service/colibri_version_service.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/utilities/const.dart';

/// 非强制更新弹窗。
///
/// 白色卡片 + 编辑式左对齐排版：标题 + NEW 徽标、版本说明、更新日志面板，
/// 品牌绿主按钮（黑字）与弱化的次级操作，延续访客「我的」页白卡设计语言。
/// 弹窗不可通过点击遮罩关闭，用户必须做出明确选择，避免误触。
class AppUpdateDialog extends StatelessWidget {
  final ColibriVersionInfo version;
  final VoidCallback onUpdate;
  final VoidCallback onLater;
  final VoidCallback onIgnore;

  const AppUpdateDialog({
    super.key,
    required this.version,
    required this.onUpdate,
    required this.onLater,
    required this.onIgnore,
  });

  List<String> get _noteLines {
    final notes = version.notes ?? '';
    return notes
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final lines = _noteLines;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Center(
        child: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 12),
          decoration: BoxDecoration(
            color: cWhite,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题行：标题 + NEW 徽标
                Row(
                  children: [
                    Text('发现新版本',
                        style: MyTextStyle.gilroyExtraBold(
                            size: 22, color: cMainText)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: cPrimarySoft,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text('NEW',
                          style:
                              MyTextStyle.gilroyBold(size: 11, color: cGreen)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('新版本 v${version.code} 已发布，更新后体验更佳。',
                    style: MyTextStyle.gilroyRegular(
                        size: 13.5, color: cLightText)),
                const SizedBox(height: 18),

                // 更新日志面板
                if (lines.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    decoration: BoxDecoration(
                      color: cBG,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('更新内容',
                            style: MyTextStyle.gilroySemiBold(
                                size: 12, color: cLightText)),
                        const SizedBox(height: 10),
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
                                      color: cGreen,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    line,
                                    style: MyTextStyle.gilroyRegular(
                                        size: 13.5, color: cMainText),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                ] else
                  const SizedBox(height: 24),

                // 立即更新（主按钮：品牌绿 + 黑字，与访客「我的」页按钮语言一致）
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: onUpdate,
                    style: FilledButton.styleFrom(
                      backgroundColor: cPrimary,
                      foregroundColor: cBlack,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text('立即更新',
                        style: MyTextStyle.gilroyBold(size: 16, color: cBlack)),
                  ),
                ),

                // 次级操作：下次再说 / 忽略此版本（同排弱化，避免按钮堆叠）
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: onLater,
                      style: TextButton.styleFrom(
                        foregroundColor: cLightText,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: Text('下次再说',
                          style: MyTextStyle.gilroyMedium(
                              size: 13.5, color: cLightText)),
                    ),
                    Container(
                      width: 3,
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: cLightIcon,
                      ),
                    ),
                    TextButton(
                      onPressed: onIgnore,
                      style: TextButton.styleFrom(
                        foregroundColor: cLightText,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: Text('忽略此版本',
                          style: MyTextStyle.gilroyMedium(
                              size: 13.5, color: cLightText)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

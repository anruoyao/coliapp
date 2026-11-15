import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/utilities/const.dart';

/// 全局页面转场：淡入叠加轻微放大，保持上一页作为过渡背景。
class ColibriPageTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.82, end: 1).animate(curved),
        child: child,
      ),
    );
  }
}

/// Colibri UI 设计语言共享组件库：
/// - [showColibriSheet]  统一底部弹层（拖动把手 + 标题 + 图标 chip 菜单项）
/// - [ColibriSheetItem]   弹层菜单项数据
/// - [ColibriEmptyState]  统一空状态（软绿圆底图标 + 标题 + 副标题）
/// - [ColibriCapsuleTabs] 胶囊分段 tab（绿色胶囊选中态，无 TabController 依赖）
/// - [ColibriIconChip]    软底色圆角图标 chip（菜单/设置行通用）
/// - [ColibriPillButton]  胶囊按钮（关注/私信/主操作）
/// - [ColibriSectionLabel] 分组小标题
/// - [showColibriConfirmDialog] 统一系统风格确认弹窗

/// 以扩张动画打开设置详情页，保持设置入口与详情页的视觉连续性。
Future<void> openColibriSettingPage(BuildContext context, Widget page) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 360),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, animation, secondaryAnimation) => page,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.82, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

/// 弹层菜单项。
class ColibriSheetItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;
  final String? subtitle;

  const ColibriSheetItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.danger = false,
    this.subtitle,
  });
}

/// 通用液态玻璃底部弹层：拖动把手、可选标题与菜单项列表。
/// 点击任意项：先关闭弹层，再执行 onTap。
Future<void> showColibriSheet(
  BuildContext context, {
  String? title,
  List<ColibriSheetItem> items = const [],
}) async {
  final selected = await showColibriBottomSheet<int>(
    RepaintBoundary(child: _ColibriSheet(title: title, items: items)),
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: cBlack.withValues(alpha: 0.24),
    useSafeArea: true,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: math.min(680, MediaQuery.of(context).size.height * 0.82),
    ),
  );
  if (selected != null && selected >= 0 && selected < items.length) {
    items[selected].onTap?.call();
  }
}

class _ColibriSheet extends StatelessWidget {
  final String? title;
  final List<ColibriSheetItem> items;

  const _ColibriSheet({this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return ColibriSheetSurface(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ColibriSheetHeader(
            title: title,
            trailing: const ColibriSheetCloseButton(),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ColibriSheetActionRow(
                  title: item.label,
                  subtitle: item.subtitle,
                  icon: item.icon,
                  destructive: item.danger,
                  showDivider: index < items.length - 1,
                  onTap: () => Navigator.of(context).pop(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 软底色圆角图标 chip：常规绿系、危险红系。
class ColibriIconChip extends StatelessWidget {
  final IconData icon;
  final bool danger;
  final double size;
  final double iconSize;

  const ColibriIconChip({
    super.key,
    required this.icon,
    this.danger = false,
    this.size = 38,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        color: danger ? cRed.withValues(alpha: 0.10) : cPrimarySoft,
      ),
      child: Icon(icon, size: iconSize, color: danger ? cRed : cGreen),
    );
  }
}

/// 统一空状态：软绿圆底图标 + 标题 + 副标题 + 可选操作按钮。
class ColibriEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final double topSpacing;

  const ColibriEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.topSpacing = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          SizedBox(height: topSpacing),
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
                color: cPrimarySoft, shape: BoxShape.circle),
            child: Icon(icon, size: 40, color: cGreen),
          ),
          const SizedBox(height: 18),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: cMainText)),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13.5, color: cLightText, height: 1.4)),
          ],
          if (action != null) ...[
            const SizedBox(height: 22),
            action!,
          ],
        ],
      ),
    );
  }
}

/// 胶囊分段 tab：选中项绿色软底胶囊 + 深绿加粗文字。
class ColibriCapsuleTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const ColibriCapsuleTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: cWhite,
        border: Border(bottom: BorderSide(color: cLightBg, width: 1)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: Container(
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: i == selectedIndex
                        ? cPrimary.withValues(alpha: 0.16)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: i == selectedIndex
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: i == selectedIndex ? cGreen : cLightText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 胶囊按钮：filled 绿底黑字 / 描边白底。
/// [minWidth] 保证「关注/已关注」等长短切换时按钮宽度稳定不跳动。
class ColibriPillButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool filled;
  final IconData? icon;
  final double height;
  final double radius;
  final double? minWidth;

  const ColibriPillButton({
    super.key,
    required this.text,
    this.onTap,
    this.filled = false,
    this.icon,
    this.height = 44,
    this.radius = 14,
    this.minWidth,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    return Material(
      color: filled ? cPrimary : cWhite,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Container(
          height: height,
          constraints:
              minWidth != null ? BoxConstraints(minWidth: minWidth!) : null,
          padding: minWidth == null
              ? null
              : const EdgeInsets.symmetric(horizontal: 10),
          decoration: filled
              ? null
              : BoxDecoration(
                  borderRadius: borderRadius,
                  border: Border.all(color: cLightBg, width: 1.2)),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 17, color: filled ? cWhite : cMainText),
                  const SizedBox(width: 6),
                ],
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: filled ? cWhite : cMainText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 分组小标题。
class ColibriSectionLabel extends StatelessWidget {
  final String text;

  const ColibriSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: cLightText,
            letterSpacing: 0.3),
      ),
    );
  }
}

// ===================== 确认弹窗 =====================

/// 统一系统风格确认弹窗，异步确认期间显示进度状态。
///
/// 返回 `true` 表示用户确认且 [onConfirm] 执行成功；取消、关闭或确认失败时返回 `false`。
/// [onConfirm] 为空时，点击确认立即返回 `true`。
Future<bool> showColibriConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required IconData icon,
  String? confirmText,
  String? cancelText,
  bool danger = true,
  Future<bool> Function()? onConfirm,
}) {
  final resolvedConfirmText = confirmText ?? LKeys.commonConfirm.tr;
  final resolvedCancelText = cancelText ?? LKeys.commonCancel.tr;
  var busy = false;
  return showDialog<bool>(
    context: context,
    barrierColor: cBlack.withValues(alpha: 0.28),
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xE62C2C2E)
                    : const Color(0xEFFFFFFF),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 0.72),
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon,
                            size: 21,
                            color: danger
                                ? const Color(0xFFFF3B30)
                                : Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: const Size(64, 44),
                            foregroundColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: busy
                              ? null
                              : () => Navigator.of(dialogContext).pop(false),
                          child: Text(resolvedCancelText),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: const Size(64, 44),
                            foregroundColor: danger
                                ? const Color(0xFFFF3B30)
                                : Theme.of(context).colorScheme.primary,
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onPressed: busy
                              ? null
                              : () async {
                                  if (onConfirm == null) {
                                    Navigator.of(dialogContext).pop(true);
                                    return;
                                  }
                                  setDialogState(() => busy = true);
                                  try {
                                    final ok = await onConfirm();
                                    if (!dialogContext.mounted) return;
                                    if (ok) {
                                      Navigator.of(dialogContext).pop(true);
                                    } else {
                                      setDialogState(() => busy = false);
                                    }
                                  } catch (_) {
                                    if (dialogContext.mounted) {
                                      setDialogState(() => busy = false);
                                    }
                                  }
                                },
                          child: busy
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: danger
                                        ? const Color(0xFFFF3B30)
                                        : Theme.of(context).colorScheme.primary,
                                  ),
                                )
                              : Text(resolvedConfirmText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  ).then((value) => value == true);
}

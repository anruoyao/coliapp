import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
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
/// - [showColibriConfirmDialog] 统一确认弹窗（磨砂遮罩 + 弹性缩放入场 + loading 态确认按钮）

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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: cBlack.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xF7FFFFFF),
            border: Border.all(color: const Color(0x33FFFFFF), width: 0.8),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 12, top: 8),
                  child: SizedBox(
                    height: 42,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            tooltip: '关闭',
                            onPressed: () => Navigator.of(context).pop(),
                            icon:
                                const Icon(Icons.close_rounded, color: cBlack),
                            style: IconButton.styleFrom(
                              backgroundColor: cWhite,
                              foregroundColor: cBlack,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(42, 42),
                              shape: const CircleBorder(),
                            ),
                          ),
                        ),
                        if (title != null)
                          Text(
                            title!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: cMainText,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cLightIcon.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 10),
                    children: [
                      for (var index = 0; index < items.length; index++)
                        _ColibriSheetItemRow(
                          item: items[index],
                          index: index,
                        ),
                    ],
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

class _ColibriSheetItemRow extends StatelessWidget {
  final ColibriSheetItem item;
  final int index;

  const _ColibriSheetItemRow({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        child: Row(
          children: [
            ColibriIconChip(icon: item.icon, danger: item.danger),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: item.danger ? cRed : cMainText,
                    ),
                  ),
                  if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(item.subtitle!,
                        style:
                            const TextStyle(fontSize: 12, color: cLightText)),
                  ],
                ],
              ),
            ),
          ],
        ),
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

/// 统一确认弹窗：磨砂遮罩 + 白色圆角卡片 + 弹性缩放入场 + 确认按钮 loading 态。
///
/// 返回 `true` 表示用户已确认且 [onConfirm] 执行成功（弹窗已关闭）；
/// `false` 表示用户取消、点遮罩关闭或 [onConfirm] 返回 false（失败时弹窗保留，调用方自行提示）。
///
/// - [danger] 为 true 时确认按钮与图标使用红色系（删除/举报等破坏性操作），
///   false 时使用品牌绿（常规确认）。
/// - [onConfirm] 为空则点击确认立即关闭返回 true。
Future<bool> showColibriConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required IconData icon,
  String confirmText = '确认',
  String cancelText = '取消',
  bool danger = true,
  Future<bool> Function()? onConfirm,
}) {
  return showColibriBottomSheet<bool>(
    Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: _ColibriConfirmDialog(
        title: title,
        message: message,
        icon: icon,
        confirmText: confirmText,
        cancelText: cancelText,
        danger: danger,
        onConfirm: onConfirm,
      ),
    ),
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.36),
    useSafeArea: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 420, maxHeight: 420),
  ).then((value) => value == true);
}

class _ColibriConfirmDialog extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final String confirmText;
  final String cancelText;
  final bool danger;
  final Future<bool> Function()? onConfirm;

  const _ColibriConfirmDialog({
    required this.title,
    required this.message,
    required this.icon,
    required this.confirmText,
    required this.cancelText,
    required this.danger,
    this.onConfirm,
  });

  @override
  State<_ColibriConfirmDialog> createState() => _ColibriConfirmDialogState();
}

class _ColibriConfirmDialogState extends State<_ColibriConfirmDialog> {
  bool _busy = false;

  Future<void> _onConfirm() async {
    if (_busy) return;
    if (widget.onConfirm == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _busy = true);
    final ok = await widget.onConfirm!();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      // 失败：保留弹窗，调用方已自行提示错误
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.danger ? cRed : cGreen;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: cBlack.withValues(alpha: 0.16),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: LiquidGlassLens(
          style: const LiquidGlassStyle(
            shape: LiquidGlassShape.continuousRoundedRectangle(
              cornerRadius: 26,
              clipQuality: LiquidGlassClipQuality.exact,
              borderWidth: 0.8,
              lightIntensity: 1,
              lightDirection: 45,
              borderType: OpticalBorder(
                borderSaturation: 1.1,
                ambientIntensity: 0.9,
                borderSolidity: 0.75,
              ),
            ),
            appearance: LiquidGlassAppearance(
              color: Color(0xF7FFFFFF),
              blur: LiquidGlassBlur(sigmaX: 2, sigmaY: 2),
            ),
            refraction: LiquidGlassRefraction(
              distortion: 0.07,
              distortionWidth: 16,
              chromaticAberration: 0.0005,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 图标：软底圆形 + 细描边环
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: accent.withValues(alpha: 0.22), width: 1.5),
                  ),
                  child: Icon(widget.icon, size: 27, color: accent),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: cMainText,
                      height: 1.3),
                ),
                const SizedBox(height: 7),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13.5, color: cLightText, height: 1.55),
                ),
                const SizedBox(height: 22),
                // 按钮行
                Row(
                  children: [
                    Expanded(
                      child: _ConfirmButton(
                        text: widget.cancelText,
                        onTap: _busy
                            ? null
                            : () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: _ConfirmButton(
                        text: widget.confirmText,
                        filled: true,
                        accent: accent,
                        loading: _busy,
                        onTap: _onConfirm,
                      ),
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

/// 弹窗按钮：灰色软底（取消）/ 彩色实底（确认，danger 红字白 / 常规绿底黑字）。
class _ConfirmButton extends StatelessWidget {
  final String text;
  final bool filled;
  final Color? accent; // filled 时的底色
  final bool loading;
  final VoidCallback? onTap;

  const _ConfirmButton({
    required this.text,
    this.filled = false,
    this.accent,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRed = accent == cRed;
    final borderRadius = BorderRadius.circular(23);
    return Material(
      color: filled ? accent : cLightBg,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: SizedBox(
          height: 46,
          child: Center(
            child: loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: isRed ? Colors.white : cBlack,
                    ),
                  )
                : Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color:
                          filled ? (isRed ? Colors.white : cBlack) : cMainText,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

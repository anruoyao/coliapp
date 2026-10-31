import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:untitled/utilities/const.dart';

enum ColibriToastStatus { info, error, success }

OverlayEntry? _activeToast;

/// Shows a short, root-overlay toast capsule near the bottom of the screen.
///
/// A second call replaces the currently visible capsule. [message] is shown
/// below [title] when present. The legacy color parameters are accepted so
/// existing callers can migrate without losing their original status mapping.
void showColibriToast(
  String title, {
  String? message,
  BuildContext? context,
  ColibriToastStatus status = ColibriToastStatus.info,
  IconData? icon,
  Color? backgroundColor,
  Color? colorText,
  Duration duration = const Duration(milliseconds: 2500),
}) {
  final resolvedStatus = backgroundColor == cRed
      ? ColibriToastStatus.error
      : backgroundColor == cGreen
          ? ColibriToastStatus.success
          : status;
  final overlay = context != null
      ? Overlay.maybeOf(context, rootOverlay: true)
      : Get.key.currentState?.overlay;
  if (overlay == null) return;

  final previous = _activeToast;
  _activeToast = null;
  if (previous != null && previous.mounted) previous.remove();

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ColibriToast(
      title: title,
      message: message,
      status: resolvedStatus,
      icon: icon,
      duration: duration,
      onDismiss: () {
        if (entry.mounted) entry.remove();
        if (identical(_activeToast, entry)) _activeToast = null;
      },
    ),
  );
  _activeToast = entry;
  overlay.insert(entry);
}

/// Compatibility API for bookmark actions.
void showColibriBookmarkToast(BuildContext context,
    {required bool bookmarked}) {
  showColibriToast(
    bookmarked ? '已添加到收藏' : '已取消收藏',
    context: context,
    icon: bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
    duration: const Duration(milliseconds: 2100),
    status: bookmarked ? ColibriToastStatus.success : ColibriToastStatus.info,
  );
}

class _ColibriToast extends StatefulWidget {
  final String title;
  final String? message;
  final ColibriToastStatus status;
  final IconData? icon;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ColibriToast({
    required this.title,
    required this.message,
    required this.status,
    required this.icon,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ColibriToast> createState() => _ColibriToastState();
}

class _ColibriToastState extends State<_ColibriToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380));
  late final CurvedAnimation _curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic);
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_closing || !mounted) return;
    _closing = true;
    _timer?.cancel();
    try {
      await _controller.reverse().orCancel;
    } on TickerCanceled {
      // The overlay is being disposed.
    }
    widget.onDismiss();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _closing = true;
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  Color get _accent => switch (widget.status) {
        ColibriToastStatus.success => cGreen,
        ColibriToastStatus.error => cRed,
        ColibriToastStatus.info => cPrimary,
      };

  IconData get _icon =>
      widget.icon ??
      switch (widget.status) {
        ColibriToastStatus.success => Icons.check_circle_rounded,
        ColibriToastStatus.error => Icons.error_rounded,
        ColibriToastStatus.info => Icons.info_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 84,
      child: IgnorePointer(
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 1.4), end: Offset.zero)
              .animate(_curve),
          child: FadeTransition(
            opacity: CurvedAnimation(
                parent: _controller,
                curve: const Interval(0, 0.55, curve: Curves.easeOut)),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                          color: cBlack.withValues(alpha: 0.16),
                          blurRadius: 24,
                          offset: const Offset(0, 8)),
                      BoxShadow(
                          color: cBlack.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: LiquidGlassLens(
                    style: const LiquidGlassStyle(
                      shape: LiquidGlassShape.squircle(
                        cornerRadius: 30,
                        clipQuality: LiquidGlassClipQuality.exact,
                      ),
                      appearance:
                          LiquidGlassAppearance(color: Color(0xD9FFFFFF)),
                      refraction: LiquidGlassRefraction(
                        distortion: 0.08,
                        distortionWidth: 20,
                        chromaticAberration: 0.0015,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                                color: _accent, shape: BoxShape.circle),
                            child: Icon(_icon, size: 18, color: cWhite),
                          ),
                          const SizedBox(width: 11),
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.title,
                                    style: const TextStyle(
                                        color: cMainText,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600)),
                                if (widget.message != null &&
                                    widget.message!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(widget.message!,
                                      style: TextStyle(
                                          color:
                                              cDarkText.withValues(alpha: 0.82),
                                          fontSize: 12.5),
                                      softWrap: true),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

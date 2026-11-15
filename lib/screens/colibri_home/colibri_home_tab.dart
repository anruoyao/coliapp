import 'package:flutter/material.dart';

/// Keeps each tab mounted while only the selected tab receives input and focus.
class ColibriHomeTab extends StatefulWidget {
  final bool active;
  final double direction;
  final Widget child;

  const ColibriHomeTab({
    super.key,
    required this.active,
    required this.direction,
    required this.child,
  });

  @override
  State<ColibriHomeTab> createState() => _ColibriHomeTabState();
}

class _ColibriHomeTabState extends State<ColibriHomeTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1,
    duration: const Duration(milliseconds: 240),
  );
  late Tween<double> _opacity = Tween(
    begin: widget.active ? 1 : 0,
    end: widget.active ? 1 : 0,
  );
  Tween<double> _offset = Tween(begin: 0, end: 0);
  bool _reduceMotion = false;

  double get _progress => Curves.easeOutCubic.transform(_controller.value);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion && _controller.isAnimating) _controller.value = 1;
  }

  @override
  void didUpdateWidget(ColibriHomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active == widget.active) return;
    final opacity = _opacity.transform(_progress);
    final offset = _offset.transform(_progress);
    final direction = widget.direction *
        (Directionality.of(context) == TextDirection.rtl ? -1 : 1);
    _opacity = Tween(begin: opacity, end: widget.active ? 1 : 0);
    _offset = Tween(
      begin: widget.active && opacity == 0 ? direction * 12 : offset,
      end: widget.active ? 0 : -direction * 12,
    );
    _controller.duration = Duration(milliseconds: _reduceMotion ? 100 : 240);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: TickerMode(
        enabled: widget.active,
        child: RepaintBoundary(child: widget.child),
      ),
      builder: (context, child) {
        return Offstage(
          offstage: !widget.active && !_controller.isAnimating,
          child: IgnorePointer(
            ignoring: !widget.active,
            child: ExcludeSemantics(
              excluding: !widget.active,
              child: ExcludeFocus(
                excluding: !widget.active,
                child: Opacity(
                  opacity: _opacity.transform(_progress),
                  child: Transform.translate(
                    offset: Offset(
                      _reduceMotion ? 0 : _offset.transform(_progress),
                      0,
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:get/get.dart';
import 'package:untitled/utilities/const.dart';

/// A bottom sheet route with an eased entrance, drag resistance, and
/// one-third dismissal threshold.
Future<T?> showColibriBottomSheet<T>(
  Widget bottomSheet, {
  BuildContext? context,
  Color? backgroundColor,
  double? elevation,
  bool persistent = true,
  ShapeBorder? shape,
  Clip? clipBehavior,
  Color? barrierColor,
  bool? ignoreSafeArea,
  bool useSafeArea = false,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  RouteSettings? settings,
  Duration? enterBottomSheetDuration,
  Duration? exitBottomSheetDuration,
  BoxConstraints? constraints,
}) {
  return _pushColibriBottomSheet<T>(
    (_) => bottomSheet,
    context: context,
    backgroundColor: backgroundColor,
    elevation: elevation,
    persistent: persistent,
    shape: shape,
    clipBehavior: clipBehavior,
    barrierColor: barrierColor,
    ignoreSafeArea: ignoreSafeArea,
    useSafeArea: useSafeArea,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    settings: settings,
    enterBottomSheetDuration: enterBottomSheetDuration,
    exitBottomSheetDuration: exitBottomSheetDuration,
    constraints: constraints,
  );
}

Future<T?> showColibriBottomSheetBuilder<T>({
  required WidgetBuilder builder,
  BuildContext? context,
  Color? backgroundColor,
  double? elevation,
  bool persistent = true,
  ShapeBorder? shape,
  Clip? clipBehavior,
  Color? barrierColor,
  bool? ignoreSafeArea,
  bool useSafeArea = false,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  RouteSettings? settings,
  Duration? enterBottomSheetDuration,
  Duration? exitBottomSheetDuration,
  BoxConstraints? constraints,
}) {
  return _pushColibriBottomSheet<T>(
    builder,
    context: context,
    backgroundColor: backgroundColor,
    elevation: elevation,
    persistent: persistent,
    shape: shape,
    clipBehavior: clipBehavior,
    barrierColor: barrierColor,
    ignoreSafeArea: ignoreSafeArea,
    useSafeArea: useSafeArea,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    settings: settings,
    enterBottomSheetDuration: enterBottomSheetDuration,
    exitBottomSheetDuration: exitBottomSheetDuration,
    constraints: constraints,
  );
}

class ColibriSheetSurface extends StatelessWidget {
  const ColibriSheetSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 20),
    this.backgroundColor = cWhite,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class ColibriSheetHeader extends StatelessWidget {
  const ColibriSheetHeader({
    super.key,
    this.title,
    this.trailing,
    this.foregroundColor = const Color(0xFF1C1C1E),
    this.handleColor = const Color(0xFFD1D1D6),
  });

  final String? title;
  final Widget? trailing;
  final Color foregroundColor;
  final Color handleColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: handleColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        if (title != null || trailing != null) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      title!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: foregroundColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (trailing != null)
                  Align(alignment: Alignment.centerRight, child: trailing!),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class ColibriSheetCloseButton extends StatelessWidget {
  const ColibriSheetCloseButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).closeButtonTooltip,
      child: IconButton(
        tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
        onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.close_rounded, size: 19),
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFFF2F2F7),
          foregroundColor: const Color(0xFF3A3A3C),
          minimumSize: const Size(34, 34),
          maximumSize: const Size(34, 34),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class ColibriSheetActionRow extends StatelessWidget {
  const ColibriSheetActionRow({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.destructive = false,
    this.showDivider = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback onTap;
  final bool destructive;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final color =
        destructive ? const Color(0xFFFF3B30) : const Color(0xFF1C1C1E);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: subtitle == null ? 52 : 64,
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 21, color: color),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: color,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!destructive)
                    const Icon(Icons.chevron_right_rounded,
                        size: 20, color: Color(0xFFC7C7CC)),
                ],
              ),
            ),
            if (showDivider)
              const Divider(
                  height: 1, thickness: 0.5, color: Color(0xFFE5E5EA)),
          ],
        ),
      ),
    );
  }
}

Future<T?> _pushColibriBottomSheet<T>(
  WidgetBuilder builder, {
  BuildContext? context,
  Color? backgroundColor,
  double? elevation,
  bool persistent = true,
  ShapeBorder? shape,
  Clip? clipBehavior,
  Color? barrierColor,
  bool? ignoreSafeArea,
  bool useSafeArea = false,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  RouteSettings? settings,
  Duration? enterBottomSheetDuration,
  Duration? exitBottomSheetDuration,
  BoxConstraints? constraints,
}) {
  final navigator = Navigator.of(
    context ?? Get.overlayContext!,
    rootNavigator: useRootNavigator,
  );
  return navigator.push<T>(
    ColibriBottomSheetRoute<T>(
      builder: builder,
      isPersistent: persistent,
      theme: Theme.of(navigator.context),
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: shape,
      removeTop: ignoreSafeArea ?? true,
      useSafeArea: useSafeArea,
      clipBehavior: clipBehavior,
      modalBarrierColor: barrierColor,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      settings: settings,
      enterBottomSheetDuration: enterBottomSheetDuration,
      exitBottomSheetDuration: exitBottomSheetDuration,
      constraints: constraints,
    ),
  );
}

class ColibriBottomSheetRoute<T> extends PopupRoute<T> {
  ColibriBottomSheetRoute({
    required this.builder,
    required this.theme,
    required this.isScrollControlled,
    this.isPersistent = true,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.removeTop = true,
    this.useSafeArea = false,
    this.clipBehavior,
    this.modalBarrierColor,
    this.isDismissible = true,
    this.enableDrag = true,
    this.constraints,
    super.settings,
    Duration? enterBottomSheetDuration,
    Duration? exitBottomSheetDuration,
  })  : enterBottomSheetDuration =
            enterBottomSheetDuration ?? const Duration(milliseconds: 300),
        exitBottomSheetDuration =
            exitBottomSheetDuration ?? const Duration(milliseconds: 240);

  final WidgetBuilder builder;
  final ThemeData theme;
  final bool isScrollControlled;
  final bool isPersistent;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final bool removeTop;
  final bool useSafeArea;
  final Clip? clipBehavior;
  final Color? modalBarrierColor;
  final bool isDismissible;
  final bool enableDrag;
  final BoxConstraints? constraints;
  final Duration enterBottomSheetDuration;
  final Duration exitBottomSheetDuration;

  AnimationController? _animationController;

  @override
  Duration get transitionDuration => enterBottomSheetDuration;

  @override
  Duration get reverseTransitionDuration => exitBottomSheetDuration;

  @override
  bool get barrierDismissible => isDismissible;

  @override
  String? get barrierLabel =>
      MaterialLocalizations.of(navigator!.context).modalBarrierDismissLabel;

  @override
  Color get barrierColor =>
      modalBarrierColor ?? Colors.black.withValues(alpha: 0.32);

  @override
  AnimationController createAnimationController() {
    _animationController = AnimationController(
      vsync: navigator!.overlay!,
      duration: enterBottomSheetDuration,
      reverseDuration: exitBottomSheetDuration,
      debugLabel: 'ColibriBottomSheet',
    );
    return _animationController!;
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = isScrollControlled
        ? mediaQuery.size.height
        : mediaQuery.size.height * 9 / 16;
    return Theme(
      data: theme,
      child: MediaQuery.removePadding(
        context: context,
        removeTop: removeTop,
        child: Padding(
          padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: constraints ?? BoxConstraints(maxHeight: maxHeight),
              child: _ColibriBottomSheetBody<T>(
                animation: animation,
                builder: builder,
                backgroundColor: backgroundColor,
                elevation: elevation,
                shape: shape,
                useSafeArea: useSafeArea,
                clipBehavior: clipBehavior,
                enableDrag: enableDrag,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColibriBottomSheetBody<T> extends StatefulWidget {
  const _ColibriBottomSheetBody({
    required this.animation,
    required this.builder,
    required this.backgroundColor,
    required this.elevation,
    required this.shape,
    required this.useSafeArea,
    required this.clipBehavior,
    required this.enableDrag,
  });

  final Animation<double> animation;
  final WidgetBuilder builder;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final bool useSafeArea;
  final Clip? clipBehavior;
  final bool enableDrag;

  @override
  State<_ColibriBottomSheetBody<T>> createState() =>
      _ColibriBottomSheetBodyState<T>();
}

class _ColibriBottomSheetBodyState<T> extends State<_ColibriBottomSheetBody<T>>
    with SingleTickerProviderStateMixin {
  final _sheetKey = GlobalKey();
  late final AnimationController _returnController =
      AnimationController.unbounded(
    vsync: this,
    value: 0,
    duration: const Duration(milliseconds: 400),
  );

  double _dragOffset = 0;
  double _sheetHeight = 0;
  double _lastDragDelta = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureSheet());
  }

  @override
  void dispose() {
    _returnController.dispose();
    super.dispose();
  }

  void _measureSheet() {
    final renderBox =
        _sheetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !mounted) return;
    if ((_sheetHeight - renderBox.size.height).abs() > 0.5) {
      setState(() => _sheetHeight = renderBox.size.height);
    }
  }

  void _onDragStart(DragStartDetails details) {
    if (_returnController.isAnimating) {
      _returnController.stop(canceled: true);
      _dragOffset = _returnController.value;
    }
    _lastDragDelta = 0;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0;
    _lastDragDelta = delta;
    setState(() {
      if (_dragOffset <= 0 && delta < 0) {
        final resistance = 72 / (72 + _dragOffset.abs());
        _dragOffset = (_dragOffset + delta * resistance).clamp(-72.0, 0.0);
      } else {
        _dragOffset = (_dragOffset + delta).clamp(0.0, 1000.0);
      }
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final height = _sheetHeight > 0
        ? _sheetHeight
        : MediaQuery.sizeOf(context).height * 0.45;
    final velocity = details.primaryVelocity ?? _lastDragDelta;
    if (_dragOffset > height / 3 || velocity > 1000) {
      Navigator.of(context).pop();
      return;
    }
    _returnController
        .animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 420, damping: 32),
        _dragOffset,
        0,
        velocity,
      ),
    )
        .then((_) {
      if (mounted) setState(() => _dragOffset = 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sheet = AnimatedBuilder(
      animation: Listenable.merge([widget.animation, _returnController]),
      builder: (context, child) {
        final entrance = Curves.easeOutCubic.transform(widget.animation.value);
        final dragOffset = _returnController.isAnimating
            ? _returnController.value
            : _dragOffset;
        return FractionalTranslation(
          translation: Offset(0, 1 - entrance),
          child: Transform.translate(
            offset: Offset(0, dragOffset),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: _sheetKey,
        child: Material(
          color: widget.backgroundColor,
          elevation: widget.elevation ?? 0,
          shape: widget.shape ??
              const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
          clipBehavior: widget.clipBehavior ?? Clip.antiAlias,
          child: widget.useSafeArea
              ? SafeArea(
                  top: true,
                  bottom: false,
                  child: widget.builder(context),
                )
              : widget.builder(context),
        ),
      ),
    );

    if (!widget.enableDrag) return sheet;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: _onDragStart,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: sheet,
    );
  }
}

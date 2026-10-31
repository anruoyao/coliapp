import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:get/get.dart';

/// A bottom sheet route with a linear entrance, drag resistance, and
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
            enterBottomSheetDuration ?? const Duration(milliseconds: 220),
        exitBottomSheetDuration =
            exitBottomSheetDuration ?? const Duration(milliseconds: 180);

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
      modalBarrierColor ?? Colors.black.withValues(alpha: 0.24);

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
        _dragOffset = (_dragOffset + delta * 0.22).clamp(-72.0, 0.0);
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
        final entrance = Curves.linear.transform(widget.animation.value);
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
          shape: widget.shape,
          clipBehavior: widget.clipBehavior ?? Clip.none,
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

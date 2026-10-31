import 'dart:async';

import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:proste_indexed_stack/proste_indexed_stack.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/widgets/functions.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/chats_screen/chats_screen.dart';
import 'package:untitled/screens/chats_screen/chats_screen_controller.dart';
import 'package:untitled/screens/dashboard_reels_screen/dashboard_reels_screen.dart';
import 'package:untitled/screens/feed_screen/feed_screen.dart';
import 'package:untitled/screens/colibri_social/colibri_profile_screen.dart';
import 'package:untitled/screens/rooms_screen/rooms_screen.dart';
import 'package:untitled/screens/tabbar/tabbar_controller.dart';
import 'package:untitled/utilities/const.dart';

class TabBarScreen extends StatelessWidget {
  TabBarScreen({super.key});
  final ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final TabBarController controller = Get.put(TabBarController());
    final ChatsScreensController chatScreenController =
        Get.put(ChatsScreensController());
    Functions.changStatusBar(StatusBarStyle.black);
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: cWhite,
      // GetBuilder wraps the whole stack so selectIndex() rebuilds both the
      // content IndexedStack and the tab bar together (fixes tab not switching).
      body: GetBuilder<TabBarController>(
        init: controller,
        builder: (controller) {
          return Stack(
            children: [
              // Content fills the whole screen so it can refract through the glass bar.
              ProsteIndexedStack(
                children: [
                  IndexedStackChild(
                      child: FeedScreen(scrollController: scrollController)),
                  IndexedStackChild(child: RoomsScreen()),
                  IndexedStackChild(
                      child: DashboardReelsScreen(), preload: true),
                  IndexedStackChild(child: ChatsScreen(), preload: true),
                  IndexedStackChild(
                      child: ColibriProfileScreen(), preload: true),
                ],
                index: controller.selectedTab,
              ),
              // Floating Liquid Glass tab bar.
              Positioned(
                left: 12,
                right: 12,
                bottom: bottomPadding + 8,
                child: _LiquidGlassTabBar(
                  selectedIndex: controller.selectedTab,
                  chatScreenController: chatScreenController,
                  onSelect: (index) {
                    if (index == 0 && controller.selectedTab == 0) {
                      HapticFeedback.mediumImpact();
                      if (scrollController.offset == 0) {
                        refreshIndicatorKey.currentState?.show();
                      } else {
                        scrollController.animateTo(0,
                            duration: Duration(milliseconds: 500),
                            curve: Curves.linear);
                      }
                    }
                    controller.selectIndex(index);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Floating Liquid Glass tab bar.
///
/// Recreates Apple's iOS 26 Liquid Glass material on Flutter:
///  1. backdrop blur + saturation of content behind the bar (real refraction)
///  2. translucent white tint with a luminance gradient (dynamic 6-12% opacity)
///  3. diagonal specular sheen (light bending across the surface)
///  4. bright top edge highlight (the "wet glass" rim light)
///  5. soft, layered drop shadow for elevation
///  6. a branded (green) glass capsule behind the selected item
class _LiquidGlassTabBar extends StatefulWidget {
  final int selectedIndex;
  final ChatsScreensController chatScreenController;
  final ValueChanged<int> onSelect;

  const _LiquidGlassTabBar({
    required this.selectedIndex,
    required this.chatScreenController,
    required this.onSelect,
  });

  @override
  State<_LiquidGlassTabBar> createState() => _LiquidGlassTabBarState();
}

class _LiquidGlassTabBarState extends State<_LiquidGlassTabBar> {
  static const _tabCount = 5;
  static const _horizontalPadding = 4.0;
  static const _lensWidth = 68.0;

  bool _isDragging = false;
  double? _dragX;
  double _lensScaleX = 1;
  int? _pointer;
  Offset? _pointerDownPosition;
  Timer? _longPressTimer;

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  double _rubberBand(double value, double limit) {
    final pull = 1 - 1 / (value.abs() * 0.55 / limit + 1);
    return limit * pull * value.sign;
  }

  void _beginDrag(Offset position, double width) {
    final pitch = (width - _horizontalPadding * 2) / _tabCount;
    setState(() {
      _isDragging = true;
      _dragX = position.dx.clamp(
        _horizontalPadding + pitch / 2,
        width - _horizontalPadding - pitch / 2,
      );
      _lensScaleX = 1;
    });
  }

  void _moveDrag(LongPressMoveUpdateDetails details, double width) {
    final pitch = (width - _horizontalPadding * 2) / _tabCount;
    final minX = _horizontalPadding + pitch / 2;
    final maxX = width - _horizontalPadding - pitch / 2;
    final rawX = details.localPosition.dx;
    final overshoot = rawX < minX
        ? rawX - minX
        : rawX > maxX
            ? rawX - maxX
            : 0.0;
    final x = rawX.clamp(minX, maxX) + _rubberBand(overshoot, pitch * 0.7);
    final index = ((x - _horizontalPadding) / pitch).floor().clamp(0, 4);

    setState(() {
      _dragX = x;
      _lensScaleX = 1 + (overshoot.abs() / pitch).clamp(0, 0.22);
    });
    if (index != widget.selectedIndex) {
      HapticFeedback.selectionClick();
      widget.onSelect(index);
    }
  }

  void _handlePointerDown(PointerDownEvent event, double width) {
    if (_pointer != null) return;
    _pointer = event.pointer;
    _pointerDownPosition = event.localPosition;
    _longPressTimer?.cancel();
    _longPressTimer = Timer(const Duration(milliseconds: 350), () {
      if (_pointerDownPosition == null) return;
      _beginDrag(_pointerDownPosition!, width);
      _moveDrag(
        LongPressMoveUpdateDetails(localPosition: _pointerDownPosition!),
        width,
      );
    });
  }

  void _handlePointerMove(PointerMoveEvent event, double width) {
    if (event.pointer != _pointer) return;
    if (!_isDragging &&
        (event.localPosition - _pointerDownPosition!).distance > 12) {
      _longPressTimer?.cancel();
      return;
    }
    if (_isDragging) {
      _moveDrag(
        LongPressMoveUpdateDetails(localPosition: event.localPosition),
        width,
      );
    }
  }

  void _handlePointerEnd(PointerEvent event) {
    if (event.pointer != _pointer) return;
    _longPressTimer?.cancel();
    _pointer = null;
    _pointerDownPosition = null;
    if (_isDragging) _finishDrag();
  }

  void _finishDrag() {
    if (!mounted) return;
    setState(() {
      _isDragging = false;
      _dragX = null;
      _lensScaleX = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final pitch = (width - _horizontalPadding * 2) / _tabCount;
        final selectedX = _horizontalPadding +
            pitch * (widget.selectedIndex + 0.5) -
            _lensWidth / 2;
        final lensLeft = (_dragX == null ? selectedX : _dragX! - _lensWidth / 2)
            .clamp(_horizontalPadding, width - _horizontalPadding - _lensWidth);

        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) => _handlePointerDown(event, width),
          onPointerMove: (event) => _handlePointerMove(event, width),
          onPointerUp: _handlePointerEnd,
          onPointerCancel: _handlePointerEnd,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            transform: Matrix4.translationValues(0, _isDragging ? -7 : 0, 0)
              ..scaleByDouble(_isDragging ? 1.055 : 1.0, 1.0, 1.0, 1.0),
            transformAlignment: Alignment.bottomCenter,
            child: _GlassPill(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedPositioned(
                      duration: _isDragging
                          ? Duration.zero
                          : const Duration(milliseconds: 360),
                      curve: Curves.easeOutBack,
                      left: lensLeft,
                      top: 2,
                      width: _lensWidth * _lensScaleX,
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: cPrimary.withValues(alpha: 0.16),
                          border: Border.all(
                            color: cPrimary.withValues(alpha: 0.30),
                            width: 0.8,
                          ),
                          borderRadius: BorderRadius.circular(23),
                          boxShadow: _isDragging
                              ? [
                                  BoxShadow(
                                    color: cBlack.withValues(alpha: 0.12),
                                    blurRadius: 12,
                                    offset: const Offset(0, 5),
                                  ),
                                ]
                              : const [],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _tabButton(LKeys.feed, MyImages.quill, 0),
                        _tabButton(LKeys.rooms, MyImages.meeting, 1),
                        _tabButton(LKeys.reels, MyImages.reels, 2),
                        GetBuilder<ChatsScreensController>(
                          init: widget.chatScreenController,
                          builder: (c) => _tabButton(
                              LKeys.chats, MyImages.chat, 3,
                              isBadge: c.isNewMessage),
                        ),
                        _tabButton(LKeys.profile, MyImages.profile, 4),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _tabButton(String title, String image, int index,
      {bool isBadge = false}) {
    return GestureDetector(
      onTap: () => widget.onSelect(index),
      behavior: HitTestBehavior.opaque,
      child: _TabItem(
        title: title,
        image: image,
        isSelected: widget.selectedIndex == index,
        isBadge: isBadge,
      ),
    );
  }
}

/// Real Liquid Glass surface powered by liquid_glass_easy.
///
/// On Impeller (Android/iOS default) the lens refracts the live backdrop in
/// real time — content behind the bar is genuinely bent and magnified at the
/// edges, not merely blurred. On Skia (Web/Windows) it gracefully degrades to
/// a frosted look. The shader handles blur + tint + specular + edge light +
/// chromatic aberration internally; we only add a soft elevation shadow.
class _GlassPill extends StatelessWidget {
  final Widget child;

  const _GlassPill({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      // Soft elevation shadow around the floating glass pill.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 28,
              offset: const Offset(0, 12)),
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: LiquidGlassLens(
        style: const LiquidGlassStyle(
          shape: LiquidGlassShape.squircle(
            cornerRadius: 34,
            clipQuality: LiquidGlassClipQuality.exact,
          ),
          appearance: LiquidGlassAppearance(
            color: Color(0x22FFFFFF), // ~13% white tint (Apple-like)
          ),
          refraction: LiquidGlassRefraction(
            distortion: 0.13, // light-bending strength at edges
            distortionWidth: 30, // thickness of the refraction band
            chromaticAberration: 0.003, // subtle RGB fringe at edges
          ),
        ),
        child: child,
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String title;
  final String image;
  final bool isSelected;
  final bool isBadge;

  const _TabItem({
    required this.title,
    required this.image,
    required this.isSelected,
    this.isBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topRight,
              children: [
                Image.asset(
                  image,
                  width: 22,
                  height: 22,
                  color: isSelected ? cPrimary : cLightText,
                ),
                if (isBadge)
                  Positioned(
                    bottom: 13,
                    left: 13,
                    child: Container(
                      height: 9,
                      width: 9,
                      decoration: const BoxDecoration(
                        color: cRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title.tr,
              style: MyTextStyle.gilroyRegular(
                size: 11,
                color: isSelected ? cPrimary : cLightText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

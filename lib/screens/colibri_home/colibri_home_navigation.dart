import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:get/get.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/utilities/const.dart';

class ColibriHomeNavigation extends StatefulWidget {
  static const double height = 54;

  final int index;
  final int notificationUnread;
  final int chatUnread;
  final ValueChanged<int> onSelected;

  const ColibriHomeNavigation({
    super.key,
    required this.index,
    required this.notificationUnread,
    required this.chatUnread,
    required this.onSelected,
  });

  @override
  State<ColibriHomeNavigation> createState() => _ColibriHomeNavigationState();
}

class _ColibriHomeNavigationState extends State<ColibriHomeNavigation>
    with SingleTickerProviderStateMixin {
  static List<(IconData, IconData, String)> get _entries => [
        (Icons.home_outlined, Icons.home_rounded, LKeys.homeHome.tr),
        (Icons.search_outlined, Icons.search_rounded, LKeys.homeSearch.tr),
        (
          Icons.notifications_none_rounded,
          Icons.notifications_rounded,
          LKeys.commonNotifications.tr,
        ),
        (
          Icons.chat_bubble_outline_rounded,
          Icons.chat_bubble_rounded,
          LKeys.commonChats.tr,
        ),
        (Icons.person_outline_rounded, Icons.person_rounded, LKeys.commonMe.tr),
      ];
  static final _spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 520,
    ratio: 1,
  );

  late final AnimationController _position = AnimationController.unbounded(
    value: widget.index.toDouble(),
    vsync: this,
  );
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) _position.value = widget.index.toDouble();
  }

  @override
  void didUpdateWidget(ColibriHomeNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index == widget.index) return;
    if (_reduceMotion) {
      _position.value = widget.index.toDouble();
      return;
    }
    _position.animateWith(SpringSimulation(
      _spring,
      _position.value,
      widget.index.toDouble(),
      _position.velocity,
    ));
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ColibriHomeNavigation.height,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xF2F7F8FA),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E5EA)),
        boxShadow: [
          BoxShadow(
            color: cBlack.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / _entries.length;
          final rtl = Directionality.of(context) == TextDirection.rtl;
          return Stack(
            alignment: Alignment.topLeft,
            clipBehavior: Clip.none,
            children: [
              AnimatedBuilder(
                animation: _position,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: cPrimary,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: SizedBox(
                    width: itemWidth,
                    height: constraints.maxHeight,
                  ),
                ),
                builder: (context, child) {
                  final position = _position.value.clamp(0.0, 4.0);
                  return Transform.translate(
                    offset: Offset(
                      (rtl ? 4 - position : position) * itemWidth,
                      0,
                    ),
                    child: child,
                  );
                },
              ),
              Row(
                children: [
                  for (var i = 0; i < _entries.length; i++)
                    Expanded(
                      child: _NavigationItem(
                        icon: _entries[i].$1,
                        selectedIcon: _entries[i].$2,
                        label: _entries[i].$3,
                        selected: widget.index == i,
                        position: _position,
                        index: i,
                        reduceMotion: _reduceMotion,
                        unread: i == 2
                            ? widget.notificationUnread
                            : i == 3
                                ? widget.chatUnread
                                : 0,
                        onTap: () => widget.onSelected(i),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NavigationItem extends StatefulWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final Animation<double> position;
  final int index;
  final bool reduceMotion;
  final int unread;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.position,
    required this.index,
    required this.reduceMotion,
    required this.unread,
    required this.onTap,
  });

  @override
  State<_NavigationItem> createState() => _NavigationItemState();
}

class _NavigationItemState extends State<_NavigationItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      value: widget.unread > 0 ? '${widget.unread}' : null,
      onTap: widget.onTap,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
          borderRadius: BorderRadius.circular(25),
          splashFactory: NoSplash.splashFactory,
          highlightColor: cPrimary.withValues(alpha: 0.08),
          child: AnimatedScale(
            scale: _pressed && !widget.reduceMotion ? 0.92 : 1,
            duration: Duration(milliseconds: widget.reduceMotion ? 0 : 120),
            curve: Curves.easeOutCubic,
            child: SizedBox(
              height: ColibriHomeNavigation.height - 6,
              child: AnimatedBuilder(
                animation: widget.position,
                builder: (context, child) {
                  final emphasis =
                      (1 - (widget.position.value - widget.index).abs())
                          .clamp(0.0, 1.0);
                  final color = Color.lerp(cLightText, cWhite, emphasis)!;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Transform.scale(
                            scale:
                                widget.reduceMotion ? 1 : 1 + emphasis * 0.06,
                            child: Stack(
                              children: [
                                Opacity(
                                  opacity: 1 - emphasis,
                                  child:
                                      Icon(widget.icon, size: 20, color: color),
                                ),
                                Opacity(
                                  opacity: emphasis,
                                  child: Icon(widget.selectedIcon,
                                      size: 20, color: color),
                                ),
                              ],
                            ),
                          ),
                          if (widget.unread > 0)
                            PositionedDirectional(
                              start: 13,
                              top: -6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                constraints: const BoxConstraints(minWidth: 16),
                                decoration: BoxDecoration(
                                  color: cRed,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.unread > 99
                                      ? '99+'
                                      : '${widget.unread}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

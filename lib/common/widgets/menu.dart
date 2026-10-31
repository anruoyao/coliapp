import 'package:flutter/material.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'package:untitled/utilities/const.dart';

class Menu extends StatelessWidget {
  final bool isFromPost;
  final List<PopupMenuItem>? items;
  final List<MenuAction>? children;
  final Color? color;
  final bool isForVideo;
  final Function(String)? onSelect;

  const Menu({
    super.key,
    this.isForVideo = true,
    this.items,
    this.children,
    this.color,
    this.onSelect,
    this.isFromPost = false,
  });

  List<_MenuEntry> _entries() {
    if (children != null) {
      return children!
          .map((action) =>
              _MenuEntry(label: Text(action.title), onTap: action.callback))
          .toList();
    }
    return (items ?? const <PopupMenuItem>[]).map((item) {
      final value = item.value;
      return _MenuEntry(
        label: item.child ??
            Text(value?.toString() ?? '',
                style: MyTextStyle.gilroyMedium(color: cDarkText)),
        onTap: item.onTap ??
            (onSelect != null && value is String
                ? () => onSelect!(value)
                : null),
      );
    }).toList();
  }

  Future<void> _show(BuildContext context) async {
    final entries = _entries();
    if (entries.isEmpty) return;
    final selected = await showColibriBottomSheet<int>(
      _MenuSheet(entries: entries),
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      ),
    );
    if (selected != null && selected < entries.length) {
      entries[selected].onTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _show(context),
      child: isFromPost
          ? Icon(
              Icons.more_horiz,
              color: color ?? (isForVideo ? cLightIcon : cLightText),
            )
          : Image.asset(
              MyImages.more,
              color: color ?? cWhite,
              height: 30,
              width: 30,
            ),
    );
  }
}

class MenuAction {
  final String title;
  final VoidCallback callback;

  const MenuAction({required this.title, required this.callback});
}

class _MenuEntry {
  final Widget label;
  final VoidCallback? onTap;

  const _MenuEntry({required this.label, this.onTap});
}

class _MenuSheet extends StatelessWidget {
  final List<_MenuEntry> entries;

  const _MenuSheet({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cLightIcon.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < entries.length; index++)
              InkWell(
                onTap: () => Navigator.of(context).pop(index),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: entries[index].label,
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// A single action shown inside a [LiquidGlassMenu].
class LiquidGlassMenuItem {
  final String label;
  final VoidCallback onTap;

  const LiquidGlassMenuItem({required this.label, required this.onTap});
}

/// A post/action menu displayed by the shared spring bottom-sheet route.
class LiquidGlassMenu extends StatelessWidget {
  final Widget trigger;
  final List<LiquidGlassMenuItem> items;
  final Color? triggerColor;

  const LiquidGlassMenu({
    super.key,
    required this.trigger,
    required this.items,
    this.triggerColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final selected = await showColibriBottomSheet<int>(
          _MenuSheet(
            entries: items
                .map((item) => _MenuEntry(
                      label: Text(
                        item.label,
                        style: MyTextStyle.gilroyMedium(
                            size: 15, color: cDarkText),
                      ),
                      onTap: item.onTap,
                    ))
                .toList(),
          ),
          context: context,
          backgroundColor: Colors.transparent,
          useSafeArea: true,
          isScrollControlled: true,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
        );
        if (selected != null && selected < items.length) {
          items[selected].onTap();
        }
      },
      child: trigger,
    );
  }
}

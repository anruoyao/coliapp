import 'package:flutter/material.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'package:untitled/utilities/const.dart';

class Menu {
  final List<MenuAction> children;

  Menu({required this.children});
}

class MenuAction {
  final String title;
  final VoidCallback callback;

  MenuAction({required this.title, required this.callback});
}

typedef MenuProvider = Menu? Function(BuildContext context);

class ContextMenuWidget extends StatelessWidget {
  final Widget child;
  final MenuProvider menuProvider;

  const ContextMenuWidget({
    super.key,
    required this.child,
    required this.menuProvider,
  });

  Future<void> _showMenu(BuildContext context) async {
    final menu = menuProvider(context);
    if (menu == null || menu.children.isEmpty) return;

    final selected = await showColibriBottomSheet<int>(
      _ContextMenuSheet(menu: menu),
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      ),
    );
    if (selected != null && selected < menu.children.length) {
      menu.children[selected].callback();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _showMenu(context),
      child: child,
    );
  }
}

class _ContextMenuSheet extends StatelessWidget {
  final Menu menu;

  const _ContextMenuSheet({required this.menu});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cWhite,
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
            for (var index = 0; index < menu.children.length; index++)
              InkWell(
                onTap: () => Navigator.of(context).pop(index),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      menu.children[index].title,
                      style: MyTextStyle.gilroyRegular(color: cDarkText),
                    ),
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

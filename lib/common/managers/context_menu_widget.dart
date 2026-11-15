import 'package:flutter/material.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';

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
    return ColibriSheetSurface(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ColibriSheetHeader(),
          const SizedBox(height: 8),
          for (var index = 0; index < menu.children.length; index++)
            ColibriSheetActionRow(
              title: menu.children[index].title,
              showDivider: index < menu.children.length - 1,
              onTap: () => Navigator.of(context).pop(index),
            ),
        ],
      ),
    );
  }
}

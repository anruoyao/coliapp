import 'package:flutter/material.dart';
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
              // Content fills the screen beneath the translucent tab bar.
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
              // Lightweight floating tab bar.
              Positioned(
                left: 12,
                right: 12,
                bottom: bottomPadding + 8,
                child: _FloatingTabBar(
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

/// Legacy navigation bar with a lightweight translucent background.
class _FloatingTabBar extends StatelessWidget {
  final int selectedIndex;
  final ChatsScreensController chatScreenController;
  final ValueChanged<int> onSelect;

  const _FloatingTabBar({
    required this.selectedIndex,
    required this.chatScreenController,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return _TabBarSurface(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _tabButton(LKeys.feed, MyImages.quill, 0),
            _tabButton(LKeys.rooms, MyImages.meeting, 1),
            _tabButton(LKeys.reels, MyImages.reels, 2),
            GetBuilder<ChatsScreensController>(
              init: chatScreenController,
              builder: (controller) => _tabButton(
                LKeys.chats,
                MyImages.chat,
                3,
                isBadge: controller.isNewMessage,
              ),
            ),
            _tabButton(LKeys.profile, MyImages.profile, 4),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String title, String image, int index,
      {bool isBadge = false}) {
    return GestureDetector(
      onTap: () => onSelect(index),
      behavior: HitTestBehavior.opaque,
      child: _TabItem(
        title: title,
        image: image,
        isSelected: selectedIndex == index,
        isBadge: isBadge,
      ),
    );
  }
}

/// Static translucent surface for the legacy tab bar.
class _TabBarSurface extends StatelessWidget {
  final Widget child;

  const _TabBarSurface({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      // Keep the legacy floating bar legible over scrolling content.
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: ColoredBox(
          color: const Color(0xEFFFFFFF),
          child: child,
        ),
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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/posts_model.dart';
import 'package:untitled/models/reel_model.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/screens/add_post_screen/add_post_screen.dart';
import 'package:untitled/screens/camera_screen/create_reel_screen.dart';
import 'package:untitled/screens/story_screen/create_story_screen/create_story_screen.dart';
import 'package:untitled/utilities/const.dart';

class FloatingBtnForCreating extends StatelessWidget {
  final Function(Post feed)? onPostBack;
  final Function()? onStoryBack;
  final Function(Reel reel)? onReelBack;
  final bool overlayTabBar;

  const FloatingBtnForCreating({
    super.key,
    this.onPostBack,
    this.onStoryBack,
    this.onReelBack,
    this.overlayTabBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = overlayTabBar
        ? MediaQuery.of(context).padding.bottom + kBottomNavReservedHeight
        : 0.0;
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 14, 14, 14 + bottomInset),
        child: IconButton.filled(
          tooltip: LKeys.upload.tr,
          onPressed: () => _openSheet(context),
          style: IconButton.styleFrom(
            backgroundColor: cPrimary,
            foregroundColor: cBlack,
            fixedSize: const Size(60, 60),
          ),
          icon: Image.asset(
            MyImages.quill,
            width: 25,
            height: 25,
          ),
        ),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    showColibriBottomSheet(
      _CreatingChooseSheet(
        onPostTap: _createPost,
        onReelTap: _createReel,
        onStoryTap: _createStory,
      ),
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxHeight: 380),
    );
  }

  void _createStory() {
    showColibriBottomSheet(
      CreateStoryScreen(
        user: SessionManager.shared.getUser() ?? User(),
        shouldShowStory: false,
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
    ).then((value) {
      onStoryBack?.call();
    });
  }

  void _createPost() {
    Get.to(() => AddPostScreen(), opaque: false)?.then((value) {
      if (value is Post) onPostBack?.call(value);
    });
  }

  void _createReel() {
    Get.to(() => CreateReelScreen(), opaque: false)?.then((value) {
      if (value is Reel) onReelBack?.call(value);
    });
  }
}

class _CreatingChooseSheet extends StatelessWidget {
  final Function() onPostTap;
  final Function() onStoryTap;
  final Function() onReelTap;

  const _CreatingChooseSheet({
    required this.onPostTap,
    required this.onStoryTap,
    required this.onReelTap,
  });

  @override
  Widget build(BuildContext context) {
    return ColibriSheetSurface(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ColibriSheetHeader(
            title: LKeys.upload.tr,
            trailing: const ColibriSheetCloseButton(),
          ),
          const SizedBox(height: 8),
          ColibriSheetActionRow(
            title: LKeys.feed.tr,
            icon: Icons.post_add_outlined,
            showDivider: true,
            onTap: () {
              Navigator.of(context).pop();
              onPostTap();
            },
          ),
          ColibriSheetActionRow(
            title: LKeys.story.tr,
            icon: Icons.add_a_photo_outlined,
            showDivider: true,
            onTap: () {
              Navigator.of(context).pop();
              onStoryTap();
            },
          ),
          ColibriSheetActionRow(
            title: LKeys.reels.tr,
            icon: Icons.video_collection_outlined,
            onTap: () {
              Navigator.of(context).pop();
              onReelTap();
            },
          ),
        ],
      ),
    );
  }
}

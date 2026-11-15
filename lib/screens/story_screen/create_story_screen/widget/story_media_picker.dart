import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/story_screen/create_story_screen/create_story_controller.dart';

class StoryMediaPicker extends StatelessWidget {
  final CreateStoryController controller;

  const StoryMediaPicker({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ColibriSheetSurface(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ColibriSheetHeader(
            title: LKeys.howDoYouWant.tr,
            trailing: const ColibriSheetCloseButton(),
          ),
          const SizedBox(height: 8),
          ColibriSheetActionRow(
            title: LKeys.image.tr,
            icon: Icons.photo_outlined,
            showDivider: true,
            onTap: controller.pickImageFromGallery,
          ),
          ColibriSheetActionRow(
            title: LKeys.video.tr,
            icon: Icons.video_library_outlined,
            onTap: controller.pickVideoFromGallery,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/list_extension.dart';
import 'package:untitled/common/widgets/no_data_view.dart';
import 'package:untitled/screens/camera_screen/music_sheet/music_explore_page.dart';
import 'package:untitled/screens/camera_screen/music_sheet/music_sheet_controller.dart';

class MusicSavedPage extends StatelessWidget {
  final MusicSheetController controller;

  const MusicSavedPage({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      var savedMusic = controller.savedMusic.search(
        controller.searchQuery.value,
        (p0) => p0.title ?? '',
        (p0) => p0.artist ?? '',
      );
      return NoDataView(
        showShow: savedMusic.isEmpty,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: savedMusic.length,
          itemBuilder: (context, index) {
            var music = savedMusic[index];
            return MusicCard(
              music: music,
              controller: controller,
            );
          },
        ),
      );
    });
  }
}

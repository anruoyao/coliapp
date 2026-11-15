import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/music_service.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/managers/load_more_widget.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/music_categories_model.dart';
import 'package:untitled/models/musics_model.dart';
import 'package:untitled/screens/camera_screen/music_sheet/music_explore_page.dart';
import 'package:untitled/screens/camera_screen/music_sheet/music_sheet_controller.dart';
import 'package:untitled/utilities/const.dart';

class MusicCategorySheet extends StatelessWidget {
  final MusicCategory category;
  final MusicSheetController controller;

  MusicCategorySheet(
      {super.key, required this.controller, required this.category});

  final RxList<Music> musics = RxList();

  @override
  Widget build(BuildContext context) {
    fetchSounds(musics.length);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: ColibriSheetSurface(
        backgroundColor: cBlackSheetBG,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Obx(
          () => Column(
            children: [
              ColibriSheetHeader(
                title: category.title ?? '',
                foregroundColor: cWhite,
                handleColor: cWhite.withValues(alpha: 0.35),
                trailing: const ColibriSheetCloseButton(),
              ),
              Text(
                '${category.musicsCount ?? 0} ${LKeys.musics.tr}',
                style: MyTextStyle.gilroyRegular(size: 14, color: cLightText),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: LoadMoreWidget(
                  loadMore: () async {
                    await fetchSounds(musics.length);
                  },
                  child: ListView.builder(
                    itemCount: musics.length,
                    itemBuilder: (context, index) => MusicCard(
                      music: musics[index],
                      controller: controller,
                      isFromCategorySheet: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> fetchSounds(int start) async {
    musics.addAll(await MusicService.shared.fetchMusicByCategory(
      start: start,
      categoryId: category.id ?? 0,
    ));
  }
}

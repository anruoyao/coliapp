import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/music_service.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/managers/load_more_widget.dart';
import 'package:untitled/common/widgets/buttons/xmark_button.dart';
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
    return SafeArea(
      bottom: false,
      child: ClipSmoothRect(
        radius: SmoothBorderRadius.vertical(
          top: SmoothRadius(cornerRadius: 30, cornerSmoothing: cornerSmoothing),
        ),
        child: Obx(
          () => Container(
            color: cBlackSheetBG,
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 20, left: 20, top: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.title ?? '',
                              style: MyTextStyle.gilroySemiBold(
                                  size: 18, color: cPrimary),
                            ),
                            Text(
                              '${category.musicsCount ?? 0} ${LKeys.musics.tr}',
                              style: MyTextStyle.gilroyRegular(
                                  size: 18, color: cLightText),
                            ),
                          ],
                        ),
                        XmarkButtonForSheet()
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: LoadMoreWidget(
                      loadMore: () async {
                        await fetchSounds(musics.length);
                      },
                      child: ListView.builder(
                        itemCount: musics.length,
                        itemBuilder: (context, index) {
                          return MusicCard(
                            music: musics[index],
                            controller: controller,
                            isFromCategorySheet: true,
                          );
                        },
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> fetchSounds(int start) async {
    musics.addAll(await MusicService.shared
        .fetchMusicByCategory(start: start, categoryId: category.id ?? 0));
  }
}

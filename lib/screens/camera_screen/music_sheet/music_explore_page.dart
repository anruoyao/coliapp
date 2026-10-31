import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/common/widgets/no_data_view.dart';
import 'package:untitled/models/musics_model.dart';
import 'package:untitled/screens/camera_screen/music_sheet/music_sheet_controller.dart';
import 'package:untitled/utilities/const.dart';

class MusicExplorePage extends StatelessWidget {
  final MusicSheetController controller;

  const MusicExplorePage({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => NoDataView(
        showShow: controller.allMusics.isEmpty,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: controller.allMusics.length,
          itemBuilder: (context, index) {
            var music = controller.allMusics[index];
            return MusicCard(
              music: music,
              controller: controller,
            );
          },
        ),
      ),
    );
  }
}

class MusicCard extends StatelessWidget {
  const MusicCard({
    required this.music,
    required this.controller,
    this.isFromCategorySheet = false,
  });

  final MusicSheetController controller;
  final Music music;
  final bool isFromCategorySheet;

  @override
  Widget build(BuildContext context) {
    RxBool isSaved = music.isSaved.obs;
    return Obx(
      () => InkWell(
        onTap: () {
          controller.selectMusic(
              music: music, isFromCategorySheet: isFromCategorySheet);
        },
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: ClipSmoothRect(
            radius: SmoothBorderRadius(cornerRadius: 13),
            child: Container(
              padding: EdgeInsets.only(top: 8, bottom: 8, left: 8, right: 16),
              color: cWhite.withValues(alpha: 0.08),
              child: Row(
                children: [
                  Obx(
                    () => InkWell(
                      onTap: () {
                        controller.startMusic(music);
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          MyCachedImage(
                            imageUrl: music.image,
                            height: 50,
                            width: 50,
                            cornerRadius: 12,
                          ),
                          if (controller.selectedMusicToPlay.value?.id ==
                              music.id)
                            if (controller.playerStatus == PlayerStatus.loading)
                              Container(
                                height: 50,
                                width: 50,
                                padding: EdgeInsets.all(15),
                                child: CircularProgressIndicator(
                                  color: cWhite,
                                  strokeWidth: 3,
                                ),
                              )
                            else
                              CircleAvatar(
                                backgroundColor: cBlack.withValues(alpha: 0.5),
                                foregroundColor: cWhite,
                                radius: 15,
                                child: Icon(
                                  (controller.playerStatus ==
                                          PlayerStatus.playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded),
                                  size: 20,
                                ),
                              )
                          else
                            CircleAvatar(
                              backgroundColor: cBlack.withValues(alpha: 0.5),
                              foregroundColor: cWhite,
                              radius: 15,
                              child: Icon(
                                (Icons.play_arrow_rounded),
                                size: 20,
                              ),
                            )
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        music.title ?? '',
                        style:
                            MyTextStyle.gilroySemiBold(size: 14, color: cWhite),
                      ),
                      Text(
                        music.artist ?? '',
                        style: MyTextStyle.gilroyRegular(
                            size: 14, color: cLightText),
                      ),
                    ],
                  ),
                  Spacer(),
                  InkWell(
                    onTap: () {
                      isSaved.value = !isSaved.value;
                      controller.bookmarkTheMusic(music);
                    },
                    child: Image.asset(
                      !isSaved.value
                          ? MyImages.bookmark
                          : MyImages.bookmarkFill,
                      height: 25,
                      width: 25,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

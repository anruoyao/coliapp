import 'dart:io';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:detectable_text_field/detectable_text_field.dart';
import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/managers/url_extractor/parsers/base_parser.dart';
import 'package:untitled/common/widgets/buttons/circle_button.dart';
import 'package:untitled/common/widgets/interest_selector.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/add_post_screen/add_post_controller.dart';
import 'package:untitled/screens/add_post_screen/capture_or_choose_sheet.dart';
import 'package:untitled/screens/add_post_screen/record_audio/record_audio_screen.dart';
import 'package:untitled/screens/extra_views/top_bar.dart';
import 'package:untitled/screens/post/video_player_sheet.dart';
import 'package:untitled/utilities/const.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class AddPostScreen extends StatelessWidget {
  const AddPostScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AddPostController controller = AddPostController();

    return Scaffold(
      body: Column(
        children: [
          TopBarForInView(
            title: LKeys.addPost,
            child: GetBuilder(
              init: controller,
              id: controller.postBtnGetID,
              builder: (controller) {
                var isDisable = controller.textEditingController.text.isEmpty;
                return GestureDetector(
                  onTap: () {
                    if (!isDisable) {
                      controller.uploadPost();
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    padding: const EdgeInsets.only(
                        right: 20, left: 20, top: 7, bottom: 5),
                    decoration: BoxDecoration(
                        color: isDisable
                            ? cLightText.withValues(alpha: 0.5)
                            : cPrimary,
                        borderRadius: BorderRadius.circular(100)),
                    child: Text(
                      LKeys.post.tr.toUpperCase(),
                      style: MyTextStyle.gilroySemiBold(
                          color: isDisable ? cLightText : cBlack, size: 14),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(15),
                      height: 130,
                      decoration: decoration(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 12),
                      child: DetectableTextField(
                        style: MyTextStyle.outfitLight(size: 18, color: cBlack)
                            .copyWith(height: 1.2),
                        textCapitalization: TextCapitalization.sentences,
                        expands: true,
                        minLines: null,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: LKeys.writeHere.tr,
                          hintStyle: MyTextStyle.outfitLight(
                              color: cLightText.withValues(alpha: 0.6),
                              size: 18),
                          border: InputBorder.none,
                          counterText: '',
                          isDense: true,
                          contentPadding: const EdgeInsets.all(0),
                        ),
                        cursorColor: cPrimary,
                        maxLength: null,
                        keyboardType: TextInputType.multiline,
                        controller: controller.textEditingController,
                        textInputAction: TextInputAction.next,
                        onChanged: controller.onTextChanged,
                      ),
                    ),
                    GetBuilder<AddPostController>(
                        init: controller,
                        id: controller.imageGetID,
                        builder: (controller) {
                          print(controller.audioPlayerController);
                          if (controller.audioPlayerController != null) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                AudioWavePlayerCard(
                                  playerController:
                                      controller.audioPlayerController!,
                                ),
                                GestureDetector(
                                  onTap: controller.removeAudio,
                                  child: Container(
                                    color: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    child: Text(
                                      LKeys.removeThisAudio.tr,
                                      style: MyTextStyle.gilroyMedium(
                                        color: cLightText,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            );
                          } else if (controller.metaData != null) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: metadataView(controller),
                            );
                          } else if (controller.imageFileList.isEmpty &&
                              controller.videoFile == null) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: Row(
                                children: [
                                  postBtn(controller, Icons.image_rounded,
                                      PickerStyle.image, () {
                                    onImageVideoBtnTap(
                                        controller, PickerStyle.image);
                                  }),
                                  const SizedBox(width: 15),
                                  postBtn(controller, Icons.video_library,
                                      PickerStyle.video, () {
                                    onImageVideoBtnTap(
                                        controller, PickerStyle.video);
                                  }),
                                  const SizedBox(width: 15),
                                  postBtn(controller, Icons.mic_outlined,
                                      PickerStyle.audio, () {
                                    showColibriBottomSheet(
                                            RecordAudioScreen(
                                              onRecordDone:
                                                  controller.setAudioPlayer,
                                            ),
                                            enableDrag: false,
                                            isScrollControlled: true)
                                        .then((value) {
                                      controller.audioPlayerController
                                          ?.pausePlayer();
                                    });
                                  }),
                                ],
                              ),
                            );
                          } else {
                            return imageOrVideoDataView(controller);
                          }
                        }),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: InterestSelectorSection(
                        title: LKeys.selectInterestToContinue,
                        selectedInterests: controller.selectedInterests,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget metadataView(AddPostController controller) {
    UrlMetadata metadata = controller.metaData ?? UrlMetadata();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: GestureDetector(
            child: CircleIcon(color: cBlack, iconData: Icons.close),
            onTap: controller.closePreview,
          ),
        ),
        UrlMetaDataCard(metadata: metadata),
      ],
    );
  }

  Widget postBtn(AddPostController controller, IconData iconData,
      PickerStyle type, Function() onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: decoration(),
          child: Icon(
            iconData,
            color: cLightText,
          ),
        ),
      ),
    );
  }

  Widget imageOrVideoDataView(AddPostController controller) {
    if (controller.imageFileList.isNotEmpty) {
      return PreviewPostImagesPageView(
        controller: controller,
      );
    }
    return PreviewPostVideoView(controller: controller);
  }

  ShapeDecoration decoration() {
    return const ShapeDecoration(
        color: cLightBg,
        shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius.all(SmoothRadius(
                cornerRadius: 10, cornerSmoothing: cornerSmoothing))));
  }

  void onImageVideoBtnTap(AddPostController controller, PickerStyle type) {
    showColibriBottomSheet(CaptureOrChooseSheet(onCaptureTap: () {
      controller.pick(type: type, source: ImageSource.camera);
    }, onChooseTap: () {
      controller.pick(type: type, source: ImageSource.gallery);
    }));
  }
}

class PreviewPostVideoView extends StatelessWidget {
  final AddPostController controller;

  const PreviewPostVideoView({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return (controller.videoPlayerController != null)
        ? ClipSmoothRect(
            radius: const SmoothBorderRadius.all(SmoothRadius(
                cornerRadius: 8, cornerSmoothing: cornerSmoothing)),
            child: GetBuilder<AddPostController>(
                init: controller,
                id: 'player',
                builder: (controller) {
                  return Container(
                    width: Get.width - 40,
                    height: Get.width - 40,
                    color: cBlack,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        GestureDetector(
                          onTap: controller.playPause,
                          child: AspectRatio(
                            aspectRatio: controller
                                    .videoPlayerController?.value.aspectRatio ??
                                0,
                            child:
                                VideoPlayer(controller.videoPlayerController!),
                          ),
                        ),
                        Column(
                          children: [
                            Row(
                              children: [
                                const SizedBox(height: 50),
                                const Spacer(),
                                DeleteIcon(onTap: controller.removeVideo)
                              ],
                            ),
                            const Spacer(),
                            if (controller
                                    .videoPlayerController?.value.isPlaying ??
                                false)
                              Container()
                            else
                              GestureDetector(
                                onTap: controller.play,
                                child: CircleAvatar(
                                  backgroundColor:
                                      cBlack.withValues(alpha: 0.4),
                                  foregroundColor: cWhite,
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    size: 30,
                                  ),
                                ),
                              ),
                            const Spacer(),
                            VideoSlider(
                                controller: controller.videoPlayerController!,
                                onChange: controller.onChange),
                          ],
                        )
                      ],
                    ),
                  );
                }),
          )
        : Container();
  }
}

class PreviewPostImagesPageView extends StatelessWidget {
  final AddPostController controller;

  const PreviewPostImagesPageView({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
        init: controller,
        id: "pageView",
        builder: (controller) {
          var contentCount = controller.imageFileList.length;
          return SizedBox(
            height:
                controller.imageFileList.length == 1 ? null : Get.width - 40,
            // width: double.infinity,
            width: Get.width - 40,
            child: ClipSmoothRect(
              radius: const SmoothBorderRadius.all(SmoothRadius(
                  cornerRadius: 12, cornerSmoothing: cornerSmoothing)),
              child: Stack(
                children: [
                  if (controller.imageFileList.length == 1)
                    Image.file(File(controller.imageFileList[0].path),
                        width: double.infinity, fit: BoxFit.fitWidth)
                  else
                    PageView.builder(
                      onPageChanged: (value) => controller.onPageChange(value),
                      itemCount: controller.imageFileList.length,
                      itemBuilder: (context, index) {
                        var image = controller.imageFileList[index];
                        return Image.file(File(image.path), fit: BoxFit.cover);
                      },
                    ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          controller.imageFileList.length <
                                  ((SessionManager.shared
                                          .getSettings()
                                          ?.maxImagesCanBeUploadedInOnePost ??
                                      0))
                              ? DeleteIcon(
                                  onTap: () {
                                    showColibriBottomSheet(
                                        CaptureOrChooseSheet(onCaptureTap: () {
                                      controller.pick(
                                          type: PickerStyle.image,
                                          source: ImageSource.camera);
                                    }, onChooseTap: () {
                                      controller.pick(
                                          type: PickerStyle.image,
                                          source: ImageSource.gallery);
                                    }));
                                  },
                                  iconData: Icons.add_rounded,
                                )
                              : Container(),
                          DeleteIcon(
                            onTap: () {
                              controller.removeImage();
                            },
                          )
                        ],
                      ),
                      contentCount == 1
                          ? SizedBox()
                          : Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(contentCount, (index) {
                                  return Container(
                                    margin: const EdgeInsets.only(right: 3),
                                    height: 2.7,
                                    width: contentCount > 8
                                        ? (Get.width - 120) / contentCount
                                        : 30,
                                    decoration: ShapeDecoration(
                                      color:
                                          controller.selectedImageIndex == index
                                              ? cWhite
                                              : cWhite.withValues(alpha: 0.30),
                                      shape: const SmoothRectangleBorder(
                                          borderRadius: SmoothBorderRadius.all(
                                              SmoothRadius(
                                                  cornerRadius: 10,
                                                  cornerSmoothing:
                                                      cornerSmoothing))),
                                    ),
                                  );
                                }),
                              ),
                            ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
  }
}

class DeleteIcon extends StatelessWidget {
  final Function() onTap;
  final IconData iconData;

  const DeleteIcon(
      {Key? key, required this.onTap, this.iconData = Icons.delete_rounded})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var color = cWhite;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8, top: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.4), shape: BoxShape.circle),
        child: Icon(iconData, color: color, size: 25),
      ),
    );
  }
}

class UrlMetaDataCard extends StatelessWidget {
  final UrlMetadata metadata;

  const UrlMetaDataCard({super.key, required this.metadata});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final Uri uri = Uri.parse(metadata.url ?? '');

        if (!await launchUrl(uri)) {
          print('Could not launch $uri');
        }
      },
      child: Container(
        padding: EdgeInsets.all(10),
        color: cLightBg.withValues(alpha: 0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            metadata.image == null
                ? Container()
                : Container(
                    color: cWhite,
                    padding: EdgeInsets.all(10),
                    child: CachedNetworkImage(
                      imageUrl: metadata.image!,
                      width: Get.width - 40,
                      height: 100,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) {
                        return placeHolder();
                      },
                      placeholder: (context, url) {
                        return placeHolder();
                      },
                    ),
                  ),
            metadata.title == null
                ? Container()
                : Container(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      metadata.title ?? '',
                      style: MyTextStyle.gilroySemiBold(size: 16),
                    ),
                  ),
            metadata.description == null
                ? Container()
                : DetectableText(
                    maxLines: null,
                    lessStyle:
                        MyTextStyle.gilroyMedium(color: cDarkText, size: 14),
                    moreStyle:
                        MyTextStyle.gilroyMedium(color: cDarkText, size: 14),
                    trimCollapsedText: LKeys.showMore.tr,
                    trimExpandedText: '  ${LKeys.showLess.tr}',
                    text: metadata.description ?? '',
                    basicStyle:
                        MyTextStyle.gilroyRegular(size: 14, color: cLightText),
                    detectedStyle:
                        MyTextStyle.gilroySemiBold(size: 16, color: cPrimary),
                    detectionRegExp: detectionRegExp(atSign: false, url: true)!,
                  ),
          ],
        ),
      ),
    );
  }

  Widget placeHolder() {
    return Image.asset(MyImages.placeHolderImage,
        width: Get.width - 40, height: 100, fit: BoxFit.cover);
  }
}

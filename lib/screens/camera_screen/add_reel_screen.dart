import 'package:detectable_text_field/detectable_text_field.dart';
import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/widgets/interest_selector.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/add_reel_data.dart';
import 'package:untitled/screens/camera_screen/add_reel_screen_controller.dart';
import 'package:untitled/screens/extra_views/buttons.dart';
import 'package:untitled/screens/extra_views/top_bar.dart';
import 'package:untitled/utilities/const.dart';

class AddReelScreen extends StatelessWidget {
  final AddReelData data;

  const AddReelScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    AddReelScreenController controller =
        Get.put(AddReelScreenController(data: data));
    return Scaffold(
      body: Obx(
        () => Column(
          children: [
            TopBarForInView(
              title: LKeys.addNewReel,
              child: InkWell(
                onTap: controller.uploadReel,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.only(
                      right: 20, left: 20, top: 7, bottom: 5),
                  decoration: BoxDecoration(
                      color: cPrimary,
                      borderRadius: BorderRadius.circular(100)),
                  child: Text(
                    LKeys.post.tr.toUpperCase(),
                    style: MyTextStyle.gilroySemiBold(color: cBlack, size: 14),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      Container(
                        width: 170,
                        height: 250,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipSmoothRect(
                              radius: SmoothBorderRadius(
                                  cornerRadius: 10,
                                  cornerSmoothing: cornerSmoothing),
                              child:
                                  controller.data.value.thumbnailBytes != null
                                      ? Image.memory(
                                          controller.data.value.thumbnailBytes!,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          color: cLightBg,
                                        ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  BlurBgButton(
                                    text: LKeys.preview,
                                    onTap: controller.openPreview,
                                  ),
                                  BlurBgButton(
                                    text: LKeys.changeCover,
                                    onTap: controller.changeCover,
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        margin: const EdgeInsets.all(15),
                        height: 130,
                        decoration: ShapeDecoration(
                            color: cLightBg,
                            shape: SmoothRectangleBorder(
                                borderRadius: SmoothBorderRadius.all(
                                    SmoothRadius(
                                        cornerRadius: 10,
                                        cornerSmoothing: cornerSmoothing)))),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 12),
                        child: DetectableTextField(
                          style:
                              MyTextStyle.outfitLight(size: 18, color: cBlack)
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
                          // onChanged: controller.onTextChanged,
                        ),
                      ),
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
      ),
    );
  }
}

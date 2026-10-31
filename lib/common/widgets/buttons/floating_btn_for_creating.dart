import 'dart:ui';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';

import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/managers/session_manager.dart';
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

  FloatingBtnForCreating(
      {super.key,
      this.onPostBack,
      this.onStoryBack,
      this.onReelBack,
      this.overlayTabBar = false});

  @override
  Widget build(BuildContext context) {
    // When sitting over the floating Liquid Glass tab bar, lift the button so
    // it rests above the bar instead of being hidden behind it.
    final double bottomInset = overlayTabBar
        ? MediaQuery.of(context).padding.bottom + kLiquidNavBarReservedHeight
        : 0.0;
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 14, 14, 14 + bottomInset),
        child: GestureDetector(
          onTap: _openSheet,
          child: CircleAvatar(
            radius: 30,
            backgroundColor: cPrimary,
            child: Image.asset(
              MyImages.quill,
              width: 25,
              height: 25,
            ),
          ),
        ),
      ),
    );
  }

  void _openSheet() {
    showColibriBottomSheet(_CreatingChooseSheet(
      onPostTap: _createPost,
      onReelTap: _createReel,
      onStoryTap: _createStory,
    ));
  }

  void _createStory() {
    showColibriBottomSheet(
            CreateStoryScreen(
              user: SessionManager.shared.getUser() ?? User(),
              shouldShowStory: false,
            ),
            isScrollControlled: true,
            ignoreSafeArea: false)
        .then((value) {
      if (onStoryBack != null) {
        onStoryBack!();
      }
    });
  }

  void _createPost() {
    Get.to(() => AddPostScreen(), opaque: false)?.then((value) {
      if (value is Post) {
        if (onPostBack != null) {
          onPostBack!(value);
        }
      }
    });
  }

  void _createReel() {
    Get.to(() => CreateReelScreen(), opaque: false)?.then((value) {
      if (value is Reel) {
        if (onReelBack != null) {
          onReelBack!(value);
        }
      }
    });
  }
}

class _CreatingChooseSheet extends StatelessWidget {
  final Function() onPostTap;
  final Function() onStoryTap;
  final Function() onReelTap;

  const _CreatingChooseSheet(
      {required this.onPostTap,
      required this.onStoryTap,
      required this.onReelTap});

  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Wrap(
        children: [
          ClipSmoothRect(
            radius: SmoothBorderRadius.vertical(
              top: SmoothRadius(
                  cornerRadius: 30, cornerSmoothing: cornerSmoothing),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: cWhite.withValues(alpha: 0.78),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: SafeArea(
                  child: Column(
                    children: [
                      Container(
                        height: 65,
                        margin: EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              LKeys.upload.tr,
                              style:
                                  MyTextStyle.gilroyRegular(color: cDarkText),
                            ),
                            InkWell(
                              onTap: () {
                                Get.back();
                              },
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    cDarkText.withValues(alpha: 0.08),
                                child: Image.asset(
                                  MyImages.close,
                                  height: 12,
                                  width: 12,
                                  color: cDarkText,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      Container(
                        height: 0.5,
                        width: double.infinity,
                        color: cDarkText.withValues(alpha: 0.1),
                      ),
                      SizedBox(height: 10),
                      _card(
                        imageName: MyImages.feed,
                        title: LKeys.feed,
                        onTap: onPostTap,
                      ),
                      _card(
                        imageName: MyImages.story,
                        title: LKeys.story,
                        onTap: onStoryTap,
                      ),
                      _card(
                        imageName: MyImages.reels,
                        title: LKeys.reels,
                        onTap: onReelTap,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(
      {required String imageName,
      required String title,
      required Function() onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LiquidGlassLens(
        style: const LiquidGlassStyle(
          shape: LiquidGlassShape.squircle(
            cornerRadius: 18,
            clipQuality: LiquidGlassClipQuality.exact,
          ),
          appearance: LiquidGlassAppearance(color: Color(0x33FFFFFF)),
          refraction: LiquidGlassRefraction(
            distortion: 0.1,
            distortionWidth: 22,
            chromaticAberration: 0.003,
          ),
        ),
        child: InkWell(
          onTap: () {
            Get.back();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Image.asset(
                  imageName,
                  width: 26,
                  height: 26,
                  color: cDarkText,
                ),
                const SizedBox(width: 15),
                Text(
                  title.tr,
                  style: MyTextStyle.gilroyMedium(size: 17, color: cDarkText),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

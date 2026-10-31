import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:readmore/readmore.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/reel_model_extension.dart';
import 'package:untitled/screens/extra_views/back_button.dart';
import 'package:untitled/screens/follow_button/follow_button.dart';
import 'package:untitled/screens/reels_screen/reel/reel_page_controller.dart';
import 'package:untitled/screens/tag_screen/tag_controller.dart';
import 'package:untitled/screens/tag_screen/tag_screen.dart';
import 'package:untitled/utilities/const.dart';

class UserInfoAndDescription extends StatelessWidget {
  final ReelController controller;

  const UserInfoAndDescription({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          UserInfoHeader(controller: controller),
          const SizedBox(height: 2),
          UserStats(controller: controller),
          const SizedBox(height: 10),
          ReelDescriptionSection(
            controller: controller,
          ),
        ],
      ),
    );
  }
}

class UserInfoHeader extends StatelessWidget {
  const UserInfoHeader({required this.controller, super.key});

  final ReelController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: InkWell(
            onTap: controller.onProfileTap,
            child: Obx(
              () {
                return Text(
                  controller.reel.value?.user?.username ?? 'unknown',
                  style: MyTextStyle.gilroyBold(color: cWhite, size: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: VerifyIcon(
            user: controller.reel.value?.user,
          ),
        ),
        if (controller.reel.value?.isMyReel == false)
          FollowButton(
            user: controller.reel.value?.user,
            child: (isFollowing) {
              return Opacity(
                opacity: !isFollowing ? 1 : 0,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding: const EdgeInsets.only(
                      top: 6, left: 10, right: 10, bottom: 4),
                  decoration: ShapeDecoration(
                    shape: SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius(cornerRadius: 30),
                      side: BorderSide(color: cWhite.withValues(alpha: 0.3)),
                      borderAlign: BorderAlign.inside,
                    ),
                    color: cWhite.withValues(alpha: 0.05),
                  ),
                  child: Text(
                    isFollowing ? LKeys.unFollow.tr : LKeys.follow.tr,
                    style: MyTextStyle.gilroyRegular(size: 13, color: cWhite),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class UserStats extends StatelessWidget {
  const UserStats({super.key, required this.controller});

  final ReelController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          DateFormat('dd MMM yyyy')
              .format(controller.reel.value?.createdAt ?? DateTime.now()),
          style: MyTextStyle.outfitLight(
              color: cWhite.withValues(alpha: 0.8), size: 11),
        ),
        Container(
          height: 3,
          width: 3,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: cWhite.withValues(alpha: 0.8),
            shape: BoxShape.circle,
          ),
        ),
        Text(
          '${controller.reel.value?.viewsCount ?? '1'} ${LKeys.views.tr}',
          style: MyTextStyle.outfitLight(
            color: cWhite.withValues(alpha: 0.8),
            size: 11,
          ),
        ),
      ],
    );
  }
}

class ReelDescriptionSection extends StatelessWidget {
  const ReelDescriptionSection({super.key, required this.controller});

  final ReelController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.reel.value?.description == null ||
        (controller.reel.value?.description ?? '').isEmpty) {
      return const SizedBox();
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: SingleChildScrollView(
        child: ReadMoreText(
          controller.reel.value?.description ?? '',
          style: MyTextStyle.outfitLight(
                  color: cWhite.withValues(alpha: 0.8), size: 15)
              .copyWith(height: 1.4),
          annotations: [
            Annotation(
              regExp: RegExp(r'#([a-zA-Z0-9_]+)'),
              spanBuilder: ({required String text, TextStyle? textStyle}) =>
                  TextSpan(
                      text: text,
                      style: textStyle?.copyWith(
                        color: cPrimary,
                        fontFamily: MyTextStyle.gilroyMedium().fontFamily,
                        fontSize: 15,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          if (text.startsWith('#')) {
                            Get.delete<TagController>().then((value) {
                              Get.to(
                                  () => TagScreen(tag: text, isForReel: true),
                                  preventDuplicates: false,
                                  opaque: false);
                            });
                          }
                          // await Get.to(() => HashtagScreen(hashtag: text), preventDuplicates: false);
                        }),
            ),
          ],
          trimMode: TrimMode.Line,
          trimLines: 3,
          trimCollapsedText: ' ${LKeys.showMore.tr}',
          trimExpandedText: '   ${LKeys.showLess.tr}',
          moreStyle: MyTextStyle.outfitLight(
              color: cWhite.withValues(alpha: 0.8), size: 15),
          lessStyle: MyTextStyle.outfitLight(
              color: cWhite.withValues(alpha: 0.8), size: 15),
        ),
      ),
    );
  }
}

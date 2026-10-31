import 'dart:convert';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';

import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:like_button/like_button.dart';
import 'package:readmore/readmore.dart';
import 'package:untitled/common/extensions/date_time_extension.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/extensions/int_extension.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/widgets/buttons/play_button.dart';
import 'package:untitled/common/widgets/menu.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/posts_model.dart';
import 'package:untitled/screens/add_post_screen/add_post_controller.dart';
import 'package:untitled/screens/add_post_screen/add_post_screen.dart';
import 'package:untitled/screens/add_post_screen/record_audio/record_audio_screen.dart';
import 'package:untitled/screens/extra_views/back_button.dart';
import 'package:untitled/screens/post/comment/comment_screen.dart';
import 'package:untitled/screens/post/post_controller.dart';
import 'package:untitled/screens/profile_screen/profile_screen.dart';
import 'package:untitled/screens/tag_screen/tag_screen.dart';
import 'package:untitled/utilities/const.dart';
import 'package:zoom_pinch_overlay/zoom_pinch_overlay.dart';

import '../tag_screen/tag_controller.dart';
import 'double_click_like.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final Function(int postID) onDeletePost;
  final Function() refreshView;

  const PostCard(
      {super.key,
      required this.post,
      required this.onDeletePost,
      required this.refreshView});

  @override
  Widget build(BuildContext context) {
    final PostController controller =
        PostController(post, onDeletePost, refreshView);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: PostTopBar(controller: controller),
        ),
        const SizedBox(
          height: 7,
        ),
        (controller.post.desc != "" && controller.post.desc != null)
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: PostDescriptionView(controller: controller),
              )
            : const SizedBox(height: 5),
        if (controller.post.content?.isNotEmpty == true)
          (controller.post.type == PostType.audio)
              ? contentView(controller)
              : (controller.post.type == PostType.image ||
                      controller.post.type == PostType.video)
                  ? DoubleClickLikeAnimator(
                      child: contentView(controller),
                      onAnimation: () {
                        if (controller.post.isLike == 0) {
                          controller.likeFromDoubleTap();
                        }
                      },
                      onTap: () {
                        controller.openVideoSheet();
                      },
                    )
                  : Container()
        else if (controller.post.linkPreview != null)
          UrlMetaDataCard(metadata: controller.post.linkPreview!)
        else
          const Column(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: PostBottomBar(controller: controller),
        ),
        const Divider(
          thickness: 0.2,
        ),
      ],
    );
  }

  Widget contentView(PostController controller) {
    switch (controller.post.type) {
      case PostType.image:
        return PostImagesPageView(controller: controller);
      case PostType.video:
        return PostVideoElement(controller: controller);
      case PostType.audio:
        return PostAudioElement(controller: controller);
      case PostType.text:
        return Container();
    }
  }
}

class PostDescriptionView extends StatelessWidget {
  final PostController controller;
  final bool isForVideo;

  const PostDescriptionView(
      {Key? key, required this.controller, this.isForVideo = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      child: ReadMoreText(
        controller.post.desc ?? '',
        style: MyTextStyle.outfitLight(
            size: 16, color: isForVideo ? cLightIcon : cMainText),
        annotations: [
          Annotation(
            regExp: RegExp(r'#([a-zA-Z0-9_]+)'),
            spanBuilder: ({required String text, TextStyle? textStyle}) =>
                TextSpan(
                    text: text,
                    style: textStyle?.copyWith(
                      color: cPrimary,
                      fontFamily: MyTextStyle.outfitMedium(
                              size: 16, color: cHashtagColor)
                          .fontFamily,
                      fontSize: 16,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        if (text.startsWith('#')) {
                          Get.delete<TagController>().then((value) {
                            Get.to(
                                () => TagScreen(
                                      tag: text,
                                      isForReel: false,
                                    ),
                                preventDuplicates: false,
                                opaque: false);
                          });
                        }
                      }),
          ),
        ],
        trimMode: TrimMode.Line,
        trimLines: 5,
        trimCollapsedText: ' ${LKeys.showMore.tr}',
        trimExpandedText: '   ${LKeys.showLess.tr}',
        moreStyle: MyTextStyle.outfitRegular(
            color: isForVideo ? cLightIcon : cMainText, size: 16),
        lessStyle: MyTextStyle.outfitRegular(
            color: isForVideo ? cLightIcon : cMainText, size: 16),
      ),
    );
  }
}

class PostBottomBar extends StatelessWidget {
  final PostController controller;
  final bool isForVideo;

  const PostBottomBar(
      {Key? key, required this.controller, this.isForVideo = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 6),
      child: Row(
        children: [
          GetBuilder(
              init: controller,
              tag: "${controller.post.id}",
              id: 'comment',
              builder: (context) {
                return GestureDetector(
                  onTap: () {
                    showColibriBottomSheet(
                      CommentScreen(postController: controller),
                      isScrollControlled: true,
                      ignoreSafeArea: false,
                    ).then((value) {
                      controller.update(['comment']);
                      controller.update();
                      controller.refreshView();
                    });
                  },
                  child: Row(
                    children: [
                      Image.asset(
                        MyImages.comment,
                        width: 20,
                        height: 20,
                        color: isForVideo ? cWhite : cDarkText,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Text(
                        (controller.post.commentsCount).makeToString(),
                        style: MyTextStyle.gilroyRegular(
                            size: 14, color: isForVideo ? cWhite : cDarkText),
                      ),
                    ],
                  ),
                );
              }),
          const SizedBox(
            width: 15,
          ),
          Obx(
            () => LikeButton(
              onTap: (isLiked) async {
                this.controller.toggleFav();
                return true;
              },
              countPostion: CountPostion.right,
              likeCount: this.controller.post.likesCount ?? 0,
              size: 21,
              isLiked: controller.isLiked.value,
              likeCountPadding: const EdgeInsets.symmetric(horizontal: 4),
              countBuilder: (likeCount, isLiked, text) {
                return Text(
                  text,
                  style: MyTextStyle.gilroyRegular(
                      size: 14, color: isForVideo ? cWhite : cDarkText),
                );
              },
              likeBuilder: (isLiked) {
                return Image.asset(
                  this.controller.isLiked.value
                      ? MyImages.heartFill
                      : MyImages.heart,
                  width: 21,
                  height: 21,
                  color: this.controller.isLiked.value
                      ? cRed
                      : isForVideo
                          ? cWhite
                          : cDarkText,
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class PostTopBar extends StatelessWidget {
  final PostController controller;
  final bool isForVideo;

  const PostTopBar(
      {Key? key, required this.controller, this.isForVideo = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.to(() => ProfileScreen(userId: controller.post.userId ?? 0),
            preventDuplicates: false, opaque: false);
      },
      child: Row(
        children: [
          MyCachedProfileImage(
            imageUrl: controller.post.user?.profile,
            width: 45,
            height: 45,
            fullName: controller.post.user?.fullName,
            cornerRadius: 15,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              controller.post.user?.fullName ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: MyTextStyle.gilroyBold(
                                  color: isForVideo ? cWhite : cBlack,
                                  size: 17),
                            ),
                          ),
                          VerifyIcon(user: controller.post.user),
                          const SizedBox(
                            width: 5,
                          )
                        ],
                      ),
                    ),

                    // const Spacer(),
                    Text(
                      controller.post.date.timeAgo(),
                      style: MyTextStyle.gilroyLight(
                          size: 14,
                          color: (isForVideo ? cLightIcon : cLightText)),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    PostMenuButton(
                      controller: controller,
                      isForVideo: isForVideo,
                    ),
                    SizedBox(width: isForVideo ? 10 : 0),
                    isForVideo ? const XMarkButton() : Container()
                  ],
                ),
                Text(
                  "@${controller.post.user?.username ?? ""}",
                  style: MyTextStyle.gilroyLight(
                      size: 16, color: isForVideo ? cWhite : cLightText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PostMenuButton extends StatelessWidget {
  final PostController controller;
  final bool isForVideo;

  const PostMenuButton(
      {Key? key, required this.controller, required this.isForVideo})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = <LiquidGlassMenuItem>[
      if (SessionManager.shared.getUserID() == controller.post.userId)
        LiquidGlassMenuItem(
          label: LKeys.seeWhoLikedPost.tr,
          onTap: controller.showWhoLikedThePost,
        ),
      LiquidGlassMenuItem(
        label: controller.post.userId == SessionManager.shared.getUserID()
            ? LKeys.delete.tr
            : LKeys.report.tr,
        onTap: controller.deleteOrReport,
      ),
      if (SessionManager.shared.getUserID() != controller.post.userId &&
          SessionManager.shared.getUser()?.isModerator == 1)
        LiquidGlassMenuItem(
          label: LKeys.delete.tr,
          onTap: controller.deletePosyByModerator,
        ),
      LiquidGlassMenuItem(
        label: LKeys.share.tr,
        onTap: controller.sharePost,
      ),
    ];
    return LiquidGlassMenu(
      trigger: Icon(
        Icons.more_horiz,
        color: isForVideo ? cLightIcon : cLightText,
      ),
      items: items,
    );
  }
}

class PostImagesPageView extends StatelessWidget {
  final PostController controller;

  const PostImagesPageView({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (controller.post.content?.isNotEmpty == true) {
      var height = controller.post.content?.length == 1 ? null : Get.width;
      return GetBuilder<PostController>(
          init: controller,
          tag: "${controller.post.id}",
          id: "pageView",
          builder: (control) {
            var contentCount = controller.post.content?.length ?? 0;
            return contentCount == 1
                ? image(
                    imageUrl: controller.post.content?.first.content,
                    height: height)
                : SizedBox(
                    height: Get.width,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        PageView.builder(
                          onPageChanged: (value) => control.onPageChange(value),
                          itemCount: controller.post.content?.length,
                          itemBuilder: (context, index) {
                            return image(
                                imageUrl:
                                    (controller.post.content?[index].content ??
                                        ''),
                                height: height);
                          },
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(contentCount, (index) {
                              return contentCount > 1
                                  ? Container(
                                      margin: const EdgeInsets.only(right: 3),
                                      height: 2.7,
                                      width: contentCount > 8
                                          ? (Get.width - 120) / contentCount
                                          : 30,
                                      decoration: ShapeDecoration(
                                        color: control.selectedImageIndex ==
                                                index
                                            ? cWhite
                                            : cWhite.withValues(alpha: 0.30),
                                        shape: const SmoothRectangleBorder(
                                            borderRadius:
                                                SmoothBorderRadius.all(
                                                    SmoothRadius(
                                                        cornerRadius: 10,
                                                        cornerSmoothing:
                                                            cornerSmoothing))),
                                      ),
                                    )
                                  : Container();
                            }),
                          ),
                        ),
                      ],
                    ),
                  );
          });
    } else {
      return Container();
    }
  }

  Widget image({String? imageUrl, double? height}) {
    return ZoomOverlay(
      modalBarrierColor: Colors.black.withValues(alpha: 0.5),
      minScale: 1,
      maxScale: 3.0,
      animationCurve: Curves.fastOutSlowIn,
      animationDuration: const Duration(milliseconds: 300),
      twoTouchOnly: true,
      child: ClipRRect(
        child: Container(
          constraints: BoxConstraints(maxHeight: Get.height / 1.5),
          child: FadeInImage(
              placeholder: AssetImage(
                MyImages.placeHolderImage,
              ),
              image: NetworkImage(imageUrl?.addBaseURL() ?? ''),
              imageErrorBuilder: (context, error, stackTrace) {
                return Image.asset(MyImages.placeHolderImage,
                    height: Get.width);
              },
              width: Get.width,
              repeat: ImageRepeat.noRepeat,
              height: height,
              fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class PostVideoElement extends StatelessWidget {
  final PostController controller;

  const PostVideoElement({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (controller.post.content?.isEmpty == true) {
      return Container();
    }
    return GestureDetector(
      onTap: () {
        controller.openVideoSheet();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: Get.width,
            width: double.infinity,
            child: MyCachedImage(
              imageUrl: (controller.post.content?.first.thumbnail ?? ""),
            ),
          ),
          PlayButton(),
        ],
      ),
    );
  }
}

class PostAudioElement extends StatelessWidget {
  final PostController controller;

  const PostAudioElement({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<double> waves =
        (jsonDecode(controller.post.content?.first.audioWaves ?? "")
                as List<dynamic>)
            .map((e) => e as double)
            .toList();
    if (controller.post.content?.isEmpty == true) {
      return Container();
    }
    return GestureDetector(
        onTap: () {
          controller.openAudioSheet();
        },
        child: WaveCard(waves: waves));
  }
}

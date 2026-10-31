import 'package:detectable_text_field/detectable_text_field.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/story_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/chat.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/screens/chats_screen/chatting_screen/chatting_controller.dart';
import 'package:untitled/screens/chats_screen/chatting_screen/content_full_screen.dart';
import 'package:untitled/screens/extra_views/back_button.dart';
import 'package:untitled/screens/profile_screen/profile_screen.dart';
import 'package:untitled/screens/story_screen/story_screen.dart';
import 'package:untitled/utilities/const.dart';
import 'package:untitled/utilities/firebase_const.dart';

class ChatTag extends StatelessWidget {
  final ChattingController controller;
  final int index;
  final ChatMessage message;
  final bool isFromRoom;

  const ChatTag(
      {Key? key,
      required this.index,
      required this.message,
      this.isFromRoom = false,
      required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var isMyMsg = message.senderId == SessionManager.shared.getUserID();
    return Row(
      mainAxisAlignment:
          isMyMsg ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        isMyMsg ? const Spacer() : Container(),
        Column(
          crossAxisAlignment:
              isMyMsg ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            commonChooseView(),
            Text(
              message.getChatTime(),
              style: MyTextStyle.gilroyRegular(size: 12, color: cLightText),
            ),
            const SizedBox(
              height: 10,
            )
          ],
        ),
        !isMyMsg ? const Spacer() : Container(),
      ],
    );
  }

  Widget storyView() {
    bool isEmojiText = isSingleEmoji(message.msg ?? '');
    var isMyMsg = message.senderId == SessionManager.shared.getUserID();
    var isStoryDeleted = message.thumbnail == null || message.thumbnail == "";
    bool shouldShowReaction = isEmojiText || isStoryDeleted;
    double emojiSize = shouldShowReaction ? 50 : 0;
    return Column(
      crossAxisAlignment:
          isMyMsg ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMyMsg) storyDivider(isStoryDeleted, isMyMsg),
            isStoryDeleted
                ? Text(
                    LKeys.storyHasBeenDeleted.tr,
                    style: MyTextStyle.gilroyRegular(color: cLightText),
                  )
                : Container(
                    width: (Get.width * 0.5) / 1.65 + (emojiSize / 2),
                    height: (Get.width * 0.5) + (emojiSize / 2),
                    child: Stack(
                      alignment:
                          isMyMsg ? Alignment.topRight : Alignment.topLeft,
                      children: [
                        Container(
                          constraints:
                              BoxConstraints(maxWidth: Get.width * 0.6),
                          padding: EdgeInsets.all(1.5),
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          decoration: ShapeDecoration(
                            color: cBlack,
                            shape: const SmoothRectangleBorder(
                                borderRadius: SmoothBorderRadius.all(
                              SmoothRadius(
                                  cornerRadius: 6.5,
                                  cornerSmoothing: cornerSmoothing),
                            )),
                          ),
                          child: ClipSmoothRect(
                            radius: SmoothBorderRadius.all(SmoothRadius(
                                cornerRadius: 5,
                                cornerSmoothing: cornerSmoothing)),
                            child: GestureDetector(
                              onTap: () {
                                BaseController.share.startLoading();
                                StoryService.shared.fetchStoryById(
                                  storyId: (message.storyId ?? 0).toInt(),
                                  completion: (story) {
                                    BaseController.share.stopLoading();
                                    if (story != null) {
                                      var user = story.user ?? User();
                                      user.stories = [story];
                                      showColibriBottomSheet(
                                          StoryScreen(users: [user], index: 0),
                                          ignoreSafeArea: false,
                                          isScrollControlled: true);
                                    } else {
                                      controller.removeStoryFromMessage(
                                          message: message);
                                    }
                                  },
                                );
                              },
                              child: MyCachedImage(
                                imageUrl: message.thumbnail,
                                height: Get.width * 0.5,
                                width: (Get.width * 0.5) / 1.65,
                              ),
                            ),
                          ),
                        ),
                        if (shouldShowReaction)
                          Positioned(
                            bottom: 0,
                            left: isMyMsg ? 0 : null,
                            right: !isMyMsg ? 0 : null,
                            child: Container(
                              child: Text(
                                message.msg ?? '',
                                style: TextStyle(
                                  fontSize: emojiSize,
                                  color: cBlack,
                                  shadows: <Shadow>[
                                    Shadow(
                                      blurRadius: 10,
                                      color: cBlack.withValues(alpha: 0.3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                      ],
                    ),
                  ),
            if (isMyMsg) storyDivider(isStoryDeleted, isMyMsg)
          ],
        ),
        ((message.msg ?? '').isNotEmpty && !shouldShowReaction)
            ? Container(
                padding: EdgeInsets.all(8),
                margin: const EdgeInsets.symmetric(vertical: 3),
                decoration: ShapeDecoration(
                  color: isMyMsg ? cBlack : cLightText.withValues(alpha: 0.15),
                  shape: const SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius.all(SmoothRadius(
                          cornerRadius: 8, cornerSmoothing: cornerSmoothing))),
                ),
                child: Text(
                  message.msg ?? '',
                  style: MyTextStyle.gilroyRegular(
                      size: 16, color: isMyMsg ? cWhite : cBlack),
                ),
              )
            : Container()
      ],
    );
  }

  Widget storyDivider(bool isStoryDeleted, bool isMyMsg) {
    return Container(
      constraints: BoxConstraints(maxWidth: Get.width * 0.6),
      height: isStoryDeleted ? 20 : Get.width * 0.5,
      width: 3,
      margin: EdgeInsets.only(
          right: isMyMsg ? 0 : 5, left: isMyMsg ? 5 : 0, top: 4.5),
      decoration: ShapeDecoration(
        color: cLightText.withValues(alpha: 0.3),
        shape: const SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius.all(SmoothRadius(
                cornerRadius: 8, cornerSmoothing: cornerSmoothing))),
      ),
    );
  }

  bool isSingleEmoji(String input) {
    // Check if the string has exactly one character
    if (input.runes.length != 1) {
      return false;
    }

    // Regular expression to match emojis
    final emojiRegex = RegExp(
        r'[\u{1F600}-\u{1F64F}' // Emoticons
        r'\u{1F300}-\u{1F5FF}' // Symbols & Pictographs
        r'\u{1F680}-\u{1F6FF}' // Transport & Map Symbols
        r'\u{1F700}-\u{1F77F}' // Alchemical Symbols
        r'\u{1F780}-\u{1F7FF}' // Geometric Shapes Extended
        r'\u{1F800}-\u{1F8FF}' // Supplemental Arrows-C
        r'\u{1F900}-\u{1F9FF}' // Supplemental Symbols and Pictographs
        r'\u{1FA00}-\u{1FA6F}' // Chess Symbols
        r'\u{1FA70}-\u{1FAFF}' // Symbols and Pictographs Extended-A
        r'\u{2600}-\u{26FF}' // Miscellaneous Symbols
        r'\u{2700}-\u{27BF}' // Dingbats
        r'\u{1F1E6}-\u{1F1FF}' // Regional Indicator Symbols
        r'\u{1F900}-\u{1F9FF}]', // Supplemental Symbols and Pictographs
        unicode: true);

    // Test the single character against the emoji regex
    return emojiRegex.hasMatch(input);
  }

  Widget imageAndVideoView() {
    var isMyMsg = message.senderId == SessionManager.shared.getUserID();
    return Container(
      constraints: BoxConstraints(maxWidth: Get.width * 0.6),
      padding: EdgeInsets.all(5),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: ShapeDecoration(
        color: isMyMsg ? cBlack : cLightText.withValues(alpha: 0.15),
        shape: const SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius.all(SmoothRadius(
                cornerRadius: 10, cornerSmoothing: cornerSmoothing))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          remoteUserNameView(verticalPadding: 3, horizontalPadding: 5),
          ClipSmoothRect(
            radius: const SmoothBorderRadius.all(SmoothRadius(
                cornerRadius: 5, cornerSmoothing: cornerSmoothing)),
            child: Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    showColibriBottomSheet(ContentFullScreen(message: message),
                        ignoreSafeArea: false, isScrollControlled: true);
                  },
                  child: MyCachedImage(
                    imageUrl: message.msgType == MessageType.video
                        ? message.thumbnail
                        : message.content,
                    width: Get.width * 0.6,
                    height: Get.width * 0.6,
                  ),
                ),
                message.msgType == MessageType.video
                    ? const CircleAvatar(
                        radius: 13,
                        backgroundColor: cPrimary,
                        foregroundColor: cBlack,
                        child: Icon(Icons.play_arrow_rounded, size: 20),
                      )
                    : Container(width: 0),
              ],
            ),
          ),
          (message.msg ?? '') != ''
              ? textView(padding: 3, showBgColor: false)
              : Container(width: 0),
        ],
      ),
    );
  }

  Widget remoteUserNameView(
      {double? verticalPadding, double? horizontalPadding}) {
    var isMyMsg = message.senderId == SessionManager.shared.getUserID();
    var user = controller.room?.roomUsers?.firstWhere(
      (element) => element.id == message.senderId,
      orElse: () => User(fullName: 'Unknown'),
    );
    if (!isMyMsg && isFromRoom) {
      return Padding(
        padding: EdgeInsets.symmetric(
            vertical: verticalPadding ?? 0, horizontal: horizontalPadding ?? 0),
        child: Column(
          children: [
            FittedBox(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (user?.id != null && user?.id != 0) {
                        Get.to(() => ProfileScreen(userId: user?.id ?? 0),
                            opaque: false);
                      }
                    },
                    child: Text(
                      user?.fullName ?? '',
                      style: MyTextStyle.gilroyBold(color: cBlack),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const VerifyIcon()
                ],
              ),
            ),
            const SizedBox(height: 2),
          ],
        ),
      );
    } else {
      return const Column();
    }
  }

  Widget textView({double? padding, bool showBgColor = true}) {
    var isMyMsg = message.senderId == SessionManager.shared.getUserID();
    return Container(
      constraints: BoxConstraints(maxWidth: Get.width * 0.6),
      padding: EdgeInsets.all(padding ?? 10),
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: ShapeDecoration(
        color: showBgColor
            ? isMyMsg
                ? cBlack
                : cLightText.withValues(alpha: 0.15)
            : Colors.transparent,
        shape: const SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius.all(SmoothRadius(
                cornerRadius: 10, cornerSmoothing: cornerSmoothing))),
      ),
      // child: Text(
      //   message.msg ?? '',
      //   style: MyTextStyle.gilroyRegular(size: 16, color: isMyMsg ? cWhite : cBlack),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          padding == null ? remoteUserNameView() : Container(),
          DetectableText(
            maxLines: null,
            detectionRegExp: detectionRegExp(atSign: false, url: true)!,
            onTap: (p0) async {
              controller.handleURL(url: p0);
            },
            lessStyle: MyTextStyle.gilroyMedium(color: cPrimary),
            moreStyle: MyTextStyle.gilroyMedium(color: cPrimary),
            trimCollapsedText: LKeys.showMore.tr,
            trimExpandedText: '  ${LKeys.showLess.tr}',
            text: message.msg ?? '',
            basicStyle: MyTextStyle.gilroyRegular(
                size: 16, color: isMyMsg ? cWhite : cBlack),
            detectedStyle:
                MyTextStyle.gilroySemiBold(size: 16, color: cPrimary),
            // )
          ),
        ],
      ),
    );
  }

  Widget commonChooseView() {
    switch (message.msgType) {
      case MessageType.text:
        return textView();
      case MessageType.image:
        return imageAndVideoView();
      case MessageType.video:
        return imageAndVideoView();
      case MessageType.storyReply:
        return storyView();
    }
  }
}

class ChatButton extends StatelessWidget {
  final String title;
  final Color color;
  final Function()? onTap;

  const ChatButton(
      {Key? key, required this.title, required this.color, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 30),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(100)),
        child: Text(
          title.tr,
          style: MyTextStyle.gilroySemiBold(color: color),
        ),
      ),
    );
  }
}

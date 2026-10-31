import 'package:dismissible_page/dismissible_page.dart';
import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/duration_extension.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/models/chat.dart';
import 'package:untitled/screens/post/post_card.dart';
import 'package:untitled/screens/post/post_controller.dart';
import 'package:untitled/utilities/const.dart';
import 'package:untitled/utilities/firebase_const.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerSheet extends StatefulWidget {
  final PostController controller;

  VideoPlayerSheet({Key? key, required this.controller}) : super(key: key);

  @override
  State<VideoPlayerSheet> createState() => _VideoPlayerSheetState();
}

class _VideoPlayerSheetState extends State<VideoPlayerSheet> {
  VideoPlayerController? playerController;
  bool isLoading = true;

  @override
  void initState() {
    initPlayer();
    super.initState();
  }

  @override
  void dispose() {
    playerController?.pause();
    playerController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const ShapeDecoration(
        color: cBlackSheetBG,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius.only(
            topLeft: SmoothRadius(
                cornerRadius: 20, cornerSmoothing: cornerSmoothing),
            topRight: SmoothRadius(
                cornerRadius: 20, cornerSmoothing: cornerSmoothing),
          ),
        ),
      ),
      margin: EdgeInsets.only(top: Get.statusBarHeight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.only(top: 20, bottom: 0, right: 20, left: 20),
            child: PostTopBar(
              controller: widget.controller,
              isForVideo: true,
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: PostDescriptionView(
                          controller: widget.controller, isForVideo: true),
                    ),
                    if (playerController != null)
                      Container(
                        width: Get.width,
                        height: Get.width,
                        color: cWhite.withValues(alpha: 0.1),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            GestureDetector(
                              onTap: playPause,
                              child: Hero(
                                tag: 'player',
                                transitionOnUserGestures: true,
                                child: AspectRatio(
                                  aspectRatio:
                                      playerController!.value.aspectRatio,
                                  child: VideoPlayer(playerController!),
                                ),
                              ),
                            ),
                            playerController != null &&
                                    playerController!.value.isInitialized &&
                                    !isLoading
                                ? ValueListenableBuilder(
                                    valueListenable: playerController!,
                                    builder: (context, VideoPlayerValue value,
                                            child) =>
                                        Column(
                                      children: [
                                        Row(
                                          children: [
                                            const Spacer(),
                                            GestureDetector(
                                              onTap: () {
                                                context.pushTransparentRoute(
                                                  ContentFullScreenForPost(
                                                    message: ChatMessage(
                                                        content: widget
                                                                .controller
                                                                .post
                                                                .content
                                                                ?.first
                                                                .content ??
                                                            '',
                                                        msgType: 'VIDEO'),
                                                    playerController:
                                                        playerController,
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                decoration: ShapeDecoration(
                                                  shape: const SmoothRectangleBorder(
                                                      borderRadius: SmoothBorderRadius
                                                          .all(SmoothRadius(
                                                              cornerRadius: 5,
                                                              cornerSmoothing:
                                                                  cornerSmoothing))),
                                                  color: cBlack.withValues(
                                                      alpha: 0.4),
                                                ),
                                                margin:
                                                    const EdgeInsets.all(10),
                                                padding:
                                                    const EdgeInsets.all(4),
                                                child: const Icon(
                                                    Icons.fullscreen_rounded,
                                                    color: cWhite),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Spacer(),
                                        value.isPlaying == true
                                            ? Container()
                                            : GestureDetector(
                                                onTap: playPause,
                                                child: CircleAvatar(
                                                  backgroundColor: cBlack
                                                      .withValues(alpha: 0.4),
                                                  foregroundColor: cWhite,
                                                  child: const Icon(
                                                    Icons.play_arrow_rounded,
                                                    size: 30,
                                                  ),
                                                ),
                                              ),
                                        const Spacer(),
                                        VideoSlider(
                                            controller: playerController,
                                            onChange: onChange),
                                      ],
                                    ),
                                  )
                                : SizedBox(height: Get.width)
                          ],
                        ),
                      )
                    else
                      Container(
                        width: Get.width,
                        height: Get.width,
                        color: cWhite.withValues(alpha: 0.1),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: cPrimary,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: PostBottomBar(
                          controller: widget.controller, isForVideo: true),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void initPlayer() {
    playerController = VideoPlayerController.networkUrl(Uri.parse(
        widget.controller.post.content?.first.content?.addBaseURL() ?? ''))
      ..initialize().then((value) {
        if (Get.isBottomSheetOpen == true) {
          play();
        }
        isLoading = false;
        setState(() {});
      });
    setState(() {});
  }

  void play() {
    playerController?.play();
  }

  void playPause() {
    if (playerController?.value.isPlaying == true) {
      playerController?.pause();
    } else {
      playerController?.play();
    }
  }

  void onChange(double value) {
    playerController?.seekTo(Duration(milliseconds: value.toInt()));
  }
}

class VideoSlider extends StatelessWidget {
  final VideoPlayerController? controller;
  final Function(double) onChange;

  const VideoSlider(
      {Key? key, required this.controller, required this.onChange})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        shape: const SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius.all(SmoothRadius(
                cornerRadius: 5, cornerSmoothing: cornerSmoothing))),
        color: cBlack.withValues(alpha: 0.4),
      ),
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(7),
      child: Row(
        children: [
          Text(
            controller?.value.position.toStringTime() ?? "",
            style: MyTextStyle.gilroyRegular(color: cWhite, size: 14),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: SliderTheme(
              data: const SliderThemeData().copyWith(
                  trackHeight: 1, overlayShape: SliderComponentShape.noThumb),
              child: Slider(
                label: "",
                thumbColor: cPrimary,
                activeColor: cWhite,
                inactiveColor: cWhite.withValues(alpha: 0.4),
                value:
                    controller?.value.position.inMilliseconds.toDouble() ?? 0,
                max: controller?.value.duration.inMilliseconds.toDouble() ?? 0,
                onChanged: (value) {
                  onChange(value);
                },
              ),
            ),
          ),
          Text(
            controller?.value.duration.toStringTime() ?? "",
            style: MyTextStyle.gilroyRegular(color: cWhite, size: 14),
          ),
        ],
      ),
    );
  }
}

class ContentFullScreenForPost extends StatefulWidget {
  final ChatMessage message;
  final VideoPlayerController? playerController;

  const ContentFullScreenForPost(
      {super.key, required this.message, this.playerController});

  @override
  State<ContentFullScreenForPost> createState() => _ContentFullScreenForPost();
}

class _ContentFullScreenForPost extends State<ContentFullScreenForPost> {
  VideoPlayerController? controller;

  @override
  void initState() {
    var msgType = widget.message.msgType == 'TEXT'
        ? MessageType.text
        : (widget.message.msgType == 'IMAGE'
            ? MessageType.image
            : MessageType.video);
    if (msgType == MessageType.video) {
      if (widget.playerController == null) {
        controller = VideoPlayerController.networkUrl(
            Uri.parse(widget.message.content?.addBaseURL() ?? ''))
          ..initialize().then((value) {
            controller?.play();
            setState(() {});
          });
      } else {
        controller = widget.playerController;
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DismissiblePage(
      onDismissed: () {
        Navigator.of(context).pop();
      },
      isFullScreen: true,
      backgroundColor: Colors.transparent,
      // Note that scrollable widget inside DismissiblePage might limit the functionality
      // If scroll direction matches DismissiblePage direction
      direction: DismissiblePageDismissDirection.multi,
      child: Scaffold(
        body: Container(
          color: cBlack,
          child: SafeArea(
            top: true,
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                Center(
                    child: Stack(
                  alignment: Alignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (controller!.value.isPlaying) {
                          controller?.pause();
                        } else {
                          controller?.play();
                        }
                      },
                      child: controller != null
                          ? Hero(
                              tag: 'player',
                              child: AspectRatio(
                                aspectRatio: controller!.value.aspectRatio,
                                child: VideoPlayer(controller!),
                              ),
                            )
                          : null,
                    ),
                    ValueListenableBuilder(
                      valueListenable: controller!,
                      builder: (context, VideoPlayerValue value, child) {
                        return Column(
                          children: [
                            const SizedBox(height: 50),
                            const Spacer(),
                            value.isPlaying == true
                                ? Container()
                                : GestureDetector(
                                    onTap: () {
                                      if (value.isPlaying) {
                                        controller?.pause();
                                      } else {
                                        controller?.play();
                                      }
                                    },
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
                                controller: controller, onChange: onChange),
                          ],
                        );
                      },
                    )
                  ],
                )),
                Container(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Get.back();
                        },
                        child: CircleAvatar(
                          backgroundColor: cLightBg.withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.close_rounded,
                            color: cLightText,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void onChange(double value) {
    controller?.seekTo(Duration(milliseconds: value.toInt()));
  }

  @override
  void dispose() {
    if (widget.playerController == null) {
      controller?.dispose();
    }
    super.dispose();
  }
}

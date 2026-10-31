import 'dart:convert';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:untitled/screens/add_post_screen/record_audio/record_audio_screen.dart';
import 'package:untitled/screens/post/post_card.dart';
import 'package:untitled/screens/post/post_controller.dart';
import 'package:untitled/utilities/const.dart';

class AudioPlayerSheet extends StatefulWidget {
  final PostController controller;

  AudioPlayerSheet({Key? key, required this.controller}) : super(key: key);

  @override
  State<AudioPlayerSheet> createState() => _AudioPlayerSheetState();
}

class _AudioPlayerSheetState extends State<AudioPlayerSheet> {
  PlayerController? audioPlayerController;

  @override
  void initState() {
    loadAudio();
    super.initState();
  }

  @override
  void dispose() {
    audioPlayerController?.pausePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<double> waves =
        (jsonDecode(widget.controller.post.content?.first.audioWaves ?? "")
                as List<dynamic>)
            .map((e) => e as double)
            .toList();

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
      child: Wrap(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      top: 20, bottom: 0, right: 20, left: 20),
                  child: PostTopBar(
                    controller: widget.controller,
                    isForVideo: true,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: PostDescriptionView(
                      controller: widget.controller, isForVideo: true),
                ),
                audioPlayerController != null ||
                        audioPlayerController?.playerState.isInitialised == true
                    ? AudioWavePlayerCard(
                        playerController: audioPlayerController!,
                        color: cWhite,
                      )
                    : WaveCard(
                        waves: waves,
                        showLoader: true,
                        color: cWhite,
                      ),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 20, right: 20, bottom: 40),
                  child: PostBottomBar(
                      controller: widget.controller, isForVideo: true),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void loadAudio() async {
    if (audioPlayerController == null) {
      DefaultCacheManager()
          .getSingleFile(widget.controller.post.content?.first.content ?? '')
          .then((value) async {
        audioPlayerController = PlayerController();
        await audioPlayerController?.preparePlayer(
            path: value.path,
            noOfSamples: playerWaveStyle.getSamplesForWidth(audioSize.width));
        if (Get.isBottomSheetOpen == true) {
          await audioPlayerController?.startPlayer();
          audioPlayerController?.setFinishMode(finishMode: FinishMode.pause);
        }
        setState(() {});
      });
    } else {
      await audioPlayerController?.startPlayer();
      audioPlayerController?.setFinishMode(finishMode: FinishMode.pause);
    }
  }
}

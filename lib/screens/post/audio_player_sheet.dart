import 'dart:convert';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
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

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: ColibriSheetSurface(
        backgroundColor: cBlackSheetBG,
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ColibriSheetHeader(
              foregroundColor: cWhite,
              handleColor: cWhite.withValues(alpha: 0.35),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 12, bottom: 0, right: 20, left: 20),
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
                            audioPlayerController?.playerState.isInitialised ==
                                true
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
                      padding: const EdgeInsets.only(
                          left: 20, right: 20, bottom: 24),
                      child: PostBottomBar(
                          controller: widget.controller, isForVideo: true),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> loadAudio() async {
    try {
      final file = await DefaultCacheManager().getSingleFile(
        widget.controller.post.content?.first.content ?? '',
      );
      if (!mounted) return;

      final player = PlayerController();
      audioPlayerController = player;
      await player.preparePlayer(
        path: file.path,
        noOfSamples: playerWaveStyle.getSamplesForWidth(audioSize.width),
      );
      if (!mounted) {
        await player.pausePlayer();
        return;
      }
      if (Get.isBottomSheetOpen == true) {
        await player.startPlayer();
        await player.setFinishMode(finishMode: FinishMode.pause);
      }
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() {});
    }
  }
}

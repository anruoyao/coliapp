import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/logger.dart';
import 'package:untitled/common/managers/my_debouncer.dart';
import 'package:untitled/models/musics_model.dart';

class MusicTrimScreenController extends BaseController {
  int videoDurationInMilliSec;
  final SelectedMusic selectedMusic;

  PlayerController audioPlayer = PlayerController();
  Rx<int?> durationInMilliSec = Rx(null);
  Rx<int> audioStartInMilliSec = Rx(0);

  RxBool isPlaying = false.obs;
  Timer? _timer;
  StreamSubscription? positionSubscription;

  MusicTrimScreenController(this.videoDurationInMilliSec,
      this.selectedMusic); // Function(SelectedMusic? music)? onMusicAdd;

  final ScrollController scrollController = ScrollController();
  RxList<double> waves = RxList();
  double oneBarValue = 0;
  final double barWidth = 3;
  final double barHorizontalMargin = 1.5;
  final double barInBoxCount = 46;
  RxDouble currentProgress = 0.0.obs;
  RxDouble scrollOffset = 0.0.obs;

  double get barTotalWidth => barWidth + (barHorizontalMargin * 2);

  double get boxWidth => barTotalWidth * barInBoxCount;

  int get currentBars =>
      (previousBar + (currentProgress.value * barInBoxCount)).toInt();

  int get previousBar => (scrollOffset.value / barTotalWidth).toInt();

  @override
  void onInit() {
    super.onInit();

    initPlayer();
  }

  void _onScroll() {
    currentProgress.value = 0.0;
    if (isPlaying.value == true) {
      onPause();
    } else {
      MyDebouncer.shared.run(() async {
        int scrollOffset = scrollController.offset.toInt();
        int startDuration =
            ((scrollOffset / barTotalWidth) / oneBarValue).toInt();
        audioStartInMilliSec.value = (startDuration * 1000);
        this.scrollOffset.value = scrollOffset.toDouble();
        onPlayAudio();
      });
    }
  }

  @override
  void onClose() {
    super.onClose();
    audioPlayer.release();
    _timer?.cancel();
    audioPlayer.dispose();
    positionSubscription?.cancel();
  }

  void initPlayer() async {
    try {
      await Future.delayed(Duration(milliseconds: 250));
      await audioPlayer.preparePlayer(
        path: selectedMusic.downloadedURL ?? '',
      );
      oneBarValue = (barInBoxCount / (videoDurationInMilliSec / 1000));
      durationInMilliSec.value = await audioPlayer.getDuration();

      for (int i = 0;
          i <= (oneBarValue * ((durationInMilliSec.value ?? 0) / 1000)).toInt();
          i++) {
        waves.add(i % 2 == 0 ? 0.15 : 0.3);
      }
      // waves.value = await audioPlayer.extractWaveformData(path: selectedMusic.downloadedURL ?? '', noOfSamples: (oneBarValue * ((durationInMilliSec.value ?? 0) / 1000)).toInt());

      scrollController.addListener(_onScroll);
      scrollController.animateTo(
        ((selectedMusic.startMilliSec ?? 0) / 1000) *
            barTotalWidth *
            oneBarValue,
        duration: Duration(milliseconds: 10),
        curve: Curves.bounceIn,
      );
      playPause();
    } catch (e) {
      Loggers.error("Error loading audio source: $e");
    }
  }

  Future<void> playPause() async {
    (isPlaying.value) ? await onPause() : await onPlayAudio();
  }

  void _listenPlayer() {
    positionSubscription = audioPlayer.onCurrentDurationChanged.listen((event) {
      int relativePosition =
          (event.milliseconds.inMilliseconds) - audioStartInMilliSec.value;
      currentProgress.value = relativePosition / videoDurationInMilliSec;
    });
  }

  Future<void> onPlayAudio() async {
    _listenPlayer();
    try {
      await audioPlayer.seekTo(audioStartInMilliSec.value);

      await Future.delayed(const Duration(milliseconds: 300));
      await audioPlayer.startPlayer();
      audioPlayer.setFinishMode(finishMode: FinishMode.pause);

      int endTime =
          ((durationInMilliSec.value ?? 0) - audioStartInMilliSec.value);

      if (videoDurationInMilliSec < endTime) {
        endTime = videoDurationInMilliSec;
      }
      isPlaying.value = true;
      _timer = Timer(Duration(milliseconds: videoDurationInMilliSec), () async {
        await onPause();
      });
    } catch (e) {
      Loggers.error('ON PLAY ERROR : $e');
    } finally {
      Loggers.info('PLAY');
    }
  }

  Future<void> onPause() async {
    try {
      await audioPlayer.pausePlayer();
      await positionSubscription?.cancel();
      isPlaying.value = false;
      _timer?.cancel();
    } catch (e) {
      Loggers.error(e);
    } finally {
      Loggers.info('PAUSE');
    }
  }

  void onContinueTap() async {
    int audioTotalMilliSec = durationInMilliSec.value ?? 0;
    int audioStartingMilliSec = audioStartInMilliSec.value;

    if (audioTotalMilliSec > videoDurationInMilliSec &&
        (audioTotalMilliSec - audioStartingMilliSec) <
            videoDurationInMilliSec) {
      return Loggers.error('Player Not Ready');
    }

    Loggers.success('READY FOR THE PLAY');
    onPause();
    Get.back(
        result: SelectedMusic(selectedMusic.downloadedURL,
            audioStartingMilliSec, selectedMusic.music,
            endMilliSec: audioStartingMilliSec + videoDurationInMilliSec));
  }

  Future<String> getPath() async {
    Directory? directory = await (Platform.isAndroid
        ? getExternalStorageDirectory()
        : getApplicationDocumentsDirectory());
    return directory?.path ?? '';
  }
}

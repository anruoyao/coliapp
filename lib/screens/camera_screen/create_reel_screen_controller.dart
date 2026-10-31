import 'dart:async';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart'
    show DefaultCacheManager;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:retrytech_plugin/retrytech_plugin.dart';
import 'package:untitled/common/api_service/reel_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/editor_manager.dart';
import 'package:untitled/common/managers/logger.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/add_reel_data.dart';
import 'package:untitled/models/musics_model.dart';
import 'package:untitled/screens/camera_screen/add_reel_screen.dart';
import 'package:untitled/screens/camera_screen/music_sheet/music_sheet.dart';
import 'package:untitled/screens/camera_screen/music_trim_sheet/music_trim_sheet.dart';
import 'package:untitled/screens/camera_screen/reel_editor_screen.dart';
import 'package:untitled/screens/sheets/confirmation_sheet.dart';
import 'package:untitled/utilities/const.dart';
import 'package:untitled/utilities/filters.dart';
import 'package:video_player/video_player.dart';

class CreateReelScreenController extends BaseController
    with GetSingleTickerProviderStateMixin {
  late final PlayerController audioPlayer;

  Rx<VideoPlayerController?> videoPlayerController = Rx(null);
  RxBool isRecording = false.obs;

  RxInt selectedVideoDurationSec = secondsForMakingReel.first.obs;
  RxBool isTorchOn = false.obs;
  RxBool isFilterShow = false.obs;
  RxBool isPlaying = false.obs;

  bool get isRecordingStarted => progress.value != 0;
  Rx<Filters?> selectedFilter = filters.first.obs;
  RxInt selectedFilterIndex = 0.obs;

  // Rx<CameraController?> cameraController = Rx<CameraController?>(null);
  Rx<SelectedMusic?> selectedMusic = Rx(null);
  RxDouble progress = 0.0.obs;
  Timer? _timer;

  RxString outputURL = ''.obs;

  PageController pageController =
      PageController(initialPage: 0, viewportFraction: .22, keepPage: true);

  CreateReelScreenController({Music? music}) {
    if (music != null) {
      Future.delayed(Duration(milliseconds: 100), () {
        onMusicTap(initMusic: music);
      });
    }
  }

  @override
  void onInit() {
    super.onInit();
    _initCameraView();
    audioPlayer = PlayerController();
  }

  @override
  void onClose() {
    super.onClose();
    RetrytechPlugin.shared.disposeCamera;
    audioPlayer.release();
    _timer?.cancel();
  }

  /// Initialize available cameras and set the first one
  Future<void> _initCameraView() async {
    await Future.delayed(Duration(microseconds: 500));
    RetrytechPlugin.shared.initCamera();
  }

  /// Toggle flash mode
  void toggleFlash() {
    isTorchOn.value = !isTorchOn.value;
    RetrytechPlugin.shared.flashOnOff;
  }

  /// Switch between front and back cameras
  void toggleCamera() {
    RetrytechPlugin.shared.toggleCamera;
  }

  /// Pick video from gallery
  Future<void> pickVideoFromGallery() async {
    try {
      XFile? media = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (media != null) _handleReel(media, shouldConvert: false);
    } catch (e) {
      Loggers.error('Error picking video: $e');
    }
  }

  /// Handle video recording start
  Future<void> _startRecording() async {
    if (isRecording.value) return;

    try {
      RetrytechPlugin.shared.startRecording;
      onStartAudio();
      isRecording.value = true;
      _startProgress();
    } catch (e) {
      Loggers.error("Error starting recording: $e");
    }
  }

  /// Pause video recording
  Future<void> _pauseRecording() async {
    if (!isRecording.value) return;

    try {
      RetrytechPlugin.shared.pauseRecording;
      pauseAudioVideo();
      isRecording.value = false;
      _timer?.cancel();
    } catch (e) {
      Loggers.error("Error pausing recording: $e");
    }
  }

  /// Resume video recording
  Future<void> _resumeRecording() async {
    if (isRecording.value) return;

    try {
      RetrytechPlugin.shared.resumeRecording;
      playAudioVideo();
      isRecording.value = true;
      _startProgress();
    } catch (e) {
      Loggers.error("Error resuming recording: $e");
    }
  }

  /// Stop video recording
  Future<void> stopRecording() async {
    // if (cameraController.value == null) return;

    try {
      // final file = await cameraController.value!.stopVideoRecording();
      XFile file = XFile(await RetrytechPlugin.shared.stopRecording ?? '');
      stopAudioVideo();
      _timer?.cancel();
      isRecording.value = false;
      progress.value = 0;
      await _handleReel(file);
      selectedMusic.value = null;
      audioPlayer.dispose();
    } catch (e) {
      Loggers.error("Error stopping recording: $e");
    }
  }

  void playPauseToggle() {
    if (!isRecordingStarted) {
      _startRecording();
      Loggers.info('🎥 VIDEO RECORDING STARTED');
    } else if (isRecording.value) {
      _pauseRecording();
      Loggers.info('⏸ VIDEO RECORDING PAUSED');
    } else {
      _resumeRecording();
      Loggers.info('▶️ VIDEO RECORDING RESUMED');
    }
  }

  void playPausePlayer() {
    if (isPlaying.value) {
      pauseAudioVideo();
    } else {
      playAudioVideo();
    }
  }

  /// Manage progress bar during recording
  void _startProgress() {
    _timer?.cancel();
    final stepDuration = (selectedVideoDurationSec.value * 1000) ~/
        (selectedVideoDurationSec.value * 10);

    _timer = Timer.periodic(Duration(milliseconds: stepDuration), (timer) {
      if (progress.value < selectedVideoDurationSec.value) {
        progress.value =
            double.parse((progress.value + 0.1).toStringAsFixed(1));
      } else {
        timer.cancel();
        stopRecording();
      }
    });
  }

  /// Handle the recorded video
  Future<void> _handleReel(XFile file, {bool shouldConvert = true}) async {
    if (file.path.isEmpty) return;
    startLoading();
    // @@@
    // if (Platform.isAndroid && shouldConvert) {
    //   file = XFile(await FFmpegManager.shared.convertToMp4(file));
    // }
    Loggers.warning("Recorded Video: ${file.path}");
    try {
      outputURL.value = file.path;
      RetrytechPlugin.shared.disposeCamera;
      stopLoading();
      await _initVideoPlayer(path: file.path);
      playAudioVideo();
      await Get.to(() => ReelEditorScreen(cameraScreenController: this),
              opaque: false)
          ?.then((value) async {
        _disposeVideoPlayer();
        selectedMusic.value = null;
        if (pageController.hasClients) {
          pageController.jumpToPage(0);
        }

        onPageChanged(0);
        audioPlayer.dispose();
        _initCameraView();
      });
    } catch (e) {
      Loggers.error("Error handling reel: $e");
    }
  }

  void goToPreview() async {
    var videoSec = videoPlayerController.value?.value.duration.inSeconds ?? 0;
    var limit = (SessionManager.shared.getSettings()?.durationLimitInReel ?? 0);
    startLoading();
    if (videoSec > limit) {
      stopLoading();
      showSnackBar('${LKeys.weAreOnlyAllow.tr} $limit ${LKeys.seconds.tr}',
          type: SnackBarType.error);
    } else {
      pauseAudioVideo();
      var filteredVideoURL = '${(await getPath())}/filtered_video.mp4';
      startLoading();
      if (selectedFilter.value?.colorFilter.isEmpty == true &&
          selectedMusic.value == null) {
        filteredVideoURL = outputURL.value;
      } else {
        await EditorManager.shared.applyFilterAndAudioToVideo(
          audioPath: selectedMusic.value?.downloadedURL,
          audioStartDuration: selectedMusic.value?.startMilliSec,
          duration:
              videoPlayerController.value?.value.duration.inMilliseconds ?? 0,
          inputPath: outputURL.value,
          colorChannelMixer: selectedFilter.value?.colorFilter ?? [],
          outputPath: filteredVideoURL,
        );
      }
      stopLoading();
      var model = AddReelData(
        selectedMusic: selectedMusic.value,
        filter: selectedFilter.value,
        videoPath: filteredVideoURL,
      );
      Get.to(() => AddReelScreen(data: model), opaque: false);
      stopLoading();
    }
  }

  void onMusicTap({Music? initMusic}) async {
    pauseAudioVideo();
    Music? music = initMusic ??
        await showColibriBottomSheet(
          MusicSheet(),
          isScrollControlled: true,
          ignoreSafeArea: false,
        );
    if (music != null) {
      startLoading();
      var value = await DefaultCacheManager()
          .getSingleFile(music.sound?.addBaseURL() ?? '');
      stopLoading();
      await Future.delayed(Duration(milliseconds: 300));
      await _showTrimSheet(downloadedURL: value.path, music: music, startAt: 0);
    }
  }

  Future<void> _showTrimSheet(
      {String? downloadedURL, int startAt = 0, Music? music}) async {
    int? videoDurationInMilliSec =
        videoPlayerController.value?.value.duration.inMilliseconds;
    SelectedMusic? selectedMusic = await showColibriBottomSheet(
      MusicTrimSheet(
        music: SelectedMusic(downloadedURL, startAt, music),
        videoDurationInMilliSec:
            videoDurationInMilliSec ?? (selectedVideoDurationSec.value * 1000),
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
      enableDrag: false,
      isDismissible: false,
    );

    if (selectedMusic != null) {
      this.selectedMusic.value = selectedMusic;
      this.audioPlayer.preparePlayer(path: selectedMusic.downloadedURL ?? '');
      this._initVideoPlayer();
    }
  }

  void removeMusic() {
    showColibriBottomSheet(ConfirmationSheet(
      desc: LKeys.removeSelectedMusicDesc,
      buttonTitle: LKeys.remove,
      onTap: () {
        selectedMusic.value = null;
        this.videoPlayerController.value?.setVolume(1);
        this.audioPlayer.dispose();
      },
    ));
  }

  void tapOnMusicCard() {
    _showTrimSheet(
      downloadedURL: selectedMusic.value?.downloadedURL,
      startAt: selectedMusic.value?.startMilliSec ?? 0,
      music: selectedMusic.value?.music,
    );
  }

  void pauseAudioVideo() {
    audioPlayer.pausePlayer();
    videoPlayerController.value?.pause();

    if (videoPlayerController.value != null) isPlaying.value = false;
  }

  void stopAudioVideo() {
    audioPlayer.stopPlayer();
    videoPlayerController.value?.seekTo(Duration(seconds: 0));
    if (videoPlayerController.value != null) isPlaying.value = false;
  }

  void playAudioVideo() {
    audioPlayer.startPlayer();
    videoPlayerController.value?.play();
    if (videoPlayerController.value != null) isPlaying.value = true;
  }

  void onStartAudio() {
    final startDuration = selectedMusic.value?.startMilliSec ?? 0;
    audioPlayer.seekTo(startDuration);
    audioPlayer.startPlayer();
  }

  void onPageChanged(int index) {
    selectedFilter.value = filters[index];
    selectedFilterIndex.value = index;
  }
}

extension CameraEditorScreenController on CreateReelScreenController {
  Future<void> _initVideoPlayer({String? path}) async {
    if (videoPlayerController.value == null) {
      videoPlayerController.value =
          await VideoPlayerController.file(File(path!))
            ..initialize()
            ..setLooping(false);
    }

    Future.delayed(Duration(milliseconds: 200), () {
      videoPlayerController.refresh();
    });
    await videoPlayerController.value?.seekTo(Duration(seconds: 0));
    await videoPlayerController.value
        ?.setVolume(selectedMusic.value == null ? 1 : 0);

    if (selectedMusic.value?.startMilliSec != null) {
      await audioPlayer.pausePlayer();
      await audioPlayer.seekTo(selectedMusic.value?.startMilliSec ?? 0);
    }

    // Ensure no duplicate listeners
    videoPlayerController.value?.removeListener(_listenVideoPlayer);
    videoPlayerController.value?.addListener(_listenVideoPlayer);
  }

  void _listenVideoPlayer() {
    isPlaying.value = videoPlayerController.value?.value.isPlaying ?? false;
    videoPlayerController.refresh();
    if (videoPlayerController.value?.value.position.inMilliseconds ==
        videoPlayerController.value?.value.duration.inMilliseconds) {
      _initVideoPlayer();
    }
  }

  void _disposeVideoPlayer() {
    videoPlayerController.value?.removeListener(_listenVideoPlayer);
    videoPlayerController.value?.dispose();
    videoPlayerController.value = null;
  }
}

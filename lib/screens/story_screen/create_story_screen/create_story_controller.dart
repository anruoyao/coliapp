import 'dart:async';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:retrytech_plugin/retrytech_plugin.dart';
import 'package:untitled/common/api_service/story_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/editor_manager.dart';
import 'package:untitled/common/managers/image_video_manager.dart';
import 'package:untitled/common/managers/logger.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/story_screen/create_story_screen/story_editor_screen.dart';
import 'package:untitled/screens/story_screen/create_story_screen/widget/story_media_picker.dart';
import 'package:untitled/utilities/filters.dart';
import 'package:video_player/video_player.dart';

class CreateStoryController extends BaseController {
  Rx<VideoPlayerController?> videoPlayerController = Rx(null);
  Rx<StoryType> storyType = StoryType.video.obs;
  RxBool isRecording = false.obs;

  RxBool isTorchOn = false.obs;
  RxBool isFilterShow = false.obs;
  RxBool isPlaying = false.obs;

  bool get isRecordingStarted => recordingDuration.value != 0;
  Rx<Filters?> selectedFilter = filters.first.obs;
  RxInt selectedFilterIndex = 0.obs;

  RxDouble recordingDuration = 0.0.obs;
  Timer? _timer;

  String outputURL = '';

  PageController pageController =
      PageController(initialPage: 0, viewportFraction: .22, keepPage: true);
  bool shouldAddStory = false;

  @override
  void onClose() {
    super.onClose();
    RetrytechPlugin.shared.disposeCamera;
    _timer?.cancel();
  }

  /// Initialize available cameras and set the first one
  Future<void> initCameraView() async {
    Future.delayed(Duration(microseconds: 500), () {
      RetrytechPlugin.shared.initCamera();
    });
  }

  /// Handle missing permissions
  void handlePermission() {
    // Permission handling logic
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

  void pickMedia() {
    showColibriBottomSheet(StoryMediaPicker(
      controller: this,
    ));
  }

  /// Pick video from gallery
  Future<void> pickVideoFromGallery() async {
    XFile? file = await ImagePicker().pickVideo(source: ImageSource.gallery);
    VideoPlayerController testLengthController =
        new VideoPlayerController.file(File(file?.path ?? '')); //Your file here
    await testLengthController.initialize();
    var limit = (SessionManager.shared
            .getSettings()
            ?.minuteLimitInChoosingVideoForStory ??
        0);
    if (testLengthController.value.duration.inSeconds > limit * 60) {
      BaseController.share.showSnackBar(
          '${LKeys.weAreOnlyAllow.tr} $limit ${LKeys.minute.tr}',
          type: SnackBarType.error);
    } else {
      if (file != null) {
        Get.back();
        storyType.value = StoryType.video;
        _handleReel(file, shouldConvert: false);
      }
    }
    testLengthController.dispose();
  }

  Future<void> pickImageFromGallery() async {
    try {
      XFile? media = await ImagePicker().pickImage(source: ImageSource.gallery);
      storyType.value = StoryType.image;
      Get.back();
      if (media != null) _handleReel(media, shouldConvert: false);
    } catch (e) {
      Loggers.error('Error picking image: $e');
    }
  }

  /// Handle video recording start
  Future<void> startRecording() async {
    if (isRecording.value) return;

    try {
      RetrytechPlugin.shared.startRecording;
      isRecording.value = true;
      _startProgress();
    } catch (e) {
      Loggers.error("Error starting recording: $e");
    }
  }

  /// Stop video recording
  Future<void> stopRecording() async {
    try {
      XFile file = XFile(await RetrytechPlugin.shared.stopRecording ?? '');
      stopAudioVideo();
      _timer?.cancel();
      isRecording.value = false;
      recordingDuration.value = 0;
      storyType.value = StoryType.video;
      await _handleReel(file);
    } catch (e) {
      Loggers.error("Error stopping recording: $e");
    }
  }

  void takePicture() async {
    storyType.value = StoryType.image;
    //@@@
    print("Ayu");
    var path = await RetrytechPlugin.shared.captureImage() ?? '';
    print(path);
    XFile? file = XFile(path);
    _handleReel(file, shouldConvert: false);
  }

  void playPauseToggle() {
    if (videoPlayerController.value != null) {
      if (isPlaying.value) {
        pauseAudioVideo();
      } else {
        playAudioVideo();
      }
    }
  }

  /// Manage progress bar during recording
  void _startProgress() {
    _timer?.cancel();
    if (recordingDuration.value == 0) {
      recordingDuration.value = 0.0001;
    }
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      recordingDuration.value = recordingDuration.value + 1;
      Loggers.success(recordingDuration.value);
    });
  }

  /// Handle the recorded video
  Future<void> _handleReel(XFile file, {bool shouldConvert = true}) async {
    if (file.path.isEmpty) return;
    startLoading();
    // @@@
    // if (Platform.isAndroid && shouldConvert && storyType.value == StoryType.video) {
    //   file = XFile(await FFmpegManager.shared.convertToMp4(file));
    // }
    Loggers.warning("Recorded Video: ${file.path}");
    try {
      outputURL = file.path;

      RetrytechPlugin.shared.disposeCamera;

      stopLoading();
      if (storyType.value == StoryType.video) await _initVideoPlayer();
      imageCache.clear();
      imageCache.clearLiveImages();
      await Get.to(() => StoryEditorScreen(controller: this), opaque: false)
          ?.then((value) async {
        _disposeVideoPlayer();
        if (pageController.hasClients) {
          pageController.jumpToPage(0);
        }

        onPageChanged(0);
        RetrytechPlugin.shared.initCamera();
      });
    } catch (e) {
      Loggers.error("Error handling reel: $e");
    }
  }

  void sendStory() async {
    pauseAudioVideo();
    var filterOutputURL = '';

    startLoading();

    if (storyType.value == StoryType.video) {
      var filteredVideoURL = '${(await getPath())}/filtered_video.mp4';
      await EditorManager.shared.applyFilterAndAudioToVideo(
        audioPath: null,
        audioStartDuration: null,
        duration:
            videoPlayerController.value?.value.duration.inMilliseconds ?? 0,
        inputPath: outputURL,
        colorChannelMixer: selectedFilter.value?.colorFilter ?? [],
        outputPath: filteredVideoURL,
      );
      filterOutputURL = filteredVideoURL;
    } else {
      var filteredImageURL = '${(await getPath())}/filtered_image.jpg';
      await EditorManager.shared.applyFilterToImage(
        inputPath: outputURL,
        colorChannelMixer: selectedFilter.value?.colorFilter ?? [],
        outputPath: filteredImageURL,
      );
      filterOutputURL = filteredImageURL;
    }
    stopLoading();
    _createStory(
        fileURL: filterOutputURL,
        duration:
            videoPlayerController.value?.value.duration.inSeconds.toDouble() ??
                0);
  }

  void pauseAudioVideo() {
    videoPlayerController.value?.pause();

    if (videoPlayerController.value != null) isPlaying.value = false;
  }

  void stopAudioVideo() {
    videoPlayerController.value?.seekTo(Duration(seconds: 0));
    if (videoPlayerController.value != null) isPlaying.value = false;
  }

  void playAudioVideo() {
    videoPlayerController.value?.play();
    if (videoPlayerController.value != null) isPlaying.value = true;
  }

  void onPageChanged(int index) {
    selectedFilter.value = filters[index];
    selectedFilterIndex.value = index;
  }
}

extension CameraEditorScreenController on CreateStoryController {
  Future<void> _initVideoPlayer() async {
    if (videoPlayerController.value == null) {
      videoPlayerController.value =
          await VideoPlayerController.file(File(outputURL))
            ..initialize()
            ..setLooping(false);
    }

    Future.delayed(Duration(milliseconds: 200), () {
      videoPlayerController.refresh();
    });
    await videoPlayerController.value?.seekTo(Duration(seconds: 0));

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

  void _createStory({required String fileURL, required double duration}) async {
    startLoading();
    var thumbnailPath = "";
    if (storyType.value == StoryType.video) {
      thumbnailPath =
          (await ImageVideoManager.shared.extractThumbnail(videoPath: fileURL))
              .path;
    }
    print(thumbnailPath);
    print(fileURL);

    _upload(fileURL: fileURL, duration: duration, thumbnailPath: thumbnailPath);

    stopLoading();
  }

  void _upload(
      {required String fileURL,
      required double duration,
      required String thumbnailPath}) async {
    StoryService.shared.createStory(
        fileURL: fileURL,
        type: storyType.value.value,
        duration: duration,
        thumbnail: thumbnailPath,
        completion: () {
          stopLoading();
          Get.back();
          Get.back();
        });
  }

  void createAnotherStory() {
    shouldAddStory = true;
    update();
  }
}

enum StoryType {
  image(0),
  video(1);

  final int value;

  const StoryType(this.value);
}

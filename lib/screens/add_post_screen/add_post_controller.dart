import 'dart:convert';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'dart:io';
import 'dart:math';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:detectable_text_field/detectable_text_field.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled/common/api_service/post_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/string_extension.dart';
import 'package:untitled/common/managers/image_video_manager.dart';
import 'package:untitled/common/managers/my_debouncer.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/managers/url_extractor/metadata_extract_base.dart';
import 'package:untitled/common/managers/url_extractor/parsers/base_parser.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/setting_model.dart';
import 'package:untitled/screens/sheets/confirmation_sheet.dart';
import 'package:untitled/utilities/const.dart';
import 'package:video_player/video_player.dart';

class AddPostController extends BaseController {
  final String postBtnGetID = "postButGetID";
  final String imageGetID = "imageGetID";
  DetectableTextEditingController textEditingController =
      DetectableTextEditingController(
    detectedStyle: MyTextStyle.outfitLight(size: 18, color: cHashtagColor)
        .copyWith(height: 1.2),
    regExp: RegExp(r'#([a-zA-Z0-9_]+)'),
  );
  final ImagePicker _picker = ImagePicker();
  PickerStyle type = PickerStyle.image;
  XFile? videoFile;
  List<XFile> imageFileList = [];
  int selectedImageIndex = 0;
  VideoPlayerController? videoPlayerController;

  PlayerController? audioPlayerController;
  String? audioPath;
  List<double> waves = [];

  RxList<Interest> selectedInterests = RxList();

  UrlMetadata? metaData;
  Set<String> closedUrls = {};

  @override
  void onReady() {
    textEditingController.addListener(() {
      update([postBtnGetID]);
    });
    super.onReady();
  }

  void pick({required PickerStyle type, required ImageSource source}) async {
    this.type = type;
    Get.back();
    if (type == PickerStyle.image) {
      if (source == ImageSource.camera) {
        final XFile? selectedImage = await _picker.pickImage(
            source: source,
            maxHeight: Limits.imageSize,
            maxWidth: Limits.imageSize,
            imageQuality: Limits.quality);
        if (selectedImage != null) {
          imageFileList.add(selectedImage);
        }
      } else {
        startLoading();
        final List<XFile> selectedImages = await _picker.pickMultiImage(
            maxHeight: Limits.imageSize,
            maxWidth: Limits.imageSize,
            imageQuality: Limits.quality);
        var imageCount = min(
            (SessionManager.shared
                        .getSettings()
                        ?.maxImagesCanBeUploadedInOnePost ??
                    0) -
                imageFileList.length,
            selectedImages.length);
        for (var i = 0; i < imageCount; i++) {
          imageFileList.add(selectedImages[i]);
        }
        stopLoading();
      }
    } else {
      XFile? file = await _picker.pickVideo(source: source);
      if (file != null) {
        startLoading();
        int videoDurationSec = await file.path.getVideoDurationInSecond;
        var limit = (SessionManager.shared
                .getSettings()
                ?.minuteLimitInChoosingVideoForPost ??
            0);
        if (videoDurationSec > (limit * 60)) {
          stopLoading();
          showSnackBar('${LKeys.weAreOnlyAllow.tr} $limit ${LKeys.minute.tr}',
              type: SnackBarType.error);
        } else {
          videoFile = file;
          videoPlayerController =
              VideoPlayerController.file(File(videoFile!.path));
          await videoPlayerController?.initialize();
          update(['player']);
          update();
          videoPlayerController?.addListener(() {
            update(['player']);
          });
        }

        stopLoading();
      }
    }
    update([imageGetID, postBtnGetID]);
  }

  void uploadPost() async {
    startLoading();

    videoPlayerController?.pause();
    var thumbnailPath = "";
    if (videoFile != null) {
      thumbnailPath = (await ImageVideoManager.shared
              .extractThumbnail(videoPath: videoFile!.path))
          .path;
    }

    List<String> detectedTags = TextPatternDetector.extractDetections(
        textEditingController.text, textEditingController.regExp!);
    List<String> tags = detectedTags
        .map((s) => s.replaceFirst('#', '').removeAllWhitespace)
        .toList();

    var urlJson = jsonEncode(metaData);

    var contentType = PostType.text;

    if (imageFileList.isNotEmpty) {
      contentType = PostType.image;
    } else if (videoFile != null) {
      contentType = PostType.video;
    } else if (audioPath != null) {
      contentType = PostType.audio;
    }

    PostService.shared.uploadPost(
      contentType: contentType,
      urlPreview: urlJson,
      tags: tags.join(','),
      images: imageFileList,
      video: videoFile,
      audioFile: audioPath == null ? null : XFile(audioPath!),
      thumbnailPath: thumbnailPath,
      desc: textEditingController.text,
      waves: waves,
      interestIds: selectedInterests
          .map((element) => '${element.id}')
          .toList()
          .join(','),
      onProgress: (bytes, totalBytes) {},
      completion: (post) {
        post.user = SessionManager.shared.getUser();
        stopLoading();
        Get.back(result: post);
        showSnackBar(LKeys.postAddedSuccessfully.tr,
            type: SnackBarType.success);
      },
    );
  }

  void onTextChanged(String value) {
    MyDebouncer.shared.run(fetchUrlPreview);
  }

  void fetchUrlPreview() {
    if (metaData == null) {
      List<String> urls = TextPatternDetector.extractDetections(
          textEditingController.text,
          detectionRegExp(atSign: false, url: true)!);
      var urlString = urls.lastOrNull?.toLowerCase() ?? '';
      if (urlString.isEmpty || closedUrls.contains(urlString)) return;
      if (!urlString.startsWith('http')) {
        urlString = 'https://' + urlString;
      }
      extract(urlString).then((value) {
        metaData = value;
        update([imageGetID]);
      });
    }
  }

  void closePreview() {
    List<String> urls = TextPatternDetector.extractDetections(
        textEditingController.text, detectionRegExp(atSign: false, url: true)!);
    closedUrls.addAll(urls);
    // }
    metaData = null;
    update([imageGetID]);
  }

  void setAudioPlayer(
      String path, PlayerController playerController, List<double> waves) {
    audioPath = path;
    audioPlayerController = playerController;
    this.waves = waves;
    update([imageGetID]);
  }

  String replaceCharAt(String oldString, int index, String newChar) {
    return oldString.substring(0, index) +
        newChar +
        oldString.substring(index + 1);
  }

  void play() {
    videoPlayerController?.play();
  }

  void pause() {
    videoPlayerController?.pause();
  }

  void playPause() {
    if (videoPlayerController?.value.isPlaying ?? false) {
      pause();
    } else {
      play();
    }
  }

  void onPageChange(int value) {
    selectedImageIndex = value;
    update(['pageView']);
  }

  void onChange(double value) {
    videoPlayerController?.seekTo(Duration(milliseconds: value.toInt()));
  }

  void removeVideo() {
    videoPlayerController?.pause();
    videoPlayerController?.dispose();
    videoFile = null;
    update([imageGetID, postBtnGetID]);
  }

  void removeAudio() {
    showColibriBottomSheet(ConfirmationSheet(
        desc: LKeys.doYouWantToRemoveThisRecording,
        buttonTitle: LKeys.yes,
        onTap: () {
          audioPlayerController?.pausePlayer();
          audioPlayerController?.dispose();
          audioPlayerController = null;
          audioPath = null;
          update([imageGetID, postBtnGetID]);
        }));
  }

  void removeImage() {
    imageFileList.removeAt(selectedImageIndex);
    selectedImageIndex = max(
        imageFileList.length == 1
            ? 0
            : (selectedImageIndex == imageFileList.length
                ? selectedImageIndex - 1
                : selectedImageIndex),
        0);
    update([imageGetID, postBtnGetID, "pageView"]);
  }
}

enum PickerStyle { video, image, audio }

enum PostType {
  image(0),
  video(1),
  audio(2),
  text(3);

  final int value;

  const PostType(this.value);
}

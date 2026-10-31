import 'package:detectable_text_field/detectable_text_field.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled/common/api_service/reel_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/string_extension.dart';
import 'package:untitled/common/managers/image_video_manager.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/enums/reel_page_type.dart';
import 'package:untitled/models/add_reel_data.dart';
import 'package:untitled/models/reel_model.dart';
import 'package:untitled/models/setting_model.dart';
import 'package:untitled/screens/reels_screen/reels_screen.dart';
import 'package:untitled/utilities/const.dart';

class AddReelScreenController extends BaseController {
  late Rx<AddReelData> data;
  DetectableTextEditingController textEditingController =
      DetectableTextEditingController(
    detectedStyle: MyTextStyle.outfitLight(size: 18, color: cHashtagColor)
        .copyWith(height: 1.2),
    regExp: RegExp(r'#([a-zA-Z0-9_]+)'),
  );
  RxList<Interest> selectedInterests = RxList();

  AddReelScreenController({required AddReelData data}) {
    this.data = data.obs;
  }

  void openPreview() {
    Reel reel = Reel(
      description: textEditingController.text,
      id: -1,
      createdAt: DateTime.now(),
      user: SessionManager.shared.getUser(),
      content: data.value.videoPath,
      thumbnail: data.value.thumbnailPath,
      musicId: data.value.selectedMusic?.music?.id,
    );

    Get.to(
        () => ReelsScreen(
              reels: [reel].obs,
              position: 0.obs,
              pageType: ReelPageType.preview,
              isLoading: false.obs,
            ),
        opaque: false);
  }

  void changeCover() async {
    XFile? pickedImage = await ImageVideoManager.shared.pickImage();
    if (pickedImage != null) {
      data.update((val) async {
        val?.thumbnailBytes = await pickedImage.readAsBytes();
        val?.thumbnailPath = pickedImage.path;
        data.refresh();
      });
    }
  }

  @override
  void onReady() {
    super.onReady();
    _generateThumbnail();
  }

  void _generateThumbnail() async {
    data.update((val) async {
      val?.thumbnailBytes = (await (ImageVideoManager.shared
          .extractThumbnailByte(videoPath: val.videoPath ?? '')));
      val?.thumbnailPath = (await (ImageVideoManager.shared
              .extractThumbnail(videoPath: val.videoPath ?? '')))
          .path;
      data.refresh();
    });
  }

  void uploadReel() async {
    BaseController.share.startLoading();
    List<String> detectedTags = TextPatternDetector.extractDetections(
        textEditingController.text, textEditingController.regExp!);

    List<String> tags = detectedTags
        .map((s) => s.replaceFirst('#', '').removeAllWhitespace)
        .toList();

    int videoDurationSec = await data.value.videoPath!.getVideoDurationInSecond;
    Reel? reel = await ReelService.shared.uploadReel(
      description: textEditingController.text,
      content: XFile(data.value.videoPath!),
      thumbnail: XFile(data.value.thumbnailPath!),
      hashtags: tags.join(','),
      interestIds: selectedInterests
          .map((element) => '${element.id}')
          .toList()
          .join(','),
      musicId: data.value.selectedMusic?.music?.id,
    );
    stopLoading();
    if (reel != null) {
      Get.back();
      Get.back();
      Get.back();
      Get.back(result: reel);
    }
  }

  String replaceCharAt(String oldString, int index, String newChar) {
    return oldString.substring(0, index) +
        newChar +
        oldString.substring(index + 1);
  }
}

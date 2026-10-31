import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled/common/api_service/user_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/setting_model.dart';
import 'package:untitled/screens/profile_picture_screen/profile_picture_controller.dart';

class ProfileVerificationController extends ProfilePictureController {
  XFile? selectedDocument;
  TextEditingController fullNameController = TextEditingController();
  SettingCommon? selectedType;
  List<SettingCommon> types =
      SessionManager.shared.getSettings()?.documentType ?? [];

  @override
  void onReady() {
    selectedType = types.first;
    update();
    super.onReady();
  }

  void onChangeType(SettingCommon? value) {
    selectedType = value;
    update();
  }

  void selectDocument() async {
    try {
      selectedDocument = await picker.pickImage(source: ImageSource.gallery);
      update();
    } catch (e) {
      showSnackBar("Invalid Document");
    }
  }

  void submitRequest() async {
    if (fullNameController.text.isEmpty) {
      showSnackBar(LKeys.pleaseEnterFullName.tr, type: SnackBarType.error);
    } else if (selectedDocument == null) {
      showSnackBar(LKeys.pleaseSelectDocument.tr, type: SnackBarType.error);
    } else if (imagePath.isEmpty) {
      showSnackBar(LKeys.pleaseEnterYourSelfie.tr, type: SnackBarType.error);
    } else {
      startLoading();
      UserService.shared.profileVerification(fullNameController.text,
          selectedType?.title ?? '', selectedDocument, XFile(imagePath));
    }
  }
}

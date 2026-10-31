import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/setting_model.dart';
import 'package:untitled/screens/extra_views/back_button.dart';
import 'package:untitled/screens/extra_views/buttons.dart';
import 'package:untitled/screens/extra_views/top_bar.dart';
import 'package:untitled/screens/profile_picture_screen/profile_picture_screen.dart';
import 'package:untitled/screens/profile_verification_screen/profile_verification_controller.dart';
import 'package:untitled/screens/rooms_you_own/create_room_screen/create_room_screen.dart';
import 'package:untitled/utilities/const.dart';

class ProfileVerificationScreen extends StatelessWidget {
  const ProfileVerificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ProfileVerificationController controller = ProfileVerificationController();
    return Scaffold(
      body: Column(
        children: [
          const TopBarForInView(title: LKeys.profileVerification),
          Expanded(
            child: SingleChildScrollView(
              child: GetBuilder(
                  init: controller,
                  builder: (controller) {
                    return Column(
                      children: [
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              SessionManager.shared.getUser()?.username ?? '',
                              style: MyTextStyle.gilroyBold(),
                            ),
                            const SizedBox(width: 5),
                            const VerifyIcon(isPlaceholder: true)
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: Get.width * 0.75,
                          child: Text(
                            LKeys.profileVerificationDesc.tr,
                            style: MyTextStyle.gilroyLight(
                                color: cLightText, size: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),
                        documentVerificationView(controller),
                        const SizedBox(height: 40),
                        CommonButton(
                          text: LKeys.submit,
                          onTap: controller.submitRequest,
                        )
                      ],
                    );
                  }),
            ),
          ),
        ],
      ),
    );
  }

  Widget documentVerificationView(ProfileVerificationController controller) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          const CreateRoomHeading(title: LKeys.fullName),
          MyTextField(
              controller: controller.fullNameController,
              placeHolder: SessionManager.shared.getUser()?.fullName ?? ''),
          const SizedBox(height: 10),
          const CreateRoomHeading(title: LKeys.documentType),
          dropDown(controller),
          GestureDetector(
            onTap: () {
              controller.selectDocument();
            },
            child: Container(
              decoration: BoxDecoration(
                color: cLightBg,
                borderRadius: BorderRadius.circular(8),
              ),
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              child: Text(
                (controller.selectedDocument?.name
                        .replaceAll('image_picker_', '') ??
                    LKeys.selectDocument.tr),
                textAlign: TextAlign.center,
                style: MyTextStyle.gilroyLight(color: cLightText),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const CreateRoomHeading(title: LKeys.yourSelfie),
          ProfileImagePicker(
            controller: controller,
            boxSize: Get.width / 2,
            radius: 100,
            onTap: () {
              controller.pickImage(source: ImageSource.camera);
            },
          ),
        ],
      ),
    );
  }

  Widget dropDown(ProfileVerificationController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
          color: cLightBg, borderRadius: BorderRadius.circular(8)),
      child: DropdownButton<SettingCommon>(
        borderRadius: BorderRadius.circular(12),
        dropdownColor: cLightBg,
        value: controller.selectedType,
        elevation: 16,
        isExpanded: true,
        underline: const SizedBox(),
        style: MyTextStyle.gilroyMedium(color: cLightText),
        onChanged: controller.onChangeType,
        items: controller.types
            .map<DropdownMenuItem<SettingCommon>>((SettingCommon value) {
          return DropdownMenuItem<SettingCommon>(
            value: value,
            child: Text(value.title ?? ''),
          );
        }).toList(),
      ),
    );
  }
}

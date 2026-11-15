import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled/common/api_service/post_service.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/managers/image_video_manager.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/chats_screen/chatting_screen/chatting_controller.dart';
import 'package:untitled/screens/extra_views/top_bar.dart';
import 'package:untitled/utilities/const.dart';
import 'package:untitled/utilities/firebase_const.dart';

class ImageVideoOptionPicker extends StatelessWidget {
  final VoidCallback onVideoTap;
  final VoidCallback onImageTap;

  const ImageVideoOptionPicker({
    super.key,
    required this.onVideoTap,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return ColibriSheetSurface(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ColibriSheetHeader(
            title: LKeys.howDoYouWant.tr,
            trailing: const ColibriSheetCloseButton(),
          ),
          const SizedBox(height: 8),
          ColibriSheetActionRow(
            title: LKeys.image.tr,
            icon: Icons.photo_outlined,
            showDivider: true,
            onTap: onImageTap,
          ),
          ColibriSheetActionRow(
            title: LKeys.video.tr,
            icon: Icons.video_library_outlined,
            onTap: onVideoTap,
          ),
        ],
      ),
    );
  }
}

class WriteDescriptionSheet extends StatefulWidget {
  final XFile file;
  final ChattingController controller;
  final MessageType type;

  const WriteDescriptionSheet({
    super.key,
    required this.file,
    required this.controller,
    required this.type,
  });

  @override
  State<WriteDescriptionSheet> createState() => _WriteDescriptionSheetState();
}

class _WriteDescriptionSheetState extends State<WriteDescriptionSheet> {
  XFile? thumbnail;

  Future<void> setImage() async {
    if (widget.type == MessageType.video) {
      final value = await ImageVideoManager.shared
          .extractThumbnail(videoPath: widget.file.path);
      if (!mounted) return;
      thumbnail = XFile(value.path);
    } else {
      thumbnail = widget.file;
    }
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    setImage();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        top: true,
        child: Column(
          children: [
            TopBarForInView(
              title: '',
              backIcon: Icons.close_rounded,
              child: GestureDetector(
                onTap: _sendMedia,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.fromLTRB(20, 7, 20, 5),
                  decoration: BoxDecoration(
                    color: cPrimary,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    LKeys.send.tr.toUpperCase(),
                    style: MyTextStyle.gilroySemiBold(color: cBlack, size: 14),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    Container(
                      height: 130,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 12),
                      child: TextField(
                        controller: widget.controller.messageTextController,
                        textCapitalization: TextCapitalization.sentences,
                        expands: true,
                        minLines: null,
                        maxLines: null,
                        style: MyTextStyle.gilroyRegular(
                            color: cDarkText.withValues(alpha: 0.75)),
                        decoration: InputDecoration(
                          hintText: LKeys.writeHere.tr,
                          hintStyle: MyTextStyle.gilroyRegular(
                              color: cLightText.withValues(alpha: 0.75)),
                          border: InputBorder.none,
                          counterText: '',
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        cursorColor: cPrimary,
                        textInputAction: TextInputAction.done,
                      ),
                    ),
                    const SizedBox(height: 15),
                    if (thumbnail?.path.isNotEmpty == true)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(thumbnail!.path),
                          fit: BoxFit.cover,
                          height: Get.width - 30,
                          width: Get.width - 30,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMedia() {
    final controller = widget.controller;
    controller.startLoading();
    if (widget.type == MessageType.image) {
      PostService.shared.uploadFile(widget.file, (url) {
        controller.stopLoading();
        Get.back();
        controller.commonSend(type: MessageType.image, content: url);
      });
      return;
    }
    PostService.shared.uploadFile(widget.file, (videoUrl) {
      final preview = thumbnail;
      if (preview == null) return;
      PostService.shared.uploadFile(preview, (thumbnailUrl) {
        controller.stopLoading();
        Get.back();
        controller.commonSend(
          type: MessageType.video,
          content: videoUrl,
          thumbnail: thumbnailUrl,
        );
      });
    });
  }
}

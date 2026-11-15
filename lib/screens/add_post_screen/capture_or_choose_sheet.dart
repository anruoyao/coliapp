import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'package:untitled/localization/languages.dart';

class CaptureOrChooseSheet extends StatelessWidget {
  final Function() onCaptureTap;
  final Function() onChooseTap;

  const CaptureOrChooseSheet({
    super.key,
    required this.onCaptureTap,
    required this.onChooseTap,
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
          const SizedBox(height: 12),
          ColibriSheetActionRow(
            title: LKeys.capture.tr,
            icon: Icons.camera_alt_outlined,
            showDivider: true,
            onTap: () {
              Navigator.of(context).pop();
              onCaptureTap();
            },
          ),
          ColibriSheetActionRow(
            title: LKeys.choose.tr,
            icon: Icons.photo_library_outlined,
            onTap: () {
              Navigator.of(context).pop();
              onChooseTap();
            },
          ),
        ],
      ),
    );
  }
}

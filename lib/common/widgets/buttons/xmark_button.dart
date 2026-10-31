import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/widgets/buttons/circle_button.dart';
import 'package:untitled/utilities/const.dart';

class XmarkButton extends StatelessWidget {
  final Function onTap;

  const XmarkButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: const CircleIcon(color: cBlack, iconData: Icons.close),
      onTap: () {
        Get.back();
        onTap();
      },
    );
  }
}

class XmarkButtonForSheet extends StatelessWidget {
  const XmarkButtonForSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.back();
      },
      child: CircleAvatar(
        radius: 16,
        backgroundColor: cWhite.withValues(alpha: 0.1),
        child: Image.asset(
          MyImages.close,
          height: 12,
          width: 12,
          color: cLightText,
        ),
      ),
    );
  }
}

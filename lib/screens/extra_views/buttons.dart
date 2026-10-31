import 'dart:ui';

import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/utilities/const.dart';

class CommonButton extends StatelessWidget {
  final String text;
  final Function onTap;

  const CommonButton({Key? key, required this.text, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: GestureDetector(
        onTap: () => onTap(),
        child: Container(
          decoration: ShapeDecoration(
            color: cPrimary,
            shape: const SmoothRectangleBorder(
                borderRadius: SmoothBorderRadius.all(SmoothRadius(
                    cornerRadius: 12, cornerSmoothing: cornerSmoothing))),
            shadows: kMyBoxShadow,
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
          margin: const EdgeInsets.only(bottom: 15, right: 10, left: 10),
          alignment: Alignment.center,
          width: double.infinity,
          child: Text(
            text.tr,
            style: MyTextStyle.gilroySemiBold(size: 18),
          ),
        ),
      ),
    );
  }
}

class CommonSheetButton extends StatelessWidget {
  final Color? color;
  final Color? textColor;
  final String title;
  final VoidCallback onTap;

  const CommonSheetButton(
      {Key? key,
      required this.title,
      required this.onTap,
      this.color,
      this.textColor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.only(bottom: 30),
        decoration: ShapeDecoration(
            shape: const SmoothRectangleBorder(
                borderRadius: SmoothBorderRadius.all(SmoothRadius(
                    cornerRadius: 12, cornerSmoothing: cornerSmoothing))),
            color: color ?? cWhite),
        height: 50,
        width: double.infinity,
        child: Text(
          title.tr,
          style: MyTextStyle.gilroySemiBold(color: textColor ?? cBlack),
        ),
      ),
    );
  }
}

class BlurBgButton extends StatelessWidget {
  final String text;
  final Function() onTap;

  const BlurBgButton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: SmoothBorderRadius(cornerRadius: 20),
          border: Border.all(
            color: cWhite.withValues(alpha: 0.2),
          ),
        ),
        child: ClipRRect(
          borderRadius: SmoothBorderRadius(cornerRadius: 20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: SmoothBorderRadius(cornerRadius: 20),
              color: cBlack.withValues(alpha: 0.4),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: Text(text.tr,
                    style: MyTextStyle.outfitLight(color: cWhite)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

var kMyBoxShadow = [
  BoxShadow(
    color: cPrimary.withValues(alpha: 0.5),
    blurRadius: 10,
    offset: const Offset(0, 4), // Shadow position
  )
];

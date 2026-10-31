import 'package:flutter/material.dart';
import 'package:untitled/common/widgets/back_button.dart';
import 'package:untitled/utilities/const.dart';

import '../../../enums/reel_page_type.dart';
import '../reels_screen_controller.dart';

class ReelsTopBar extends StatelessWidget {
  final ReelsScreenController controller;
  final ReelPageType reelType;
  final Widget? widget;

  const ReelsTopBar(
      {super.key,
      required this.controller,
      required this.reelType,
      this.widget});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Visibility(
                  visible: reelType.shouldShowBackButton,
                  replacement: const SizedBox(width: 30),
                  child: BackBarButton(color: cWhite),
                ),
                if (widget != null) widget ?? Container(),
                SizedBox(width: 30)
              ],
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/utilities/const.dart';

import 'buttons/circle_button.dart';

class BackBarButton extends StatelessWidget {
  final Color? color;

  const BackBarButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: CircleIcon(
          color: color ?? cBlack, iconData: Icons.chevron_left_rounded),
      onTap: () {
        Get.back();
      },
    );
  }
}

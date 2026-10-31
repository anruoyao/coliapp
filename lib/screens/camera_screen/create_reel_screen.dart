import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:retrytech_plugin/retrytech_plugin.dart';
import 'package:untitled/common/widgets/black_gradient_shadow.dart';
import 'package:untitled/models/musics_model.dart';
import 'package:untitled/screens/camera_screen/create_reel_screen_controller.dart';
import 'package:untitled/screens/camera_screen/widget/create_reel_bottom_view.dart';
import 'package:untitled/screens/camera_screen/widget/create_reel_top_view.dart';
import 'package:untitled/utilities/const.dart';

class CreateReelScreen extends StatelessWidget {
  final Music? music;

  const CreateReelScreen({super.key, this.music});

  @override
  Widget build(BuildContext context) {
    final _ = Get.put(CreateReelScreenController(music: music));

    return Scaffold(
      backgroundColor: cBlack,
      resizeToAvoidBottomInset: false,
      body: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: .52,
            child: ClipSmoothRect(
              radius: SmoothBorderRadius(cornerRadius: 20, cornerSmoothing: 1),
              child: SizedBox(
                height: 100,
                width: 100,
                child: RetrytechPlugin.shared.cameraView,
              ),
            ),
          ),
          const Align(
              alignment: Alignment.bottomCenter, child: BlackGradientShadow()),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CreateReelTopView(),
                CreateReelBottomView(),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class BuildBorderRoundIcon extends StatelessWidget {
  final String? image;
  final VoidCallback? onTap;
  final double size;

  const BuildBorderRoundIcon(
      {super.key, this.image, this.onTap, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
            color: cWhite.withValues(alpha: .20),
            shape: BoxShape.circle,
            border: Border.all(color: cWhite.withValues(alpha: .25))),
        child: Center(
          child: Image.asset(image!, color: cWhite, width: size, height: size),
        ),
      ),
    );
  }
}

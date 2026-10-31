import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

extension S on String {
  Text toTextTR(TextStyle style) {
    return Text(
      tr,
      textAlign: TextAlign.center,
      style: style,
    );
  }
}

extension FileExtension on String {
  Future<int> get getVideoDurationInSecond async {
    var tempVideoController = VideoPlayerController.file(File(this));
    await tempVideoController.initialize();
    var seconds = tempVideoController.value.duration.inSeconds;
    tempVideoController.dispose();
    return seconds;
  }
}

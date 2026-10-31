import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled/utilities/const.dart';
import 'package:video_compress/video_compress.dart';

class ImageVideoManager {
  static var shared = ImageVideoManager();
  var _picker = ImagePicker();

  Future<XFile?> pickImage() async {
    final XFile? selectedImage = await _picker.pickImage(
      source: ImageSource.gallery,
      maxHeight: Limits.imageSize,
      maxWidth: Limits.imageSize,
      imageQuality: Limits.quality,
    );
    return selectedImage;
  }

  Future<File> extractThumbnail({required String videoPath}) async {
    final file = await VideoCompress.getFileThumbnail(
      videoPath,
      quality: Limits.quality,
      position: -1,
    );

    return file;
  }

  Future<Uint8List?> extractThumbnailByte({required String videoPath}) async {
    final file = await VideoCompress.getByteThumbnail(
      videoPath,
      quality: Limits.quality,
      position: -1,
    );

    return file;
  }
}

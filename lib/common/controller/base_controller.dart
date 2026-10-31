import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
import 'package:untitled/common/widgets/colibri_ui.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/utilities/const.dart';
import 'package:url_launcher/url_launcher.dart';

class BaseController extends GetxController {
  static var share = BaseController();
  RxBool isLoading = false.obs;

  void startLoading() {
    loader();
    isLoading.value = true;
    update();
  }

  void stopLoading([List<Object>? ids, bool condition = true]) {
    if (isLoading.value && (Get.isDialogOpen ?? false)) {
      Get.back();
    }
    // 无论弹窗是否还开着，loading 状态都要复位，避免标志位卡死后误关其他页面
    isLoading.value = false;
    update();
  }

  loader({double? value}) {
    Get.dialog(
        Center(
          child: CircularProgressIndicator(
            color: cPrimary,
          ),
        ),
        barrierColor: Colors.transparent);
    // showDialog(
    //   context: Get.context!,
    //   // barrierDismissible: true,
    //   barrierDismissible: false,
    //   builder: (context) {
    //     return const Center(
    //       child: CircularProgressIndicator(
    //         color: cPrimary,
    //       ),
    //     );
    //   },
    // );
  }

  void materialSnackBar(String title,
      {SnackBarType type = SnackBarType.info,
      String? message,
      Function()? onCompletion}) {
    showColibriToast(
      title.tr.toString(),
      message: message?.tr.toString(),
      status: switch (type) {
        SnackBarType.success => ColibriToastStatus.success,
        SnackBarType.error => ColibriToastStatus.error,
        SnackBarType.info => ColibriToastStatus.info,
      },
    );
    onCompletion?.call();
  }

  void showSnackBar(String title,
      {SnackBarType type = SnackBarType.info,
      String? message,
      Function()? onCompletion}) {
    materialSnackBar(title,
        type: type, message: message, onCompletion: onCompletion);
  }

  void showConfirmationSheet(
      {required desc, required buttonTitle, required onTap}) {
    showColibriConfirmDialog(
      Get.context!,
      icon: Icons.warning_amber_rounded,
      title: LKeys.areYouSure.tr,
      message: desc.toString().tr,
      confirmText: buttonTitle.toString().tr,
      onConfirm: () async {
        onTap();
        return true;
      },
    );
  }

  void handleURL({required String url}) async {
    var urlString = url;
    if (!urlString.startsWith('http')) {
      urlString = 'https:\\\\' + urlString;
    }
    final Uri uri = Uri.parse(urlString);

    if (!await launchUrl(uri)) {
      print('Could not launch $uri');
    }
  }

  Future<String> getPath() async {
    Directory? directory = await (Platform.isAndroid
        ? getExternalStorageDirectory()
        : getApplicationDocumentsDirectory());
    return directory?.path ?? '';
  }
}

enum SnackBarType { info, error, success }

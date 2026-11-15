import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:untitled/common/managers/logger.dart';
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

  void loader({double? value}) {
    Get.dialog(
      Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: cWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cBlack.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const CupertinoActivityIndicator(radius: 13),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.12),
    );
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

  void showConfirmationSheet({
    required Object desc,
    required Object buttonTitle,
    required VoidCallback onTap,
  }) {
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
      urlString = 'https:\\\\$urlString';
    }
    final Uri uri = Uri.parse(urlString);

    if (!await launchUrl(uri)) {
      Loggers.error('Could not launch $uri');
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

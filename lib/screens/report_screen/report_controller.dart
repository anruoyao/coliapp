import 'package:flutter/material.dart';
import 'package:untitled/common/api_service/post_service.dart';
import 'package:untitled/common/api_service/reel_service.dart';
import 'package:untitled/common/api_service/room_service.dart';
import 'package:untitled/common/api_service/user_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/posts_model.dart';
import 'package:untitled/models/reel_model.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/models/room_model.dart';
import 'package:untitled/models/setting_model.dart';

class ReportController extends BaseController {
  final List<SettingCommon> reasons =
      SessionManager.shared.getSettings()?.reportReasons ?? [];
  SettingCommon? selectedReason;
  TextEditingController reasonTextController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    selectedReason = reasons.isNotEmpty ? reasons.first : null;
  }

  void onReasonChange(SettingCommon? reason) {
    selectedReason = reason;
    update();
  }

  void submitReport(Room? room, Post? post, User? user, Reel? reel) {
    if (selectedReason == null) {
      showSnackBar("Please select a reason");
      return;
    }
    if (reasonTextController.text.isEmpty) {
      showSnackBar(LKeys.pleaseEnterDescription);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    startLoading();
    if (room != null) {
      RoomService.shared.reportRoom(
          room.id ?? 0, selectedReason?.title ?? '', reasonTextController.text);
    } else if (post != null) {
      PostService.shared.reportPost(
          post.id ?? 0, selectedReason?.title ?? '', reasonTextController.text);
    } else if (user != null) {
      UserService.shared.reportUser(
          user.id ?? 0, selectedReason?.title ?? '', reasonTextController.text);
    } else if (reel != null) {
      ReelService.shared.reportReel(
          reelId: reel.id ?? 0,
          reason: selectedReason?.title ?? '',
          desc: reasonTextController.text);
    }
  }
}

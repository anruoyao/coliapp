import 'package:flutter/material.dart';
import 'package:untitled/common/api_service/common_service.dart';
import 'package:untitled/common/controller/cupertino_controller.dart';
import 'package:untitled/models/notification_model.dart';
import 'package:untitled/models/user_notification_model.dart';

class NotificationScreenController extends CupertinoController {
  ScrollController scrollController = ScrollController();
  ScrollController userScrollController = ScrollController();
  List<PlatformNotification> notifications = [];
  List<UserNotification> userNotifications = [];

  @override
  void onReady() {
    fetchUserNotifications();
    fetchNotification();

    super.onReady();
  }

  Future<void> fetchNotification({bool shouldRefresh = false}) async {
    await CommonService.shared.fetchPlatformNotification(
        shouldRefresh ? 0 : notifications.length, (notifications) {
      if (shouldRefresh) {
        notifications.clear();
        update();
      }
      this.notifications.addAll(notifications);
      update();
    });
  }

  Future<void> fetchUserNotifications({bool shouldRefresh = false}) async {
    if (userNotifications.isEmpty) {
      startLoading();
    }

    await CommonService.shared.fetchUserNotifications(
        shouldRefresh ? 0 : userNotifications.length, (notifications) {
      if (userNotifications.isEmpty) {
        stopLoading();
      }
      if (shouldRefresh) {
        userNotifications.clear();
        update();
      }
      userNotifications.addAll(notifications);
      update();
    });
  }
}

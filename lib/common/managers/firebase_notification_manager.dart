import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:untitled/common/managers/logger.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/utilities/const.dart';
import 'package:untitled/utilities/params.dart';

class FirebaseNotificationManager {
  static var shared = FirebaseNotificationManager();
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  AndroidNotificationChannel channel = AndroidNotificationChannel(
      'chatter', // id
      'Chatter Notification', // title
      playSound: true,
      enableLights: true,
      enableVibration: true,
      importance: Importance.max);

  String newMessageId = '';

  /// 已获取到的 FCM token 缓存（App 启动时 init() 即开始预热获取）。
  /// 登录等关键路径优先读取缓存，避免在无 Google 服务的设备上阻塞等待。
  String? cachedFcmToken;

  void init() async {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, sound: true);

    await firebaseMessaging.requestPermission(
        alert: true, badge: false, sound: true);
    Loggers.success("NOTIFICATION DOOOOOOOOONE");

    var initializationSettingsAndroid = const AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    var initializationSettingsIOS = const DarwinInitializationSettings(
        defaultPresentAlert: true,
        defaultPresentSound: true,
        defaultPresentBadge: false);

    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data[Param.conversationId] ==
          SessionManager.shared.getStoredConversation()) {
        print('In Same Chat');
        return;
      }
      if (message.messageId != newMessageId || Platform.isAndroid) {
        newMessageId = message.messageId!;
        print('Notification: ${message.messageId}');
        showNotification(message);
      }
    });

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    getNotificationToken(
      (token) {},
    );
    subscribeToTopic(notificationTopic);
  }

  void showNotification(RemoteMessage message) {
    flutterLocalNotificationsPlugin.show(
      1,
      message.data['title'],
      message.data['body'],
      NotificationDetails(
          iOS: const DarwinNotificationDetails(
              presentSound: true, presentAlert: true, presentBadge: false),
          android: AndroidNotificationDetails(channel.id, channel.name)),
    );
  }

  void getNotificationToken(Function(String token) completion) {
    // 防止 completion 被重复调用（超时触发后原 Future 可能又完成了）
    var finished = false;
    void done(String token) {
      if (finished) return;
      finished = true;
      completion(token);
    }

    try {
      FirebaseMessaging.instance.getToken().then(
        (value) {
          if (value?.isEmpty == true || value == null) {
            Loggers.error('Token: $value');
            done('No Token');
          } else {
            cachedFcmToken = value;
            Loggers.success('Token: $value');
            done(value);
          }
        },
        onError: (e) {
          done('No Token');
        },
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        // 在无 Google 服务的设备上 getToken() 可能永远不返回，
        // 超时兜底防止登录流程（registerUser）永久卡在转圈
        Loggers.warning('getNotificationToken timeout, fallback to No Token');
        done('No Token');
        return null;
      });
    } catch (e) {
      done('No Token');
    }
  }

  void subscribeToTopic(String topic) async {
    var user = SessionManager.shared.getUser();
    if (user == null || user.isPushNotifications == 1) {
      await firebaseMessaging
          .subscribeToTopic('${topic}_${Platform.isIOS ? 'ios' : 'android'}')
          .onError((error, stackTrace) {
        print(error);
      });

      if (kDebugMode)
        await firebaseMessaging.subscribeToTopic(
            'test_${topic}_${Platform.isIOS ? 'ios' : 'android'}');
    }
  }

  void unsubscribeToTopic(String topic) async {
    await firebaseMessaging
        .unsubscribeFromTopic('${topic}_${Platform.isIOS ? 'ios' : 'android'}');

    if (kDebugMode)
      await firebaseMessaging.subscribeToTopic(
          'test_${topic}_${Platform.isIOS ? 'ios' : 'android'}');
  }

  bool hasListenerSet = false;

  void setupListener() async {
    if (hasListenerSet) {
      return;
    }
    ;
    hasListenerSet = true;
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("notification aavi: ${message.toMap()}");

      if (message.data[Param.conversationId] ==
          SessionManager.shared.getStoredConversation()) {
        print('In Same Chat');
        return;
      }

      if (message.messageId != newMessageId || Platform.isAndroid) {
        newMessageId = message.messageId!;
        print('Notification: ${message.messageId}');
        showNotification(message);
      }
    });
  }
}

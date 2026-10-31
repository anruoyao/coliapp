import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:audio_session/audio_session.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:untitled/common/api_service/colibri_api.dart';
import 'package:untitled/common/managers/app_command_handler.dart';
import 'package:untitled/common/managers/bookmark_store.dart';
import 'package:untitled/common/managers/chat_unread_store.dart';
import 'package:untitled/common/managers/firebase_notification_manager.dart';
import 'package:untitled/common/managers/guest_session.dart';
import 'package:untitled/common/managers/haptic_manager.dart';
import 'package:untitled/common/managers/logger.dart';
import 'package:untitled/common/managers/presence_manager.dart';
import 'package:untitled/common/managers/reverb_service.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/widgets/colibri_ui.dart';
import 'package:untitled/common/widgets/functions.dart';
import 'package:untitled/localization/allLanguages.dart';
import 'package:untitled/screens/login_screen/login_screen.dart';
import 'package:untitled/screens/splash_screen/splash_screen_view.dart';
import 'package:untitled/utilities/const.dart';

import 'localization/languages.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  Loggers.success("Handling a background message: ${message.data}");
  await Firebase.initializeApp();
  FirebaseNotificationManager.shared.showNotification(message);
}

Future<void> main() async {
  final startup = Stopwatch()..start();
  Loggers.info('startup.main.enter');
  WidgetsFlutterBinding.ensureInitialized();
  Loggers.info('startup.binding.ready ${startup.elapsedMilliseconds}ms');
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    Loggers.error('startup.unhandled $error\\n$stackTrace');
    return false;
  };
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  Loggers.info(
      'startup.orientation.requested ${startup.elapsedMilliseconds}ms');

  Loggers.info('startup.storage.init.start ${startup.elapsedMilliseconds}ms');
  await GetStorage.init();
  Loggers.info('startup.storage.init.done ${startup.elapsedMilliseconds}ms');
  SessionManager.shared;
  Loggers.info('startup.session.ready ${startup.elapsedMilliseconds}ms');
  // 全局收藏状态唯一真相（permanent：登录/登出/401 全生命周期常驻，内部按 token 自管理）
  Get.put(BookmarkStore(), permanent: true);
  // 访客会话（permanent）：启动分流检测 + 访客态/能力矩阵唯一来源
  Get.put(GuestSession(), permanent: true);
  // 全局聊天未读数（permanent）：底部 Tab 红点唯一真相，WS 事件防抖对账
  Get.put(ChatUnreadStore(), permanent: true);
  Loggers.info(
      'startup.global-managers.ready ${startup.elapsedMilliseconds}ms');

  final previousFlutterErrorHandler = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.library == 'image resource service' &&
        (details.exception.toString().contains('404') ||
            details.exception.toString().contains('403'))) {
      return;
    }

    final handler = previousFlutterErrorHandler;
    Loggers.error(
        'startup.flutter-error ${details.exception}\\n${details.stack}');
    if (handler != null) {
      handler(details);
    } else {
      FlutterError.presentError(details);
    }
  };
  // 全局 401：token 失效时断开实时连接并回到登录页
  ColibriApi.onUnauthorized = () {
    BookmarkStore.i.reset();
    ChatUnreadStore.i.reset();
    ReverbService.shared.disconnect();
    Get.offAll(() => const LoginScreen());
  };
  AppCommandHandler.shared.register();
  ReverbService.shared.subscribePublicCommands();
  PresenceManager.shared.register();
  Loggers.info('startup.managers.registered ${startup.elapsedMilliseconds}ms');

  runApp(const MyApp());
  Loggers.info('startup.runApp.returned ${startup.elapsedMilliseconds}ms');
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Loggers.info('startup.first-frame ${startup.elapsedMilliseconds}ms');
    unawaited(_initializeOptionalServices());
  });
}

Future<void> _initializeOptionalServices() async {
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (error, stackTrace) {
    Loggers.error('Firebase initialization failed: $error\\n$stackTrace');
  }

  try {
    final packageInfo = await PackageInfo.fromPlatform();
    ColibriApi.appVersion = packageInfo.version.trim();
  } catch (error, stackTrace) {
    Loggers.error('Package info initialization failed: $error\\n$stackTrace');
  }

  try {
    final audioSession = await AudioSession.instance;
    await audioSession.configure(
      const AudioSessionConfiguration.speech(),
    );
  } catch (error, stackTrace) {
    Loggers.error('Audio session initialization failed: $error\\n$stackTrace');
  }

  try {
    HapticManager.shared.init();
    fvp.registerWith();
  } catch (error, stackTrace) {
    Loggers.error('Media service initialization failed: $error\\n$stackTrace');
  }

  ReverbService.shared.connect();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Loggers.info('startup.my-app.build');
    Functions.changStatusBar(StatusBarStyle.black);
    Lang lang = SessionManager.shared.getLang();

    return GetMaterialApp(
      translations: Languages(),
      locale: lang.language.local,
      builder: (context, child) {
        return ScrollConfiguration(behavior: MyScrollBehavior(), child: child!);
      },
      fallbackLocale: LANGUAGES.first.language.local,
      debugShowCheckedModeBanner: false,
      customTransition: ColibriPageTransition(),
      transitionDuration: const Duration(milliseconds: 360),
      title: appName,
      theme: ThemeData(
        useMaterial3: false,
        primaryColor: cPrimary,
        colorScheme: const ColorScheme.light(
          primary: cPrimary,
          secondary: cPrimary,
          surface: cWhite,
          error: cRed,
        ),
        scaffoldBackgroundColor: cWhite,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SplashScreenView(),
    );
  }
}

class MyScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

import 'package:flutter/material.dart';

const String appName = "Chatter";
const String baseURL = "https://ad.mariawk.cn/";
const String itemBaseURL = "";
const String apiURL = "${baseURL}api/";
const String wsURL = "wss://ad.mariawk.cn/ws";
const String termsURL = "${baseURL}termsOfUse";
const String privacyURL = "${baseURL}privacyPolicy";
const String helpURL = "http://www.yourHelpURL.com";
const String notificationTopic = "chatter"; // Do not change it

// ===== ColibriPlus 后端（Flutter App 对接，替代 chatter_backend）=====
// 认证：Sanctum Bearer token；token 存 SessionManager。
const String colibriApiBase = "https://mariawk.cn/api/";

// 客户端请求密钥（X-App-Key，攻击者可从 APK/抓包提取，属"官方客户端标识"
// 而非机密；服务端白名单可轮换，泄露即踢 — 见后端 config/security.php）
const String colibriAppApiKey = "clbPK-8f3k2m9xq4w7v1t6a5s0d2n8h4j6y1c";

// ColibriPlus 实时通道（Laravel Reverb / pusher 协议）
const String colibriWsUrl =
    "wss://mariawk.cn/app/nhxjwwd3w1stvi8xv11d?protocol=7&client=flutter&version=1.0";

const String revenuecatAppleApiKey = '';
const String revenuecatAndroidApiKey = '';

const String agoraAppId = 'd943b9658d3a4d7bb505fe50cd520936';
// Agora customer credentials are backend-only and are never embedded in the app.

class Limits {
  static int username = 30;
  static int roomDescCount = 120;
  static int bioCount = 120;
  static int interestCount = 5;
  static int pagination = 20;
  static int storyDuration = 3;

  static double imageSize = 720;
  static int quality = 50;
}

const List<String> storyQuickReplyEmojis = ['😂', '😮', '😍', '😢', '👏', '🔥'];
const List<int> secondsForMakingReel = [15, 30];

extension O on String {
  String addBaseURL() {
    return itemBaseURL + this;
  }
}

// Colors
// Neutral glass palette: white surfaces, charcoal content, and restrained status colors.
const cPrimary = Color(0xFF1D1D1F);
const cPulsing = Color(0xFFB8BCC4);
const cHashtagColor = Color(0xFF1D1D1F);
const cWhite = Colors.white;
const cBlack = Color(0xFF0E0E0E);
const cBlackSheetBG = Color(0xFF1F1F1F);
const cMainText = Color(0xFF2D2D2D);
const cLightText = Color(0xFF8A8F98);
const cLightIcon = Color(0xFF9DA3AD);
const cDarkText = Color(0xFF4A4D53);
const cLightBg = Color(0xFFE9EBEF);
const cDarkBG = Color(0xFF212121);
const cBG = Color(0xFFF7F8FA);
const cGreen = Color(0xFF1D1D1F);
const cDarkGreen = Color(0xFF34363B);
const cBlueTick = Color(0xFF1D9BF0);
const cRed = Color(0xFFFF3939);

// Neutral glass tokens used for selected states and soft surfaces.
const cPrimarySoft = Color(0xFFE9EBEF);
const cGradientGreen1 = Color(0xFFF8F9FB);
const cGradientGreen2 = Color(0xFFB9BEC7);

const cAudioSpaceBG = Color(0xFF272727);
const cAudioSpaceDarkBG = Color(0xFF222222);
const cAudioSpaceLightBG = Color(0xFF3B3B3B);
const cAudioSpaceText = Color(0xFFD4D4D4);

const refreshIndicatorColor = cBlack;
const refreshIndicatorBgColor = cPrimary;

// Corner Radius-Smoothing
const cornerSmoothing = 1.0;

// Floating Liquid Glass tab bar reserved space (bar height + bottom gap),
// excluding the device safe-area inset. Used to lift FABs above the glass bar.
const double kLiquidNavBarReservedHeight = 80.0;

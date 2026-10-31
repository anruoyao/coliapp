import 'dart:async';

import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_api.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/string_extension.dart';
import 'package:untitled/common/managers/guest_session.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/colibri_feed/colibri_feed_screen.dart';
import 'package:untitled/screens/colibri_home/colibri_home_screen.dart';
import 'package:untitled/screens/extra_views/logo_tag.dart';
import 'package:untitled/screens/rooms_you_own/create_room_screen/create_room_screen.dart';
import 'package:untitled/utilities/const.dart';

/// ColibriPlus 认证弹窗：登录 / 注册（两步：基本信息 → 邮箱验证码）/ 忘记密码。
class SignInWithEmailScreen extends StatefulWidget {
  /// 初始面板类型（访客引导的「创建新账号」入口直接展开注册）。
  final EmailSignInType initialType;

  const SignInWithEmailScreen(
      {Key? key, this.initialType = EmailSignInType.signIn})
      : super(key: key);

  @override
  State<SignInWithEmailScreen> createState() => _SignInWithEmailScreenState();
}

class _SignInWithEmailScreenState extends State<SignInWithEmailScreen>
    with SingleTickerProviderStateMixin {
  TextEditingController emailController = TextEditingController();
  TextEditingController fullNameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final FocusNode codeFocusNode = FocusNode();

  EmailSignInType type = EmailSignInType.signIn;
  BaseController baseController = BaseController();
  var height = Get.height / 40;

  // ===== 注册第二步：邮箱验证码 =====
  int signUpStep = 1;
  ColibriAuthConfig? authConfig;
  Timer? codeTimer;
  int resendInSeconds = 0; // 重发冷却剩余
  int codeTtlSeconds = 0; // 验证码有效期剩余
  String? codeError; // 验证码行内错误

  bool get isCodeExpired => codeTtlSeconds <= 0;

  @override
  void initState() {
    type = widget.initialType;
    emailController.addListener(refresh);
    fullNameController.addListener(refresh);
    usernameController.addListener(refresh);
    passwordController.addListener(refresh);
    confirmPasswordController.addListener(refresh);
    codeController.addListener(() => onCodeChanged(codeController.text));
    codeFocusNode.addListener(refresh);
    super.initState();
  }

  @override
  void dispose() {
    codeTimer?.cancel();
    emailController.dispose();
    fullNameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    codeController.dispose();
    codeFocusNode.dispose();
    super.dispose();
  }

  void refresh() {
    setState(() {});
  }

  void onCodeChanged(String value) {
    // 输入新码时清除上一次错误（即时反馈）
    if (codeError != null) {
      setState(() => codeError = null);
    } else {
      setState(() {});
    }
    if (value.length == 6) {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ClipSmoothRect(
        radius: const SmoothBorderRadius.only(
            topRight: SmoothRadius(
                cornerRadius: 12, cornerSmoothing: cornerSmoothing),
            topLeft: SmoothRadius(
                cornerRadius: 12, cornerSmoothing: cornerSmoothing)),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Container(
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: GestureDetector(
                        child: const Icon(
                          Icons.close_rounded,
                          color: cBlack,
                          size: 30,
                        ),
                        onTap: () {
                          Get.back();
                        },
                      ),
                    ),
                    const Spacer()
                  ],
                ),
                Expanded(
                    child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      const LogoTag(width: 100),
                      const SizedBox(height: 40),
                      getTitle().toTextTR(MyTextStyle.gilroyBold(size: 23)),
                      const SizedBox(height: 20),
                      view(),
                      const SizedBox(height: 20),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget view() {
    switch (type) {
      case EmailSignInType.signIn:
        return signView();
      case EmailSignInType.signUp:
        return signUpView();
      case EmailSignInType.forgot:
        return forgotView();
    }
  }

  String getTitle() {
    switch (type) {
      case EmailSignInType.signIn:
        return LKeys.signInWithEmail;
      case EmailSignInType.signUp:
        return signUpStep == 2 ? '验证邮箱' : LKeys.register;
      case EmailSignInType.forgot:
        return LKeys.forgotPassword;
    }
  }

  // ===== 登录：POST /api/sanctum/token → token → bootstrap 用户 → 进主界面 =====
  Future<void> _doLogin() async {
    if (baseController.isLoading.value) return;
    baseController.startLoading();
    try {
      final token = await ColibriApi.shared.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      SessionManager.shared.setToken(token);

      final user = await ColibriApi.shared.fetchBootstrapUser();
      SessionManager.shared.setColibriUser(user);
      SessionManager.shared.setLogin(true);

      baseController.stopLoading();
      _enterLoggedInHome();
    } on ColibriApiException catch (e) {
      baseController.stopLoading();
      baseController.showSnackBar(_mapAuthError(e.message),
          type: SnackBarType.error);
    } catch (e) {
      baseController.stopLoading();
      baseController.showSnackBar(e.toString(), type: SnackBarType.error);
    }
  }

  /// 登录/注册成功进入主界面：退出访客态，并清除访客态残留的 Feed 控制器，
  /// 使主界面重建后以登录态重新拉取（无整页刷新感的状态转化）。
  void _enterLoggedInHome() {
    GuestSession.i.markLoggedIn();
    if (Get.isRegistered<ColibriFeedController>()) {
      Get.delete<ColibriFeedController>();
    }
    Get.offAll(() => const ColibriHomeScreen());
  }

  /// 把后端英文认证错误映射成中文（colibri 的 Sanctum 错误是英文）。
  String _mapAuthError(String msg) {
    final m = msg.trim().toLowerCase();
    if (m.contains('credentials are incorrect') ||
        m.contains('invalid credentials') ||
        m.contains('password')) {
      return '邮箱或密码不正确';
    }
    if (m.contains('unauthorized') || m.contains('unauthenticated')) {
      return '登录状态已失效，请重新登录';
    }
    if (m.contains('too many attempts') || m.contains('throttl')) {
      return '尝试次数过多，请稍后再试';
    }
    return msg;
  }

  // ===== 注册第一步：本地校验 → 拉后端开关 → 直接注册 或 发码进第二步 =====
  Future<void> _onSignUpContinue() async {
    if (baseController.isLoading.value) return;

    // 即时本地校验（规则与后端对齐）
    final fullName = fullNameController.text.trim();
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final minLen = authConfig?.passwordMin ?? 8;

    if (fullName.length < 2) {
      _toast('昵称至少需要 2 个字符');
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9._]{2,32}$').hasMatch(username)) {
      _toast('用户名只能包含字母、数字、点或下划线（2-32 位）');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _toast('请输入正确的邮箱地址');
      return;
    }
    if (password.length < minLen) {
      _toast('密码至少需要 $minLen 个字符');
      return;
    }
    if (password != confirmPasswordController.text) {
      _toast(LKeys.passwordMismatched.tr);
      return;
    }

    baseController.startLoading();
    // 检测后端是否开启邮箱验证（失败可重试；开关状态决定走第二页还是直接注册）
    final config = await _ensureAuthConfig();
    if (config == null) {
      baseController.stopLoading();
      return;
    }

    if (!config.registrationEnabled) {
      baseController.stopLoading();
      _toast('注册功能当前已关闭，请稍后再试');
      return;
    }

    if (!config.emailVerificationEnabled) {
      // 后端未开启邮箱验证：沿用即注册即登录（_doRegister 自管 loading，先关掉当前的）
      baseController.stopLoading();
      await _doRegister();
      return;
    }

    // 开启验证：先发送验证码，成功后进入第二页
    await _sendCode(initial: true);
    baseController.stopLoading();
  }

  /// 拉取注册开关配置（单次会话内缓存）。网络失败返回 null，由调用方保留当前页供重试。
  Future<ColibriAuthConfig?> _ensureAuthConfig() async {
    final cached = authConfig;
    if (cached != null) return cached;
    try {
      final config = await ColibriApi.shared.fetchAuthConfig();
      authConfig = config;
      return config;
    } on ColibriApiException catch (e) {
      _toast('网络异常，请检查后重试：${e.message}');
      return null;
    } catch (e) {
      _toast('网络异常：$e');
      return null;
    }
  }

  /// 发送/重发验证码。[initial]=true 为第一步进入第二步；false 为第二页重发。
  Future<void> _sendCode({required bool initial}) async {
    final email = emailController.text.trim();
    try {
      final result = await ColibriApi.shared.sendRegistrationCode(
        email: email,
        resend: !initial,
      );
      if (!mounted) return;

      codeController.clear();
      setState(() {
        codeError = null;
        signUpStep = 2;
      });
      _startCountdowns(
          ttl: result.codeExpiresIn, cooldown: result.resendCooldown);

      if (!initial) {
        _toast('验证码已重新发送，请查收邮件', error: false);
      }
      // 进入验证码页后自动唤起数字键盘
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) codeFocusNode.requestFocus();
      });
    } on ColibriApiException catch (e) {
      // 重发冷却：以服务端剩余秒数为准同步倒计时
      if (e.statusCode == 429 && e.data?['time_left'] != null) {
        final left = (e.data!['time_left'] as num).toInt();
        if (initial) {
          // 首次发送即冷却（极少，如重复提交）：仍进入第二步等待
          setState(() => signUpStep = 2);
          _startCountdowns(
              ttl: authConfig?.codeExpiresSeconds ?? 600, cooldown: left);
        } else {
          _startCountdowns(
              ttl: codeTtlSeconds > 0 ? codeTtlSeconds : 60, cooldown: left);
        }
        return;
      }
      _toast(_fieldErrorMessage(e) ?? e.message);
    } catch (e) {
      _toast('网络异常：$e');
    }
  }

  // ===== 注册第二步：提交验证码完成注册 =====
  Future<void> _completeRegistration() async {
    if (baseController.isLoading.value) return;
    final code = codeController.text.trim();

    if (code.length != 6) {
      setState(() => codeError = '请输入 6 位验证码');
      return;
    }
    if (isCodeExpired) {
      setState(() => codeError = '验证码已过期，请重新获取');
      return;
    }

    await _doRegister(emailCode: code);
  }

  /// 真正调用注册接口：POST /api/auth/register（即注册即登录）。
  Future<void> _doRegister({String? emailCode}) async {
    baseController.startLoading();
    try {
      final result = await ColibriApi.shared.register(
        firstName: fullNameController.text.trim(),
        username: usernameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        emailCode: emailCode,
      );
      SessionManager.shared.setToken(result.token);
      SessionManager.shared.setColibriUser(result.user);
      SessionManager.shared.setLogin(true);

      baseController.stopLoading();
      _enterLoggedInHome();
    } on ColibriApiException catch (e) {
      baseController.stopLoading();
      // 验证码错误：在第二页输入框下方行内提示（错误/过期/尝试次数过多）
      final codeFieldMsg = e.errors?['email_code'];
      if (signUpStep == 2 && codeFieldMsg is List && codeFieldMsg.isNotEmpty) {
        setState(() {
          codeError = codeFieldMsg.map((m) => '$m').join('\n');
          codeController.clear();
        });
        codeFocusNode.requestFocus();
        return;
      }
      // 其余展示服务器字段级错误（如用户名/邮箱已被占用）
      final msg = _fieldErrorMessage(e);
      _toast(msg ?? e.message);
    } catch (e) {
      baseController.stopLoading();
      _toast('网络异常：$e');
    }
  }

  /// 提取服务端字段级错误（含 email_code / email / username 等）。
  String? _fieldErrorMessage(ColibriApiException e) {
    final errors = e.errors;
    if (errors == null || errors.isEmpty) return null;
    final msgs = errors.values
        .expand((v) => v is List ? v.map((m) => '$m') : <String>['$v'])
        .toList();
    return msgs.isEmpty ? null : msgs.join('\n');
  }

  void _toast(String message, {bool error = true}) {
    baseController.showSnackBar(message,
        type: error ? SnackBarType.error : SnackBarType.success);
  }

  // ===== 验证码倒计时 =====
  void _startCountdowns({required int ttl, required int cooldown}) {
    codeTimer?.cancel();
    setState(() {
      codeTtlSeconds = ttl;
      resendInSeconds = cooldown;
    });
    codeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (codeTtlSeconds > 0) codeTtlSeconds--;
        if (resendInSeconds > 0) resendInSeconds--;
      });
    });
  }

  void _backToStep1() {
    codeTimer?.cancel();
    setState(() {
      signUpStep = 1;
      codeError = null;
      codeController.clear();
      codeTtlSeconds = 0;
      resendInSeconds = 0;
    });
  }

  // ===== 忘记密码：POST /api/auth/forgot-password =====
  Future<void> _doForgot() async {
    if (baseController.isLoading.value) return;
    baseController.startLoading();
    try {
      await ColibriApi.shared
          .forgotPassword(email: emailController.text.trim());
      baseController.stopLoading();
      baseController.showSnackBar(LKeys.linkSendToReset.tr,
          type: SnackBarType.success);
      setState(() {
        type = EmailSignInType.signIn;
      });
    } on ColibriApiException catch (e) {
      baseController.stopLoading();
      baseController.showSnackBar(e.message, type: SnackBarType.error);
    } catch (e) {
      baseController.stopLoading();
      baseController.showSnackBar(e.toString(), type: SnackBarType.error);
    }
  }

  Widget signView() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          MyTextField(controller: emailController, placeHolder: LKeys.email),
          const SizedBox(height: 12),
          SecureTextField(
            controller: passwordController,
            placeHolder: LKeys.password,
          ),
          EmailButton(
              text: LKeys.continue_.tr,
              isDisable: emailController.text.isEmpty ||
                  passwordController.text.isEmpty,
              onTap: _doLogin),
          Row(
            children: [
              LKeys.doNtHaveAnAccount.toTextTR(
                  MyTextStyle.gilroyLight(color: cLightText, size: 14)),
              const SizedBox(width: 5),
              GestureDetector(
                onTap: showSignUp,
                child: LKeys.signUp.toTextTR(
                    MyTextStyle.gilroySemiBold(color: cBlack, size: 14)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: showForgot,
                child: LKeys.forgotPassword.toTextTR(
                    MyTextStyle.gilroySemiBold(color: cBlack, size: 14)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget forgotView() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          LKeys.forgotPasswordDisc.toTextTR(
            MyTextStyle.gilroyLight(color: cLightText, size: 14),
          ),
          const SizedBox(height: 10),
          MyTextField(controller: emailController, placeHolder: LKeys.email),
          EmailButton(
              text: LKeys.reset.tr,
              isDisable: emailController.text.isEmpty,
              onTap: _doForgot),
          Row(
            children: [
              LKeys.doNtHaveAnAccount.toTextTR(
                  MyTextStyle.gilroyLight(color: cLightText, size: 14)),
              const SizedBox(width: 5),
              GestureDetector(
                onTap: showSignUp,
                child: LKeys.signUp.toTextTR(
                    MyTextStyle.gilroySemiBold(color: cBlack, size: 14)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: showForgot,
                child: LKeys.forgotPassword.toTextTR(
                    MyTextStyle.gilroySemiBold(color: cBlack, size: 14)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget signUpView() {
    return signUpStep == 2 ? signUpStep2View() : signUpStep1View();
  }

  /// 注册第一页：账号基本信息（验证码在第二页，避免单页信息过载）。
  Widget signUpStep1View() {
    final fieldsFilled = fullNameController.text.isNotEmpty &&
        usernameController.text.isNotEmpty &&
        emailController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        confirmPasswordController.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 步骤指示
          Row(
            children: [
              _StepDot(active: true, label: '1'),
              Container(
                  width: 26,
                  height: 1,
                  color: cLightText.withValues(alpha: 0.4)),
              _StepDot(active: false, label: '2'),
              const SizedBox(width: 8),
              Text('填写账号信息',
                  style: MyTextStyle.gilroyLight(color: cLightText, size: 12)),
            ],
          ),
          const SizedBox(height: 16),
          // 昵称：即你的称呼，会显示在个人主页和帖子旁。必填（≥2字符）。
          _FieldWithHint(
            label: '昵称',
            helper: '你的称呼，会显示在主页和帖子旁',
            field: MyTextField(
                controller: fullNameController, placeHolder: '请输入昵称'),
          ),
          const SizedBox(height: 12),
          // 用户名 @xxx：别人@你/搜索你用的唯一账号。必填，仅限拉丁字母、数字、点和下划线。
          _FieldWithHint(
            label: '用户名',
            helper: '只能包含拉丁字母、数字、点和下划线，全站唯一',
            field: MyTextField(
                controller: usernameController, placeHolder: LKeys.username),
          ),
          const SizedBox(height: 12),
          // 邮箱：登录账号，全站唯一，用于接收验证码。必填。
          _FieldWithHint(
            label: '邮箱',
            helper: '用于登录和接收验证码，全站唯一',
            field: MyTextField(
                controller: emailController, placeHolder: LKeys.email),
          ),
          const SizedBox(height: 12),
          // 密码：登录用，需满足最小长度。必填。
          _FieldWithHint(
            label: '密码',
            helper: '至少 ${authConfig?.passwordMin ?? 8} 个字符',
            field: SecureTextField(
              controller: passwordController,
              placeHolder: LKeys.password,
            ),
          ),
          const SizedBox(height: 12),
          // 确认密码：需与上面密码一致。必填。
          SecureTextField(
            controller: confirmPasswordController,
            placeHolder: LKeys.confirmPassword,
          ),
          EmailButton(
            text: (authConfig?.emailVerificationEnabled ?? false)
                ? '继续'
                : LKeys.register,
            isDisable: !fieldsFilled,
            onTap: _onSignUpContinue,
          ),
          Row(
            children: [
              LKeys.iHaveAnAccount.toTextTR(
                  MyTextStyle.gilroyLight(color: cLightText, size: 14)),
              const SizedBox(width: 5),
              GestureDetector(
                onTap: showSignIn,
                child: LKeys.signIn.toTextTR(
                    MyTextStyle.gilroySemiBold(color: cBlack, size: 14)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: showForgot,
                child: LKeys.forgotPassword.toTextTR(
                    MyTextStyle.gilroySemiBold(color: cBlack, size: 14)),
              ),
            ],
          )
        ],
      ),
    );
  }

  /// 注册第二页：邮箱验证码。
  Widget signUpStep2View() {
    final email = emailController.text.trim();
    final canConfirm = codeController.text.trim().length == 6 && !isCodeExpired;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 返回第一页修改信息
          GestureDetector(
            onTap: baseController.isLoading.value ? null : _backToStep1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 14, color: cBlack),
                const SizedBox(width: 4),
                Text('返回修改',
                    style: MyTextStyle.gilroyMedium(color: cBlack, size: 13)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                  color: cPrimarySoft, shape: BoxShape.circle),
              child: const Icon(Icons.mark_email_read_outlined,
                  color: cGreen, size: 30),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              '验证码已发送至',
              style: MyTextStyle.gilroyLight(color: cLightText, size: 13),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              email,
              style: MyTextStyle.gilroySemiBold(color: cMainText, size: 15),
            ),
          ),
          const SizedBox(height: 24),
          _OtpInput(
            controller: codeController,
            focusNode: codeFocusNode,
            length: 6,
            hasError: codeError != null,
          ),
          // 错误 / 有效期提示
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
            child: Text(
              codeError ??
                  (isCodeExpired
                      ? '验证码已过期，请点击下方「重新发送」'
                      : '验证码 ${_formatSeconds(codeTtlSeconds)} 内有效，请勿泄露给他人'),
              style: MyTextStyle.gilroyLight(
                color: codeError != null || isCodeExpired ? cRed : cLightText,
                size: 12,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 重新发送（冷却倒计时）
          Center(
            child: GestureDetector(
              onTap: (resendInSeconds > 0 || baseController.isLoading.value)
                  ? null
                  : () async {
                      baseController.startLoading();
                      await _sendCode(initial: false);
                      baseController.stopLoading();
                    },
              child: Text(
                resendInSeconds > 0
                    ? '重新发送（${_formatSeconds(resendInSeconds)}）'
                    : '没收到验证码？重新发送',
                style: MyTextStyle.gilroySemiBold(
                  color: resendInSeconds > 0 ? cLightText : cHashtagColor,
                  size: 13,
                ),
              ),
            ),
          ),
          EmailButton(
            text: '完成注册',
            isDisable: !canConfirm,
            onTap: _completeRegistration,
          ),
          Center(
            child: Text(
              '没收到邮件？请检查垃圾邮件或广告文件夹',
              style: MyTextStyle.gilroyLight(color: cLightText, size: 11),
            ),
          ),
        ],
      ),
    );
  }

  String _formatSeconds(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void showSignIn() {
    codeTimer?.cancel();
    setState(() {
      type = EmailSignInType.signIn;
      signUpStep = 1;
    });
  }

  void showSignUp() {
    setState(() {
      type = EmailSignInType.signUp;
      signUpStep = 1;
    });
  }

  void showForgot() {
    codeTimer?.cancel();
    setState(() {
      type = EmailSignInType.forgot;
      signUpStep = 1;
    });
  }
}

class EmailButton extends StatelessWidget {
  final String text;
  final bool isDisable;
  final Function() onTap;

  const EmailButton(
      {Key? key,
      required this.text,
      required this.onTap,
      required this.isDisable})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          if (!isDisable) {
            onTap();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDisable ? cLightText.withValues(alpha: 0.4) : cPrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
          margin: const EdgeInsets.only(bottom: 15, top: 15),
          alignment: Alignment.center,
          width: double.infinity,
          child: Text(
            text.tr,
            style: MyTextStyle.gilroySemiBold(color: Colors.white),
          ),
        ));
  }
}

enum EmailSignInType { signIn, signUp, forgot }

class SecureTextField extends StatefulWidget {
  final String placeHolder;
  final TextEditingController controller;

  const SecureTextField(
      {Key? key, required this.placeHolder, required this.controller})
      : super(key: key);

  @override
  State<SecureTextField> createState() => _SecureTextFieldState();
}

class _SecureTextFieldState extends State<SecureTextField> {
  bool isShowPassword = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MyTextField(
          controller: widget.controller,
          placeHolder: widget.placeHolder,
          obscureText: isShowPassword,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          height: 45,
          child: Row(
            children: [
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    isShowPassword = !isShowPassword;
                  });
                },
                child: Icon(
                  isShowPassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: cLightText,
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}

/// 带「标签 + 说明」的表单字段：让用户清楚每个填什么、有什么限制。
class _FieldWithHint extends StatelessWidget {
  final String label;
  final String helper;
  final Widget field;

  const _FieldWithHint(
      {required this.label, required this.helper, required this.field});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: MyTextStyle.gilroyMedium(color: cMainText, size: 13)),
        const SizedBox(height: 6),
        field,
        const SizedBox(height: 4),
        Text(helper,
            style: MyTextStyle.gilroyLight(color: cLightText, size: 11)),
      ],
    );
  }
}

/// 注册步骤指示圆点。
class _StepDot extends StatelessWidget {
  final bool active;
  final String label;

  const _StepDot({required this.active, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? cPrimary : Colors.transparent,
        border: Border.all(color: active ? cPrimary : cLightText, width: 1),
      ),
      child: Text(
        label,
        style: MyTextStyle.gilroySemiBold(
            size: 11, color: active ? cBlack : cLightText),
      ),
    );
  }
}

/// 6 位验证码输入框：等分格子 + 单个透明 TextField 承载真实输入。
///
/// 用透明的真实 TextField 覆盖在格子层之上，保证：
/// 数字键盘、光标、粘贴、系统自动填充等原生行为全部可用，
/// 格子仅作展示，适配不同屏幕宽度（每格 Expanded 等分）。
class _OtpInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final bool hasError;

  const _OtpInput({
    required this.controller,
    required this.focusNode,
    this.length = 6,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final code = controller.text;
    final focused = focusNode.hasFocus;

    final cells = List<Widget>.generate(length, (i) {
      final filled = i < code.length;
      // 当前待输入位置高亮（聚焦且码长正好停在此格）
      final isActive = focused && i == code.length && !hasError;

      return Expanded(
        child: Container(
          margin: EdgeInsets.only(right: i == length - 1 ? 0 : 8),
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cLightBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasError
                  ? cRed
                  : isActive
                      ? cHashtagColor
                      : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            filled ? code.substring(i, i + 1) : '',
            style: MyTextStyle.gilroyBold(size: 20, color: cMainText),
          ),
        ),
      );
    });

    return GestureDetector(
      onTap: () {
        if (!focusNode.hasFocus) focusNode.requestFocus();
      },
      child: Stack(
        children: [
          Row(children: cells),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLength: length,
                autofocus: false,
                showCursor: false,
                enableSuggestions: false,
                autocorrect: false,
                style: const TextStyle(color: Colors.transparent, height: 0.01),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:untitled/common/managers/bookmark_store.dart';
import 'package:untitled/common/managers/chat_unread_store.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/utilities/const.dart';
import 'package:uuid/uuid.dart';

/// ColibriPlus API 异常（HTTP 错误 / 校验失败 / 网络异常统一归一）。
class ColibriApiException implements Exception {
  final int? statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  /// 失败响应里的 data 字段（如验证码重发冷却 429 携带的 time_left）。
  final Map<String, dynamic>? data;

  ColibriApiException(this.message, {this.statusCode, this.errors, this.data});

  @override
  String toString() => message;
}

/// ColibriPlus 后端 API 封装（替代 chatter_backend 的 ApiService）。
///
/// 认证方式：Sanctum Bearer token（存于 SessionManager）。
/// 所有业务请求自动带 `Authorization: Bearer <token>`；登录接口除外。
/// 响应约定：成功 2xx 返回 body；失败（4xx/5xx/网络）抛 [ColibriApiException]。
class ColibriApi {
  static final shared = ColibriApi();

  /// 全局 401 处理回调（token 失效时由外部注册，如跳转登录页）。
  static void Function()? onUnauthorized;

  /// 全局封禁处理回调（服务端返回 X-User-Status 头 / 登录 403 user_status 时触发）。
  /// 参数：user_status（blocked/suspended）、原因。
  static void Function(String status, String? reason)? onUserStatusBlocked;

  /// 全局维护处理回调（服务端返回 X-Maintenance 头时触发）。
  /// 参数：维护公告 message、预计恢复时间 until（ISO8601，可能为 null）。
  static void Function(String? message, String? until)? onMaintenance;

  /// 全局强制更新回调（服务端 426 + X-Require-Update 时触发，危险版本下线）。
  /// 参数为后端返回的最新版本信息（download_url / latest / notes / min_supported_version）。
  static void Function(Map<String, dynamic> info)? onRequireUpdate;

  /// 当前 App 版本代号（如 1.0.0），启动时由 PackageInfo 赋值。
  /// 随每个请求携带 X-App-Version，供服务端「最低安全版本」比对。
  static String appVersion = '';

  /// App 设备唯一标识（UUID，GetStorage 持久化）。
  /// 随每个请求携带 X-Client-Id，供服务端会话级在线区分多端（P0 在线用户数）。
  static String? _clientId;

  static String get clientId {
    if (_clientId == null) {
      _clientId = GetStorage().read<String>('colibri_client_id');
      if (_clientId == null || _clientId!.isEmpty) {
        _clientId = const Uuid().v4();
        GetStorage().write('colibri_client_id', _clientId);
      }
    }
    return _clientId!;
  }

  /// 共享 client：复用 keep-alive 连接池。
  final http.Client _client = http.Client();

  static const _timeout = Duration(seconds: 20);

  Map<String, String> _headers({bool auth = true}) {
    final h = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      // 版本上报：危险版本下线（服务端按最低安全版本拦截）
      'X-App-Version': appVersion,
      'X-App-Platform': Platform.isIOS ? 'ios' : 'android',
      // 设备标识：会话级在线区分（P0 在线用户数）
      'X-Client-Id': clientId,
      // 设备 Cookie：服务端按 device_id 做帖子浏览量去重（Viewable，24h 内同设备同帖只计一次）。
      // App 不维护 Cookie Jar，这里在每个请求上手动带上持久化的同一设备 UUID。
      'Cookie': 'device_id=$clientId',
      // 客户端请求密钥：准入门槛 + 击杀开关（服务端白名单校验，详见 const.dart 注释）
      'X-App-Key': colibriAppApiKey,
    };
    if (auth) {
      final t = SessionManager.shared.getToken();
      if (t != null && t.isNotEmpty) {
        h['Authorization'] = 'Bearer $t';
      }
    }
    return h;
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
    bool auth = true,
  }) async {
    var uri = Uri.parse('$colibriApiBase$path');
    if (query != null && query.isNotEmpty) {
      uri =
          uri.replace(queryParameters: query.map((k, v) => MapEntry(k, '$v')));
    }

    try {
      http.Response response;
      switch (method) {
        case 'GET':
          response = await _client
              .get(uri, headers: _headers(auth: auth))
              .timeout(_timeout);
          break;
        case 'POST':
          response = await _client
              .post(uri,
                  headers: _headers(auth: auth),
                  body: jsonEncode(body ?? const <String, dynamic>{}))
              .timeout(_timeout);
          break;
        case 'PUT':
          response = await _client
              .put(uri,
                  headers: _headers(auth: auth),
                  body: jsonEncode(body ?? const <String, dynamic>{}))
              .timeout(_timeout);
          break;
        case 'DELETE':
          response = await _client
              .delete(uri,
                  headers: _headers(auth: auth),
                  body: body == null ? null : jsonEncode(body))
              .timeout(_timeout);
          break;
        default:
          throw ColibriApiException('Unsupported method: $method');
      }

      final decoded = _decodeBody(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded is Map<String, dynamic>
            ? decoded
            : <String, dynamic>{'data': decoded};
      }

      // 失败：优先取 colibri 响应里的 message / errors
      String message = '请求失败（HTTP ${response.statusCode}）';
      Map<String, dynamic>? errors;
      Map<String, dynamic>? errorData;
      bool hasServerMessage = false;
      if (decoded is Map<String, dynamic>) {
        if (decoded['message'] != null) {
          message = decoded['message'].toString();
          hasServerMessage = true;
        }
        if (decoded['errors'] is Map)
          errors = Map<String, dynamic>.from(decoded['errors'] as Map);
        if (decoded['data'] is Map)
          errorData = Map<String, dynamic>.from(decoded['data'] as Map);
      }

      // 429：限流。服务端已统一返回中文文案（「操作过于频繁，请稍后再试」或带
      // 等待秒数的「操作过于频繁，请 N 秒后再试」），直接透传；仅无 message 时本地兜底
      if (response.statusCode == 429 && !hasServerMessage) {
        message = '操作过于频繁，请稍后再试';
      }

      // 401：token 失效，清理本地会话并触发全局登出回调
      if (response.statusCode == 401 && auth) {
        SessionManager.shared.setToken('');
        SessionManager.shared.setLogin(false);
        onUnauthorized?.call();
      }

      // 封禁/停用：服务端中间件返回 X-User-Status 头，触发全局封禁页跳转（拉兜底）
      final userStatus = response.headers['x-user-status'];
      if (userStatus == 'blocked' || userStatus == 'suspended') {
        String? reason;
        if (decoded is Map<String, dynamic>) {
          final d = decoded['data'];
          if (d is Map<String, dynamic>) reason = d['reason']?.toString();
        }
        onUserStatusBlocked?.call(userStatus!, reason);
      }

      // 维护模式：服务端中间件返回 X-Maintenance 头，触发全局维护页跳转（拉兜底）
      if (response.headers['x-maintenance'] == '1') {
        String? message;
        String? until;
        if (decoded is Map<String, dynamic>) {
          message = decoded['message']?.toString();
          final d = decoded['data'];
          if (d is Map<String, dynamic>) until = d['until']?.toString();
        }
        onMaintenance?.call(message, until);
      }

      // 危险版本下线：426 + X-Require-Update，触发全局强制更新页
      if (response.headers['x-require-update'] == '1') {
        final d = decoded is Map<String, dynamic> ? decoded['data'] : null;
        if (d is Map<String, dynamic>) onRequireUpdate?.call(d);
      }

      throw ColibriApiException(message,
          statusCode: response.statusCode, errors: errors, data: errorData);
    } on ColibriApiException {
      rethrow;
    } on Exception catch (e) {
      throw ColibriApiException('网络异常：$e');
    }
  }

  dynamic _decodeBody(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      // 纯文本响应（如 sanctum/token 直接返回 token 字符串）
      return body;
    }
  }

  Future<Map<String, dynamic>> get(String path,
          {Map<String, dynamic>? query, bool auth = true}) =>
      _send('GET', path, query: query, auth: auth);

  Future<Map<String, dynamic>> post(String path,
          {Map<String, dynamic>? body, bool auth = true}) =>
      _send('POST', path, body: body, auth: auth);

  Future<Map<String, dynamic>> put(String path,
          {Map<String, dynamic>? body, bool auth = true}) =>
      _send('PUT', path, body: body, auth: auth);

  Future<Map<String, dynamic>> delete(String path,
          {Map<String, dynamic>? body, bool auth = true}) =>
      _send('DELETE', path, body: body, auth: auth);

  /// multipart 上传（发送图片/视频消息、上传头像等）。
  /// [files]: keyName -> 本地文件路径。
  /// [onSendProgress]: 上传进度回调（已发送字节, 总字节），按整数百分比节流（每 1% 至多一次）。
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    Map<String, String>? fields,
    Map<String, String>? files,
    bool auth = true,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final uri = Uri.parse('$colibriApiBase$path');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers(auth: auth));
    fields?.forEach((k, v) => request.fields[k] = v);
    if (files != null) {
      for (final entry in files.entries) {
        final f = await http.MultipartFile.fromPath(entry.key, entry.value);
        request.files.add(f);
      }
    }
    try {
      if (onSendProgress == null) {
        final streamed =
            await _client.send(request).timeout(const Duration(seconds: 300));
        return await _readMultipartResponse(streamed);
      }

      // 有进度回调：计数字节流 + 背压转发（StreamedRequest 透传 MultipartRequest 的字节）。
      // 背压链（关键，否则进度瞬间 100%）：socket 写满 → IOClient 的 stream.pipe(ioRequest)
      // 暂停 controller.stream 订阅 → StreamedRequest 的 controller paused →
      // sink.addStream 暂停源流（文件流）读取。计数因此 = 真实网络发送字节。
      // （若用 listen 直灌 sink：controller 是无界缓冲，文件按磁盘速度瞬间灌完，
      //  计数瞬间 100%，字节实际还在内存排队等网卡。）
      //
      // content-type 时序：MultipartRequest.finalize() 才会把 headers['content-type']
      // 设为 multipart/form-data; boundary=...（http 1.6.0 multipart_request.dart），
      // 因此先剔除 _headers() 预置的 application/json，finalize 后再拷贝 headers。
      // 另：ByteStream 是 StreamView<List<int>>，transform 泛型必须用 List<int>。
      request.headers.remove('Content-Type');
      request.headers.remove('content-type');

      final total = request.contentLength;
      var sent = 0;
      var lastPct = -1;
      onSendProgress(0, total);

      final byteStream =
          request.finalize(); // 此后 headers 含小写 content-type: multipart/...

      final countingStream = byteStream.transform<List<int>>(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (chunk, sink) {
            sent += chunk.length;
            final pct = total > 0 ? sent * 100 ~/ total : 100;
            if (pct != lastPct) {
              lastPct = pct;
              onSendProgress(sent, total);
            }
            sink.add(chunk);
          },
        ),
      );

      final streamRequest = http.StreamedRequest('POST', uri)
        ..headers.addAll(request.headers)
        ..contentLength = total;

      // addStream 尊重 controller 背压（区别于 listen）；完成/出错都要 close，
      // 否则 controller 不 done，下游 ioRequest.addStream 会一直等。
      streamRequest.sink
          .addStream(countingStream)
          .whenComplete(streamRequest.sink.close)
          .ignore();

      final streamed = await _client
          .send(streamRequest)
          .timeout(const Duration(seconds: 300));
      return await _readMultipartResponse(streamed);
    } on ColibriApiException {
      rethrow;
    } on Exception catch (e) {
      throw ColibriApiException('网络异常：$e');
    }
  }

  Future<Map<String, dynamic>> _readMultipartResponse(
      http.StreamedResponse streamed) async {
    final body = await streamed.stream.bytesToString();
    final decoded = _decodeBody(body);
    if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
      return decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};
    }
    String message = '请求失败（HTTP ${streamed.statusCode}）';
    if (decoded is Map<String, dynamic> && decoded['message'] != null) {
      message = decoded['message'].toString();
    }
    // 429：同上，透传服务端中文文案（含带秒数版本），仅无 message 时本地兜底
    if (streamed.statusCode == 429 &&
        !(decoded is Map<String, dynamic> && decoded['message'] != null)) {
      message = '操作过于频繁，请稍后再试';
    }

    // 封禁/维护响应头兜底（multipart 上传同理）
    final userStatus = streamed.headers['x-user-status'];
    if (userStatus == 'blocked' || userStatus == 'suspended') {
      String? reason;
      if (decoded is Map<String, dynamic>) {
        final d = decoded['data'];
        if (d is Map<String, dynamic>) reason = d['reason']?.toString();
      }
      onUserStatusBlocked?.call(userStatus!, reason);
    }
    if (streamed.headers['x-maintenance'] == '1') {
      String? m;
      String? until;
      if (decoded is Map<String, dynamic>) {
        m = decoded['message']?.toString();
        final d = decoded['data'];
        if (d is Map<String, dynamic>) until = d['until']?.toString();
      }
      onMaintenance?.call(m, until);
    }
    if (streamed.headers['x-require-update'] == '1') {
      final d = decoded is Map<String, dynamic> ? decoded['data'] : null;
      if (d is Map<String, dynamic>) onRequireUpdate?.call(d);
    }

    throw ColibriApiException(message, statusCode: streamed.statusCode);
  }

  // ===================== 认证 =====================

  /// 登录：POST /sanctum/token，返回 token 字符串（纯文本，非 JSON）。
  Future<String> login({
    required String email,
    required String password,
    String deviceName = 'app',
  }) async {
    final uri = Uri.parse('${colibriApiBase}sanctum/token');
    try {
      final response = await _client
          .post(
            uri,
            // 复用统一头部：必须带 X-App-Key（服务端 VerifyAppKey 白名单校验，
            // 缺失会被伪装成 404）+ X-Client-Id。
            // auth: false —— 此刻尚未取得 token，无需 Authorization。
            headers: _headers(auth: false),
            body: jsonEncode({
              'email': email,
              'password': password,
              'device_name': deviceName,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final token = response.body.trim();
        if (token.isEmpty) {
          throw ColibriApiException('登录失败：未返回 token');
        }
        return token;
      }

      String message = '登录失败（HTTP ${response.statusCode}）';
      final decoded = _decodeBody(response.body);
      if (decoded is Map<String, dynamic>) {
        if (decoded['message'] != null) message = decoded['message'].toString();

        // 封禁/停用账号登录：触发封禁页跳转（用户仍未登录，进入封禁提示页）
        if (response.statusCode == 403) {
          final d = decoded['data'];
          if (d is Map<String, dynamic>) {
            final st = d['user_status']?.toString();
            if (st == 'blocked' || st == 'suspended') {
              onUserStatusBlocked?.call(st!, d['reason']?.toString());
            }
          }
        }

        // 危险版本：426 登录即被强制更新
        if (response.headers['x-require-update'] == '1') {
          final d = decoded['data'];
          if (d is Map<String, dynamic>) onRequireUpdate?.call(d);
        }
      }
      throw ColibriApiException(message, statusCode: response.statusCode);
    } on ColibriApiException {
      rethrow;
    } on Exception catch (e) {
      throw ColibriApiException('网络异常：$e');
    }
  }

  /// 注册：POST /auth/register，返回 { token, user }。
  /// user 结构同 bootstrap 的 auth.user。
  ///
  /// 当后台开启注册邮箱验证时，必须先调用 [sendRegistrationCode]
  /// 并把 6 位验证码传入 [emailCode]，否则服务端返回 422。
  Future<({String token, Map<String, dynamic> user})> register({
    required String firstName,
    String? lastName,
    required String username,
    required String email,
    required String password,
    String? emailCode,
    String? language,
    String deviceName = 'app',
  }) async {
    final resp = await post('auth/register', auth: false, body: {
      'first_name': firstName,
      if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
      'username': username,
      'email': email,
      'password': password,
      if (emailCode != null && emailCode.isNotEmpty) 'email_code': emailCode,
      if (language != null && language.isNotEmpty) 'language': language,
      'device_name': deviceName,
    });
    final data = resp['data'];
    if (data is! Map<String, dynamic>) {
      throw ColibriApiException('注册失败：响应缺少 data');
    }
    final token = data['token']?.toString();
    final user = data['user'];
    if (token == null || token.isEmpty || user is! Map<String, dynamic>) {
      throw ColibriApiException('注册失败：响应缺少 token 或 user');
    }
    return (token: token, user: user);
  }

  /// 拉取注册功能开关：GET /auth/config（公共接口）。
  /// App 在注册前调用，决定是否展示邮箱验证码第二页。
  Future<ColibriAuthConfig> fetchAuthConfig() async {
    final resp = await get('auth/config', auth: false);
    final data = resp['data'];
    if (data is! Map<String, dynamic>) {
      throw ColibriApiException('获取注册配置失败：响应缺少 data');
    }
    return ColibriAuthConfig.fromJson(data);
  }

  /// 发送 / 重发注册邮箱验证码。
  /// POST /auth/email-code/send 或 /auth/email-code/resend。
  ///
  /// 成功返回验证码有效期与重发冷却秒数（用服务端值启动倒计时，避免本地时钟偏差）。
  /// 冷却中服务端返回 429，异常 data['time_left'] 带剩余秒数。
  Future<({int codeExpiresIn, int resendCooldown})> sendRegistrationCode({
    required String email,
    bool resend = false,
  }) async {
    final resp = await post(
      resend ? 'auth/email-code/resend' : 'auth/email-code/send',
      auth: false,
      body: {'email': email},
    );
    final data = resp['data'];
    if (data is! Map<String, dynamic>) {
      throw ColibriApiException('发送验证码失败：响应缺少 data');
    }
    return (
      codeExpiresIn: (data['code_expires_seconds'] as num?)?.toInt() ?? 600,
      resendCooldown: (data['resend_cooldown_seconds'] as num?)?.toInt() ?? 60,
    );
  }

  /// 拉取当前登录用户数据：GET /bootstrap/bootstrap。
  /// 返回 bootstrap.data.auth.user（未登录为 null）。
  Future<Map<String, dynamic>?> fetchBootstrapUser() async {
    final resp = await get('bootstrap/bootstrap');
    final data = resp['data'];
    if (data is! Map<String, dynamic>) return null;
    final auth = data['auth'];
    if (auth is! Map<String, dynamic>) return null;
    final user = auth['user'];
    return user is Map<String, dynamic> ? user : null;
  }

  /// 忘记密码：POST /auth/forgot-password，发送重置邮件。
  Future<void> forgotPassword({required String email}) async {
    await post('auth/forgot-password', auth: false, body: {'email': email});
  }

  /// 重置密码：POST /auth/reset-password。
  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
  }) async {
    await post('auth/reset-password', auth: false, body: {
      'token': token,
      'email': email,
      'password': password,
    });
  }

  /// 登出：POST /auth/logout，注销当前 token，并清本地会话。
  Future<void> logout() async {
    try {
      await post('auth/logout');
    } on ColibriApiException {
      // 即使服务端失败也继续清理本地
    } finally {
      SessionManager.shared.setToken('');
      SessionManager.shared.setLogin(false);
      SessionManager.shared.setColibriUser(null);
      if (Get.isRegistered<BookmarkStore>()) BookmarkStore.i.reset();
      if (Get.isRegistered<ChatUnreadStore>()) ChatUnreadStore.i.reset();
    }
  }

  /// 在线心跳：App 前后台切换上报（P0 在线用户数）。
  /// [background]=true 表示进入后台（即刻离席），false 表示回到前台（标记在线）。
  Future<void> heartbeat({bool background = false}) async {
    await post('presence/heartbeat', body: {'background': background});
  }
}

/// 后端注册功能开关（GET /auth/config）。
///
/// [emailVerificationEnabled] 为 true 时，App 必须在注册第二步
/// 输入邮箱验证码才能完成注册。
class ColibriAuthConfig {
  final bool registrationEnabled;
  final bool emailVerificationEnabled;
  final String verificationType;
  final int resendCooldownSeconds;
  final int codeExpiresSeconds;
  final int passwordMin;

  const ColibriAuthConfig({
    required this.registrationEnabled,
    required this.emailVerificationEnabled,
    required this.verificationType,
    required this.resendCooldownSeconds,
    required this.codeExpiresSeconds,
    required this.passwordMin,
  });

  /// 网络异常时的保守默认值：注册可用、不强制验证码（避免配置接口偶发失败卡死注册）。
  /// 真正的强制校验仍由服务端兜底。
  factory ColibriAuthConfig.fallback() => const ColibriAuthConfig(
        registrationEnabled: true,
        emailVerificationEnabled: false,
        verificationType: 'email',
        resendCooldownSeconds: 60,
        codeExpiresSeconds: 600,
        passwordMin: 8,
      );

  factory ColibriAuthConfig.fromJson(Map<String, dynamic> json) {
    return ColibriAuthConfig(
      registrationEnabled: json['registration_enabled'] == true,
      emailVerificationEnabled: json['email_verification_enabled'] == true,
      verificationType: json['verification_type']?.toString() ?? 'email',
      resendCooldownSeconds:
          (json['resend_cooldown_seconds'] as num?)?.toInt() ?? 60,
      codeExpiresSeconds:
          (json['code_expires_seconds'] as num?)?.toInt() ?? 600,
      passwordMin: (json['password_min'] as num?)?.toInt() ?? 8,
    );
  }
}

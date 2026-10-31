import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:untitled/common/managers/logger.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/utilities/const.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// 自建 WebSocket 实时通道管理（替代 Firestore snapshots 监听）。
///
/// - 登录后 connect()：订阅本人用户频道 user.{id}.{ws_key}
/// - 进入聊天页 subscribeConversation / 离开 unsubscribeConversation
/// - 收到 chat.notification 事件 → 弹系统状态栏通知
///   （flutter_local_notifications，不依赖 Google 服务，大陆可用）
/// - 断线自动重连（3s 起步指数退避，上限 30s），重连后自动恢复全部订阅
/// - 30s 心跳保活（nginx 反代 idle 超时 3600s，心跳足够）
///
/// 事件分发：
///   message.new          → 聊天页（监听器注册方处理）
///   conversation.updated → 会话列表刷新
///   chat.notification    → 本地通知
class WsManager with WidgetsBindingObserver {
  static final WsManager shared = WsManager._internal();

  WsManager._internal() {
    // 前台恢复时自检连接（后台期间 socket 可能已被系统杀掉而无回调）
    WidgetsBinding.instance.addObserver(this);
  }

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _heartbeat;
  Timer? _reconnectTimer;
  int _reconnectDelay = 3;
  bool _manuallyClosed = false;
  bool _connecting = false;

  /// 最近一次收到服务端数据的时间（pong 超时判定用）。
  DateTime? _lastReceived;

  /// 用户频道名（连接成功后自动订阅）。
  String? _userChannel;

  /// 当前订阅的会话频道（重连后自动恢复）。
  final Set<String> _conversationChannels = {};

  /// 事件监听器：事件名 -> 回调列表（'*' 监听全部）。
  final Map<String, List<void Function(Map<String, dynamic> data)>> _listeners =
      {};

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _notificationsInitialized = false;

  bool get isConnected => _channel != null;

  /// 登录成功 / App 启动（已登录）时调用。
  void connect() {
    var user = SessionManager.shared.getUser();
    var wsKey = user?.wsKey;
    if (user?.id == null || wsKey == null || wsKey.isEmpty) {
      Loggers.warning('WS skip connect: no user or ws_key');
      return;
    }
    _manuallyClosed = false;
    _userChannel = 'user.${user!.id}.$wsKey';
    if (_channel != null || _connecting) return;

    _connecting = true;
    _open();
  }

  void disconnect() {
    _manuallyClosed = true;
    _teardown();
    _conversationChannels.clear();
    _userChannel = null;
  }

  Future<void> _open() async {
    WebSocketChannel channel;
    try {
      channel = WebSocketChannel.connect(Uri.parse(wsURL));
    } catch (e) {
      _connecting = false;
      Loggers.warning('WS connect failed: $e');
      _scheduleReconnect();
      return;
    }

    try {
      await channel.ready.timeout(const Duration(seconds: 10));
    } catch (e) {
      _connecting = false;
      Loggers.warning('WS ready failed: $e');
      _scheduleReconnect();
      return;
    }

    _channel = channel;
    _connecting = false;
    _reconnectDelay = 3;
    Loggers.success('WS connected');

    // 恢复全部订阅
    final channels = <String>[
      if (_userChannel != null) _userChannel!,
      ..._conversationChannels,
    ];
    if (channels.isNotEmpty) {
      _send({'type': 'subscribe', 'channels': channels});
    }

    _startHeartbeat();

    _subscription = channel.stream.listen(
      (data) => _onData('$data'),
      onError: (e) {
        Loggers.warning('WS error: $e');
        _scheduleReconnect();
      },
      onDone: () {
        Loggers.warning('WS closed');
        _scheduleReconnect();
      },
    );
  }

  void _onData(String raw) {
    _lastReceived = DateTime.now();
    Map<String, dynamic>? payload;
    try {
      payload = jsonDecode(raw);
    } catch (_) {
      return;
    }
    if (payload == null) return;

    final type = payload['type'];

    if (type == 'pong') return;
    if (type == 'subscribed') {
      Loggers.info('WS subscribed: ${payload['channels']}');
      return;
    }

    if (type == 'event') {
      final event = '${payload['event']}';
      final data = payload['data'];
      final map =
          data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

      if (event == 'chat.notification') {
        _handleNotification(map);
      }

      _listeners[event]?.forEach((cb) => cb(map));
      _listeners['*']?.forEach((cb) => cb(map));
    }
  }

  /// 弹系统状态栏通知（正在聊天的会话不弹，由聊天页自己处理）。
  void _handleNotification(Map<String, dynamic> data) {
    final conversationId = '${data['conversationId'] ?? ''}';
    if (conversationId == SessionManager.shared.getStoredConversation()) {
      return; // 正在这个聊天里
    }

    var user = SessionManager.shared.getUser();
    if (user?.isPushNotifications != 1) {
      return; // 用户关闭了推送
    }

    _initNotifications();
    _notifications.show(
      conversationId.hashCode & 0x7fffffff,
      '${data['title'] ?? ''}',
      '${data['body'] ?? ''}',
      const NotificationDetails(
        android: AndroidNotificationDetails('chatter', 'Chatter Notification',
            playSound: true,
            importance: Importance.max,
            priority: Priority.high),
        iOS: DarwinNotificationDetails(
            presentSound: true, presentAlert: true, presentBadge: false),
      ),
    );
  }

  void _initNotifications() {
    if (_notificationsInitialized) return;
    _notificationsInitialized = true;
    _notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
            defaultPresentAlert: true,
            defaultPresentSound: true,
            defaultPresentBadge: false),
      ),
    );
    _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, sound: true);
  }

  /// 进入聊天页：订阅会话频道 conv.{conversationId}.{key}。
  void subscribeConversation(String conversationId, String conversationKey) {
    final channel = 'conv.$conversationId.$conversationKey';
    if (_conversationChannels.contains(channel)) return;
    _conversationChannels.add(channel);
    _send({
      'type': 'subscribe',
      'channels': [channel]
    });
  }

  /// 离开聊天页：取消订阅。
  void unsubscribeConversation(String conversationId, String conversationKey) {
    final channel = 'conv.$conversationId.$conversationKey';
    _conversationChannels.remove(channel);
    _send({
      'type': 'unsubscribe',
      'channels': [channel]
    });
  }

  /// 注册事件监听。event 传 '*' 监听全部事件。
  void addListener(
      String event, void Function(Map<String, dynamic> data) callback) {
    _listeners.putIfAbsent(event, () => []).add(callback);
  }

  void removeListener(
      String event, void Function(Map<String, dynamic> data) callback) {
    _listeners[event]?.remove(callback);
  }

  void _send(Map<String, dynamic> data) {
    try {
      _channel?.sink.add(jsonEncode(data));
    } catch (e) {
      Loggers.warning('WS send failed: $e');
    }
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _lastReceived = DateTime.now();
    _heartbeat = Timer.periodic(const Duration(seconds: 30), (_) {
      // pong 超时检测：超过 75 秒未收到任何服务端数据，判定为假连接
      // （Android 后台恢复后 socket 可能已死但无 onError/onDone 回调）
      final last = _lastReceived;
      if (last != null &&
          DateTime.now().difference(last) > const Duration(seconds: 75)) {
        Loggers.warning('WS pong timeout, force reconnect');
        _scheduleReconnect();
        return;
      }
      _send({'type': 'ping'});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (_manuallyClosed) return;
    if (_channel == null && !_connecting) {
      connect(); // 未连接（如后台期间重连 timer 被冻结丢失）→ 直接重连
    } else if (_channel != null) {
      // 已连接：立即探测一次，配合 pong 超时尽快发现死连接
      _send({'type': 'ping'});
      final last = _lastReceived;
      if (last != null &&
          DateTime.now().difference(last) > const Duration(seconds: 60)) {
        Loggers.warning('WS stale on resume, force reconnect');
        _scheduleReconnect();
      }
    }
  }

  void _scheduleReconnect() {
    if (_manuallyClosed) return;
    _teardown();

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: _reconnectDelay), () {
      _reconnectDelay = (_reconnectDelay * 2).clamp(3, 30);
      connect();
    });
  }

  void _teardown() {
    _heartbeat?.cancel();
    _heartbeat = null;
    _subscription?.cancel();
    _subscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _connecting = false;
  }
}

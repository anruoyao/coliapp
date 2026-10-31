import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:untitled/common/api_service/colibri_api.dart';
import 'package:untitled/common/managers/logger.dart';
import 'package:untitled/utilities/const.dart';

/// ColibriPlus 实时通道（Laravel Reverb / pusher 协议，手写轻量客户端）。
///
/// - 连接 `wss://mariawk.cn/app/{key}`（pusher 协议）
/// - 私有频道认证走 `/api/broadcasting/auth`（Sanctum Bearer token）
/// - 断线自动重连（指数退避），重连后重新订阅已订阅频道
class ReverbService {
  static final shared = ReverbService();

  // 业务事件名（与后端 broadcastAs 一致）
  static const String eventMessageReceived = 'chat.message.received';
  static const String eventMessageDeleted = 'chat.message.deleted';
  static const String eventMessageRead = 'chat.message.read';
  // 社交通知广播。Laravel 通知广播的事件名是 BroadcastNotificationCreated 的
  // FQCN（BaseNotification 只定义了 broadcastType()=main.notification，它是
  // payload 里的 type 字段而非事件名，勿混淆）。
  static const String eventNotification =
      r'Illuminate\Notifications\Events\BroadcastNotificationCreated';
  // 服务端指令事件（封禁/解封/维护模式开关）。见后端 Events/.../*ChangedEvent。
  static const String eventCommand = 'main.command';
  // 公共命令频道：维护模式等全局指令广播到这里（无需鉴权，任何人可订阅）。
  static const String publicCommandChannel = 'App.Commands';

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  String _socketId = '';
  bool _connecting = false;
  int _reconnectAttempt = 0;

  final Set<String> _subscribedChannels = {};
  final Map<String, List<void Function(dynamic payload)>> _handlers = {};

  bool _connected = false;
  bool get isConnected => _connected;

  Timer? _pingTimer;
  Timer? _reconnectTimer;

  /// 最近一次收到 pong（或连接建立）的时间，用于死链检测。
  DateTime _lastPongAt = DateTime.now();

  /// 连接 Reverb。
  Future<void> connect() async {
    if (_connecting || _connected) return;
    _connecting = true;

    try {
      Loggers.info('Reverb: connecting...');
      final uri = Uri.parse(colibriWsUrl);
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      _sub = channel.stream.listen(
        _onMessage,
        onError: (e) {
          Loggers.error('Reverb onError: $e');
          _handleDisconnect();
        },
        onDone: _handleDisconnect,
        cancelOnError: true,
      );
    } on Exception catch (e) {
      Loggers.error('Reverb connect exception: $e');
      _connecting = false;
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    if (raw is! String) return;
    Map<String, dynamic> frame;
    try {
      frame = jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException {
      return;
    }
    final event = frame['event']?.toString();
    if (event == null) return;

    switch (event) {
      case 'pusher:connection_established':
        final data = frame['data'];
        if (data is String) {
          try {
            final d = jsonDecode(data) as Map<String, dynamic>;
            _socketId = d['socket_id']?.toString() ?? '';
          } catch (_) {}
        } else if (data is Map) {
          _socketId = data['socket_id']?.toString() ?? '';
        }
        Loggers.info('Reverb connected, socket_id=$_socketId');
        _connected = true;
        _connecting = false;
        _reconnectAttempt = 0;
        _lastPongAt = DateTime.now();
        _startPing();
        _resubscribeAll();
        break;
      case 'pusher:ping':
        _sendRaw('{"event":"pusher:pong","data":{}}');
        break;
      case 'pusher:pong':
        _lastPongAt = DateTime.now();
        break;
      case 'pusher:subscription_succeeded':
      case 'pusher:subscription_error':
        break;
      default:
        dynamic payload = frame['data'];
        if (payload is String) {
          try {
            payload = jsonDecode(payload);
          } catch (_) {}
        }
        _dispatch(event, payload);
    }
  }

  void _dispatch(String event, dynamic payload) {
    final handlers = _handlers[event];
    if (handlers == null) return;
    for (final h in List.of(handlers)) {
      try {
        h(payload);
      } catch (e) {
        Loggers.error('Reverb handler error: $e');
      }
    }
  }

  /// 注册事件监听，返回取消函数。
  void on(String event, void Function(dynamic payload) handler) {
    _handlers.putIfAbsent(event, () => []).add(handler);
  }

  void off(String event, void Function(dynamic payload) handler) {
    final list = _handlers[event];
    if (list != null) list.remove(handler);
  }

  // ===================== 频道订阅 =====================

  /// 订阅单聊/群聊私有频道。
  /// Laravel PrivateChannel 广播到 `private-App.Models.Chat.{chatId}`，必须带 private- 前缀。
  void subscribeChat(String chatId) {
    subscribeChannel('private-App.Models.Chat.$chatId');
  }

  /// 订阅当前用户的私有通知频道（社交通知实时推送）。
  /// 后端通知广播到 `private-App.Models.User.{userId}`，必须带 private- 前缀。
  void subscribeUser(String userId) {
    subscribeChannel('private-App.Models.User.$userId');
  }

  /// 订阅公共命令频道（无需鉴权，直接 subscribe）。
  /// 用于维护模式等全局指令；后端广播到 `App.Commands`。
  void subscribePublicCommands() {
    subscribePublicChannel(publicCommandChannel);
  }

  /// 订阅公共频道：不做 Reverb auth，直接下发 pusher:subscribe。
  void subscribePublicChannel(String channel) {
    if (_subscribedChannels.contains(channel)) return;
    _subscribedChannels.add(channel);
    if (_connected && _socketId.isNotEmpty) {
      _sendRaw(
        jsonEncode({
          'event': 'pusher:subscribe',
          'data': {'channel': channel},
        }),
      );
    }
  }

  void subscribeChannel(String channel) {
    if (_subscribedChannels.contains(channel)) return;
    _subscribedChannels.add(channel);
    if (_connected && _socketId.isNotEmpty) {
      _doSubscribe(channel);
    }
  }

  Future<void> _doSubscribe(String channel) async {
    try {
      final resp = await ColibriApi.shared.post(
        'broadcasting/auth',
        body: {'socket_id': _socketId, 'channel_name': channel},
      );
      final authStr = resp['auth']?.toString();
      if (authStr == null || authStr.isEmpty) {
        Loggers.error('Reverb auth failed for $channel');
        return;
      }
      _sendRaw(
        jsonEncode({
          'event': 'pusher:subscribe',
          'data': {'channel': channel, 'auth': authStr},
        }),
      );
    } on ColibriApiException catch (e) {
      Loggers.error('Reverb auth exception for $channel: ${e.message}');
    }
  }

  void _resubscribeAll() {
    if (_socketId.isEmpty) return;
    for (final channel in List.of(_subscribedChannels)) {
      if (_isGuardedChannel(channel)) {
        _doSubscribe(channel);
      } else {
        // 公共频道无需鉴权，直接下发订阅帧。
        // 走 broadcasting/auth 会被服务端拒绝，导致公共命令频道
        // （App.Commands）在首次连接与重连后都订阅失败，收不到维护指令。
        _sendRaw(
          jsonEncode({
            'event': 'pusher:subscribe',
            'data': {'channel': channel},
          }),
        );
      }
    }
  }

  /// 私有/Presence 频道需要走 broadcasting/auth 鉴权，公共频道直接订阅。
  static bool _isGuardedChannel(String channel) =>
      channel.startsWith('private-') || channel.startsWith('presence-');

  // ===================== 收发 =====================

  void _sendRaw(String text) {
    try {
      _channel?.sink.add(text);
    } catch (e) {
      Loggers.error('Reverb send error: $e');
    }
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_connected) return;
      // 死链检测：超过 70s（约两个 ping 周期）未收到任何 pong，
      // 视为连接已失效（弱网/半开连接），强制断开走重连流程。
      if (DateTime.now().difference(_lastPongAt).inSeconds > 70) {
        Loggers.warning(
            'Reverb ping timeout (>70s no pong), forcing reconnect');
        _handleDisconnect();
        return;
      }
      _sendRaw('{"event":"pusher:ping","data":{}}');
    });
  }

  void _handleDisconnect() {
    final wasConnected = _connected;
    _connected = false;
    _connecting = false;
    _socketId = '';
    _pingTimer?.cancel();
    _pingTimer = null;
    try {
      _sub?.cancel();
      _sub = null;
      _channel?.sink.close();
    } catch (_) {}
    if (wasConnected || _reconnectAttempt == 0) {
      Loggers.warning('Reverb disconnected, reconnecting...');
    }
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    final delay = const [2, 4, 8, 16, 30][_reconnectAttempt.clamp(0, 4)];
    _reconnectAttempt++;
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      if (!_connected) connect();
    });
  }

  /// 主动断开（登出时调用），清空订阅与监听。
  void disconnect() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _connected = false;
    _connecting = false;
    _subscribedChannels.clear();
    _handlers.clear();
    try {
      _sub?.cancel();
      _channel?.sink.close();
    } catch (_) {}
    _sub = null;
    _channel = null;
  }
}

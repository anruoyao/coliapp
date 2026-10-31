import 'package:untitled/common/api_service/api_service.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/models/chat.dart';
import 'package:untitled/utilities/params.dart';
import 'package:untitled/utilities/web_service.dart';

/// 本地化聊天 API（替代 Firestore chats/users 集合读写）。
///
/// 所有方法失败时走 _callChatApi 的 try-catch 兜底，
/// completion 不会被调用（与项目其他 Service 行为一致）。
class ChatService {
  static var shared = ChatService();

  /// 解析/懒创建会话（打开聊天页时调用）。
  /// peerId 单聊 / roomId 房间群聊 / conversationId 已有会话。
  void getOrCreateConversation({
    num? peerId,
    num? roomId,
    String? conversationId,
    required Function(ChatUserRoom conversation) completion,
    Function(String error)? onError,
  }) {
    _callChatApi(
      url: WebService.chatGetOrCreateConversation,
      param: {
        Param.userId: SessionManager.shared.getUserID(),
        Param.peerId: peerId,
        Param.roomId: roomId,
        Param.conversationId: conversationId,
      },
      completion: (response) {
        var data = response['data'];
        if (data is Map<String, dynamic>) {
          completion(ChatUserRoom.fromJson(data));
        }
      },
      onError: onError,
    );
  }

  /// 发送消息。返回完整消息对象（含服务端生成的 id）。
  void sendMessage({
    String? conversationId,
    num? toUserId,
    num? roomId,
    required String msgType,
    String? msg,
    String? content,
    String? thumbnail,
    num? storyId,
    required Function(ChatMessage message) completion,
    Function(String error)? onError,
  }) {
    _callChatApi(
      url: WebService.chatSendMessage,
      param: {
        Param.userId: SessionManager.shared.getUserID(),
        Param.conversationId: conversationId,
        Param.toUserId: toUserId,
        Param.roomId: roomId,
        Param.msgType: msgType,
        Param.msg: msg ?? '',
        Param.content: content,
        Param.thumbnail: thumbnail,
        Param.storyId: storyId,
      },
      completion: (response) {
        var data = response['data'];
        if (data is Map<String, dynamic>) {
          completion(ChatMessage.fromJson(data));
        }
      },
      onError: onError,
    );
  }

  /// 分页拉取消息（服务端按 id 倒序返回最新 20 条）。
  void fetchMessages({
    required String conversationId,
    num? beforeId,
    required Function(List<ChatMessage> messages, bool hasMore) completion,
    Function(String error)? onError,
  }) {
    _callChatApi(
      url: WebService.chatFetchMessages,
      param: {
        Param.userId: SessionManager.shared.getUserID(),
        Param.conversationId: conversationId,
        Param.beforeId: beforeId,
      },
      completion: (response) {
        var data = response['data'];
        var list = <ChatMessage>[];
        if (data is Map<String, dynamic> && data['messages'] is List) {
          for (var item in data['messages']) {
            list.add(ChatMessage.fromJson(item));
          }
        }
        completion(
            list, data is Map<String, dynamic> && data['hasMore'] == true);
      },
      onError: onError,
    );
  }

  /// 会话列表（单聊 + 房间群聊，按最近活跃排序）。
  void fetchConversations({
    required Function(List<ChatUserRoom> conversations) completion,
    Function(String error)? onError,
  }) {
    _callChatApi(
      url: WebService.chatFetchConversations,
      param: {Param.userId: SessionManager.shared.getUserID()},
      completion: (response) {
        var list = <ChatUserRoom>[];
        if (response['data'] is List) {
          for (var item in response['data']) {
            list.add(ChatUserRoom.fromJson(item));
          }
        }
        completion(list);
      },
      onError: onError,
    );
  }

  void markAsRead({required String conversationId}) {
    _callChatApi(
      url: WebService.chatMarkAsRead,
      param: {
        Param.userId: SessionManager.shared.getUserID(),
        Param.conversationId: conversationId
      },
      completion: (_) {},
    );
  }

  /// 标记未读红点（value: -1）/ 取消（value: 0），对齐原 Firestore 行为。
  void setUnread({required String conversationId, required int value}) {
    _callChatApi(
      url: WebService.chatSetUnread,
      param: {
        Param.userId: SessionManager.shared.getUserID(),
        Param.conversationId: conversationId,
        'value': value
      },
      completion: (_) {},
    );
  }

  void clearChat(
      {required String conversationId, required Function() completion}) {
    _callChatApi(
      url: WebService.chatClearChat,
      param: {
        Param.userId: SessionManager.shared.getUserID(),
        Param.conversationId: conversationId
      },
      completion: (_) => completion(),
    );
  }

  void deleteChat(
      {required String conversationId, required Function() completion}) {
    _callChatApi(
      url: WebService.chatDeleteChat,
      param: {
        Param.userId: SessionManager.shared.getUserID(),
        Param.conversationId: conversationId
      },
      completion: (_) => completion(),
    );
  }

  void acceptRequest(
      {required String conversationId, required Function() completion}) {
    _callChatApi(
      url: WebService.chatAcceptRequest,
      param: {
        Param.userId: SessionManager.shared.getUserID(),
        Param.conversationId: conversationId
      },
      completion: (_) => completion(),
    );
  }

  void rejectRequest(
      {required String conversationId, required Function() completion}) {
    _callChatApi(
      url: WebService.chatRejectRequest,
      param: {
        Param.userId: SessionManager.shared.getUserID(),
        Param.conversationId: conversationId
      },
      completion: (_) => completion(),
    );
  }

  /// 统一请求入口：失败（status=false 或网络异常）时不调用 completion。
  void _callChatApi({
    required String url,
    Map<String, dynamic>? param,
    required Function(Map<String, dynamic> response) completion,
    Function(String error)? onError,
  }) {
    ApiService.shared
        .call(
      url: url,
      param: param,
      completion: (response) {
        if (response['status'] == true) {
          completion(response);
        } else {
          final msg = response['message'];
          if (onError != null) {
            onError('$msg');
          }
        }
      },
    )
        .catchError((e) {
      if (onError != null) onError('$e');
    });
  }
}

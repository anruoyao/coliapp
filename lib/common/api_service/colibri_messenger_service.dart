import 'package:untitled/common/api_service/colibri_api.dart';
import 'package:untitled/models/colibri_chat_models.dart';

/// ColibriPlus Messenger API（/messenger/*）。
class ColibriMessengerService {
  static final shared = ColibriMessengerService();

  ColibriApi get _api => ColibriApi.shared;

  // ===================== 会话列表 =====================

  /// 会话列表（按最后活跃倒序）。
  Future<List<ColibriChatSummary>> fetchChats() async {
    final resp = await _api.get('messenger/chats');
    final data = resp['data'];
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => ColibriChatSummary.fromJson(e))
        .toList();
  }

  /// 总未读数。
  Future<int> fetchUnreadCount() async {
    final resp = await _api.get('messenger/unread/count');
    final data = resp['data'];
    if (data is Map<String, dynamic>) {
      return data['raw'] is int
          ? data['raw'] as int
          : int.tryParse('${data['raw']}') ?? 0;
    }
    return 0;
  }

  /// 会话详情（聊天页头部信息）。
  Future<Map<String, dynamic>> fetchChatData(String chatId) async {
    final resp = await _api.get('messenger/chat/$chatId');
    final data = resp['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  /// 最近消息列表（后端固定返回最近 30 条，按时间正序返回）。
  Future<List<ColibriMessage>> fetchMessages(String chatId) async {
    final resp = await _api.get('messenger/chat/$chatId/messages');
    final data = resp['data'];
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => ColibriMessage.fromJson(e))
        .toList();
  }

  /// 发起单聊（已存在则复用）。
  Future<String> createChat(int userId) async {
    final resp =
        await _api.post('messenger/chats/create', body: {'user_id': userId});
    final data = resp['data'];
    if (data is Map<String, dynamic>) return data['chat_id']?.toString() ?? '';
    return '';
  }

  // ===================== 消息 =====================

  /// 发送文本消息。
  Future<void> sendText(
      {required String chatId, required String content, int? parentId}) async {
    await _api.post('messenger/send', body: {
      'chat_id': chatId,
      'content': content,
      if (parentId != null) 'parent_id': parentId,
    });
  }

  /// 发送图片消息，[mediaType] 固定为 image（录音/录像已下线，仅保留图片媒体）。
  Future<void> sendMedia({
    required String chatId,
    required String filePath,
    required String mediaType,
    String? content,
    int? duration,
  }) async {
    await _api.postMultipart(
      'messenger/send',
      fields: {
        'chat_id': chatId,
        'media_type': mediaType,
        if (content != null && content.isNotEmpty) 'content': content,
        if (duration != null) 'media_duration': '$duration',
      },
      files: {'media': filePath},
    );
  }

  /// 标记已读。
  Future<void> markAsRead(String chatId) async {
    await _api.get('messenger/chat/$chatId/read');
  }

  // ===================== 会话操作 =====================

  /// 删除会话（列表隐藏，新消息自动恢复）。
  Future<void> deleteChat(String chatId) async {
    await _api.delete('messenger/chat/$chatId/delete');
  }

  Future<void> archiveChat(String chatId) async {
    await _api.delete('messenger/chat/$chatId/archive');
  }

  Future<void> unarchiveChat(String chatId) async {
    await _api.delete('messenger/chat/$chatId/unarchive');
  }

  Future<void> clearConversation(String chatId) async {
    await _api.delete('messenger/chat/$chatId/clear');
  }

  /// 删除消息（自己发的可全局删除；他人消息仅本地隐藏）。
  Future<void> deleteMessage(int messageId, {bool deleteForAll = true}) async {
    await _api.delete('messenger/chat/message/delete', body: {
      'message_id': messageId,
      'payload': {'delete_for_all': deleteForAll},
    });
  }

  // ===================== 陌生人请求 / 群邀请 =====================

  /// 我收到的待处理请求（群邀请）。
  Future<List<ColibriChatRequest>> fetchChatRequests() async {
    final resp = await _api.get('messenger/chats/requests');
    final data = resp['data'];
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => ColibriChatRequest.fromJson(e))
        .toList();
  }

  Future<int> fetchChatRequestsCount() async {
    final resp = await _api.get('messenger/chats/requests/count');
    final data = resp['data'];
    if (data is Map<String, dynamic>) {
      return data['count'] is int
          ? data['count'] as int
          : int.tryParse('${data['count']}') ?? 0;
    }
    return 0;
  }

  /// 接受邀请 / 请求。
  Future<void> acceptInvite(String chatId) async {
    await _api
        .post('messenger/groups/invite/accept', body: {'chat_id': chatId});
  }

  /// 拒绝邀请 / 请求。
  Future<void> declineInvite(String chatId) async {
    await _api
        .post('messenger/groups/invite/decline', body: {'chat_id': chatId});
  }

  // ===================== 群聊 =====================

  /// 创建群聊草稿，返回 chat_id。
  Future<String> createGroupDraft() async {
    final resp = await _api.get('messenger/groups/create');
    final data = resp['data'];
    if (data is Map<String, dynamic>) {
      final relations = data['relations'];
      if (relations is Map<String, dynamic>) {
        final chat = relations['chat'];
        if (chat is Map<String, dynamic>)
          return chat['chat_id']?.toString() ?? '';
      }
    }
    return '';
  }

  /// 更新群聊信息（名称/描述/可见性）。
  Future<void> updateGroup({
    required String chatId,
    required String name,
    String? description,
    bool visibility = false,
  }) async {
    await _api.post('messenger/groups/update', body: {
      'chat_id': chatId,
      'name': name,
      'description': description ?? '',
      'visibility': visibility,
    });
  }

  /// 群成员列表。
  Future<List<ColibriGroupParticipant>> fetchGroupParticipants(
      String chatId) async {
    final resp = await _api.get('messenger/groups/$chatId/participants');
    final data = resp['data'];
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => ColibriGroupParticipant.fromJson(e))
        .toList();
  }

  /// 搜索可邀请用户。
  Future<List<ColibriInviteCandidate>> searchInvitees(
      {required String chatId, String query = ''}) async {
    final resp = await _api.post('messenger/groups/invite/search', body: {
      'chat_id': chatId,
      'query': query,
    });
    final data = resp['data'];
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => ColibriInviteCandidate.fromJson(e))
        .toList();
  }

  /// 邀请成员（user_ids 为用户 id 列表）。
  Future<void> inviteParticipants(
      {required String chatId, required List<int> userIds}) async {
    await _api.post('messenger/groups/invite/send', body: {
      'chat_id': chatId,
      'ids': userIds,
    });
  }

  /// 移除成员（ids 为参与者 participant_id 列表）。
  Future<void> deleteGroupParticipants(
      {required String chatId, required List<int> ids}) async {
    await _api.delete('messenger/groups/participant/delete', body: {
      'chat_id': chatId,
      'ids': ids,
    });
  }

  /// 删除群聊（仅群主）。
  Future<void> deleteGroup(String chatId) async {
    await _api.delete('messenger/groups/delete', body: {'chat_id': chatId});
  }

  /// 退出群聊。
  Future<void> leaveGroup(String chatId) async {
    await _api.post('messenger/groups/leave', body: {'chat_id': chatId});
  }
}

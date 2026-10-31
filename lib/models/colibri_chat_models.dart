import 'package:untitled/common/managers/session_manager.dart';

/// ColibriPlus 聊天数据模型（对齐后端 Chat/Message Resource 结构）。

/// 会话摘要（/messenger/chats 返回项）。
class ColibriChatSummary {
  final String chatId;
  final bool isGroup;
  final String type; // direct / group

  /// 可空更新（进入聊天本地即时清零红点，不等列表重拉）。
  int unreadCount;
  final String unreadCountFormatted;
  final String lastActivityTimeAgo;
  final int lastActivityRaw;
  final String? lastMessage;
  final bool isDeleted;

  final int chatInfoId;
  final String chatInfoName;
  final String? chatInfoAvatarUrl;
  final bool chatInfoVerified;

  /// 对方用户名（单聊，用于跳转个人主页；群聊为空）。
  final String chatInfoUsername;

  ColibriChatSummary({
    required this.chatId,
    required this.isGroup,
    required this.type,
    required this.unreadCount,
    required this.unreadCountFormatted,
    required this.lastActivityTimeAgo,
    required this.lastActivityRaw,
    this.lastMessage,
    required this.isDeleted,
    required this.chatInfoId,
    required this.chatInfoName,
    this.chatInfoAvatarUrl,
    required this.chatInfoVerified,
    this.chatInfoUsername = '',
  });

  factory ColibriChatSummary.fromJson(Map<String, dynamic> json) {
    final unread = json['unread_messages_count'] is Map<String, dynamic>
        ? json['unread_messages_count'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final activity = json['last_activity'] is Map<String, dynamic>
        ? json['last_activity'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final info = json['chat_info'] is Map<String, dynamic>
        ? json['chat_info'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return ColibriChatSummary(
      chatId: json['chat_id']?.toString() ?? '',
      isGroup: json['is_group'] == true,
      type: json['type']?.toString() ?? 'direct',
      unreadCount: _toInt(unread['raw']),
      unreadCountFormatted: unread['formatted']?.toString() ?? '0',
      lastActivityTimeAgo: activity['time_ago']?.toString() ?? '',
      lastActivityRaw: _toInt(activity['raw']),
      lastMessage: json['last_message']?.toString(),
      isDeleted: json['is_deleted'] == true,
      chatInfoId: _toInt(info['id']),
      chatInfoName: info['name']?.toString() ?? '',
      chatInfoAvatarUrl: info['avatar_url']?.toString(),
      chatInfoVerified: info['verified'] == true,
      chatInfoUsername: info['username']?.toString() ?? '',
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse('$v') ?? 0;
  }
}

/// 消息中的媒体（/messenger/chat/{id}/messages 的 relations.media）。
class ColibriMessageMedia {
  final int id;
  final String sourceUrl;
  final String? thumbnailUrl;
  final String type; // image / video / audio / file
  final String extension;
  final Map<String, dynamic> metadata;

  ColibriMessageMedia({
    required this.id,
    required this.sourceUrl,
    this.thumbnailUrl,
    required this.type,
    this.extension = '',
    this.metadata = const {},
  });

  factory ColibriMessageMedia.fromJson(Map<String, dynamic> json) {
    return ColibriMessageMedia(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      sourceUrl: json['source_url']?.toString() ?? '',
      thumbnailUrl: json['thumbnail_url']?.toString(),
      type: json['type']?.toString() ?? 'file',
      extension: json['extension']?.toString() ?? '',
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : const <String, dynamic>{},
    );
  }
}

/// 陌生人请求 / 群邀请（/messenger/chats/requests 返回项）。
class ColibriChatRequest {
  final int id;
  final String status; // pending / accepted / declined
  final String chatType;
  final int senderId;
  final String senderName;
  final String senderUsername;
  final String? senderAvatarUrl;
  final String chatId;
  final String groupName;
  final String timeAgo;

  ColibriChatRequest({
    required this.id,
    required this.status,
    required this.chatType,
    required this.senderId,
    required this.senderName,
    required this.senderUsername,
    this.senderAvatarUrl,
    required this.chatId,
    required this.groupName,
    required this.timeAgo,
  });

  factory ColibriChatRequest.fromJson(Map<String, dynamic> json) {
    final relations = json['relations'] is Map<String, dynamic>
        ? json['relations'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final sender = relations['sender'] is Map<String, dynamic>
        ? relations['sender'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final chat = relations['chat'] is Map<String, dynamic>
        ? relations['chat'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final group = relations['group'] is Map<String, dynamic>
        ? relations['group'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final date = json['date'] is Map<String, dynamic>
        ? json['date'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return ColibriChatRequest(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      status: json['status']?.toString() ?? 'pending',
      chatType: json['chat_type']?.toString() ?? 'group',
      senderId: sender['id'] is int
          ? sender['id']
          : int.tryParse('${sender['id']}') ?? 0,
      senderName: sender['name']?.toString() ?? '',
      senderUsername: sender['username']?.toString() ?? '',
      senderAvatarUrl: sender['avatar_url']?.toString(),
      chatId: chat['chat_id']?.toString() ?? '',
      groupName: group['name']?.toString() ?? '',
      timeAgo: date['time_ago']?.toString() ?? '',
    );
  }
}

/// 群聊成员（/messenger/groups/{id}/participants 返回项）。
class ColibriGroupParticipant {
  final int participantId;
  final bool isAdmin;
  final String color;
  final int userId;
  final String name;
  final String username;
  final String? avatarUrl;
  final bool online;

  ColibriGroupParticipant({
    required this.participantId,
    required this.isAdmin,
    required this.color,
    required this.userId,
    required this.name,
    required this.username,
    this.avatarUrl,
    required this.online,
  });

  factory ColibriGroupParticipant.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final relations = json['relations'] is Map<String, dynamic>
        ? json['relations'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final user = relations['user'] is Map<String, dynamic>
        ? relations['user'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final lastActive = user['last_active'] is Map<String, dynamic>
        ? user['last_active'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return ColibriGroupParticipant(
      participantId: json['participant_id'] is int
          ? json['participant_id']
          : int.tryParse('${json['participant_id']}') ?? 0,
      isAdmin: meta['is_admin'] == true,
      color: meta['color']?.toString() ?? '',
      userId:
          user['id'] is int ? user['id'] : int.tryParse('${user['id']}') ?? 0,
      name: user['name']?.toString() ?? '',
      username: user['username']?.toString() ?? '',
      avatarUrl: user['avatar_url']?.toString(),
      online: lastActive['online'] == true,
    );
  }
}

/// 可邀请用户搜索结果（/messenger/groups/invite/search 返回项）。
class ColibriInviteCandidate {
  final int id;
  final bool canInvite;
  final String name;
  final String username;
  final String? avatarUrl;
  final bool online;

  ColibriInviteCandidate({
    required this.id,
    required this.canInvite,
    required this.name,
    required this.username,
    this.avatarUrl,
    required this.online,
  });

  factory ColibriInviteCandidate.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final relations = json['relations'] is Map<String, dynamic>
        ? json['relations'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final user = relations['user'] is Map<String, dynamic>
        ? relations['user'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final lastActive = user['last_active'] is Map<String, dynamic>
        ? user['last_active'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return ColibriInviteCandidate(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      canInvite: meta['can_invite'] == true,
      name: user['name']?.toString() ?? '',
      username: user['username']?.toString() ?? '',
      avatarUrl: user['avatar_url']?.toString(),
      online: lastActive['online'] == true,
    );
  }
}

/// 聊天消息（MessageResource）。
class ColibriMessage {
  final int id;
  final int userId;
  final String chatUuid;
  final String content;
  final String type; // text / image / video / ...
  final bool hasParent;

  final int senderId;
  final String senderName;
  final String senderUsername;
  final String? senderAvatarUrl;
  final bool isAuthUser;
  final String? parentContent;

  final ColibriMessageMedia? media;
  final String participantColor;

  final String dateIso;
  final String timeAgo;
  final bool isDeleted;

  ColibriMessage({
    required this.id,
    required this.userId,
    required this.chatUuid,
    required this.content,
    required this.type,
    required this.hasParent,
    required this.senderId,
    required this.senderName,
    required this.senderUsername,
    this.senderAvatarUrl,
    required this.isAuthUser,
    this.parentContent,
    this.media,
    required this.participantColor,
    required this.dateIso,
    required this.timeAgo,
    required this.isDeleted,
  });

  bool get isMine => isAuthUser;

  /// 是否携带可展示的媒体。
  bool get hasUsableMedia => media != null && media!.sourceUrl.isNotEmpty;

  /// 媒体类型消息但缺媒体数据（上传失败残留/竞态）：UI 不应渲染空泡，
  /// 控制器会触发补拉。
  bool get isMediaWithoutData => type != 'text' && !hasUsableMedia;

  /// 空消息（无文本且无可展示媒体）：不渲染气泡。
  bool get isEmptyBubble => content.trim().isEmpty && !hasUsableMedia;

  factory ColibriMessage.fromJson(Map<String, dynamic> json) {
    final relations = json['relations'] is Map<String, dynamic>
        ? json['relations'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final user = relations['user'] is Map<String, dynamic>
        ? relations['user'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final parent = relations['parent'] is Map<String, dynamic>
        ? relations['parent'] as Map<String, dynamic>
        : null;
    final participant = relations['participant'] is Map<String, dynamic>
        ? relations['participant'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final mediaJson = relations['media'];
    final date = json['date'] is Map<String, dynamic>
        ? json['date'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final meta = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : const <String, dynamic>{};

    ColibriMessageMedia? media;
    if (mediaJson is Map<String, dynamic> && mediaJson.isNotEmpty) {
      media = ColibriMessageMedia.fromJson(mediaJson);
    }

    final userId = json['user_id'] is int
        ? json['user_id']
        : int.tryParse('${json['user_id']}') ?? 0;
    // 消息方向：不能依赖后端 is_auth_user（实时广播时按发送者计算，所有接收端一致），
    // 必须用「当前登录用户 id == 消息发送者 id」判断。
    final currentId = SessionManager.shared.getColibriUser()?['id'];
    final currentUserId =
        currentId is int ? currentId : int.tryParse('$currentId') ?? -1;

    return ColibriMessage(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      userId: userId,
      chatUuid: json['chat_uuid']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      hasParent: json['has_parent'] == true,
      senderId:
          user['id'] is int ? user['id'] : int.tryParse('${user['id']}') ?? 0,
      senderName: user['name']?.toString() ?? '',
      senderUsername: user['username']?.toString() ?? '',
      senderAvatarUrl: user['avatar_url']?.toString(),
      isAuthUser: userId == currentUserId,
      parentContent: parent?['content']?.toString(),
      media: media,
      participantColor: participant['color']?.toString() ?? '',
      dateIso: date['iso']?.toString() ?? '',
      timeAgo: date['time_ago']?.toString() ?? '',
      isDeleted: meta['is_deleted'] == true,
    );
  }
}

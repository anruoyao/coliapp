const String colibriLikeUnifiedId = '2764-fe0f';

/// ColibriPlus 时间线（Feed / 帖子 / 评论）数据模型。

/// 帖子媒体（TimelineResource.relations.media[]）。
class ColibriPostMedia {
  final int id;
  final String sourceUrl;
  final String? thumbnailUrl;
  final String type; // image / video / audio / gif / document
  final String? extension;
  final int size; // 字节
  final String? status; // processing / processed / ...
  final Map<String, dynamic> metadata;

  /// metadata 常用快捷读取（视频/音频时长、文档文件名、下载次数）。
  String get fileName => metadata['file_name']?.toString() ?? '';
  Map<String, dynamic>? get durationMap => metadata['duration'] is Map
      ? metadata['duration'] as Map<String, dynamic>
      : null;
  bool get isPortrait => metadata['is_portrait'] == true;
  int get downloads => metadata['downloads'] is int
      ? metadata['downloads'] as int
      : int.tryParse('${metadata['downloads']}') ?? 0;

  /// 视频/音频是否仍在服务端处理后端处理中（处理完成前不可播放）。
  bool get isProcessing => status == 'processing';

  bool get isImage => type == 'image';
  bool get isGif => type == 'gif';
  bool get isVideo => type == 'video';
  bool get isAudio => type == 'audio';
  bool get isDocument => type == 'document';

  ColibriPostMedia({
    required this.id,
    required this.sourceUrl,
    this.thumbnailUrl,
    required this.type,
    this.extension,
    this.size = 0,
    this.status,
    this.metadata = const {},
  });

  /// 视频/音频时长 → mm:ss（兼容后端 {hours,minutes,seconds} 映射或秒数）。
  String get durationText {
    if (durationMap != null) {
      final d = durationMap!;
      final m = int.tryParse('${d['minutes'] ?? 0}') ?? 0;
      final s = int.tryParse('${d['seconds'] ?? 0}') ?? 0;
      final h = int.tryParse('${d['hours'] ?? 0}') ?? 0;
      final str =
          '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      return h > 0 ? '$h:$str' : str;
    }
    final secs = int.tryParse('${metadata['duration']}') ?? 0;
    if (secs <= 0) return '';
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// 文件大小格式化（B/KB/MB/GB）。
  String get sizeText {
    if (size <= 0) return '';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  factory ColibriPostMedia.fromJson(Map<String, dynamic> json) {
    return ColibriPostMedia(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      sourceUrl: json['source_url']?.toString() ?? '',
      thumbnailUrl: json['thumbnail_url']?.toString(),
      type: json['type']?.toString() ?? 'document',
      extension: json['extension']?.toString(),
      size: json['size'] is int
          ? json['size']
          : int.tryParse('${json['size']}') ?? 0,
      status: json['status']?.toString(),
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : const <String, dynamic>{},
    );
  }
}

/// 投票选项（PollResource.choices[]）。
class ColibriPollChoice {
  final String choiceText;
  final double percentage;
  final int voteCount;
  final bool hasVotedChoice;

  ColibriPollChoice({
    required this.choiceText,
    this.percentage = 0,
    this.voteCount = 0,
    this.hasVotedChoice = false,
  });

  factory ColibriPollChoice.fromJson(Map<String, dynamic> json) {
    return ColibriPollChoice(
      choiceText: json['choice_text']?.toString() ?? '',
      percentage: double.tryParse('${json['percentage']}') ?? 0,
      voteCount: json['vote_count'] is int
          ? json['vote_count'] as int
          : int.tryParse('${json['vote_count']}') ?? 0,
      hasVotedChoice: json['has_voted_choice'] == true,
    );
  }
}

/// 投票用户（PollResource.voter_users[]）。
class ColibriPollVoter {
  final int id;
  final String name;
  final String? avatarUrl;

  ColibriPollVoter({required this.id, required this.name, this.avatarUrl});

  factory ColibriPollVoter.fromJson(Map<String, dynamic> json) {
    return ColibriPollVoter(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
    );
  }
}

/// 帖子投票（TimelineResource.relations.poll）。
class ColibriPoll {
  final int id;
  final int postId;
  final bool hasVoted;
  final bool isExpired;
  final bool isAnonymous;
  final List<ColibriPollChoice> choices;
  final List<ColibriPollVoter> voterUsers;

  ColibriPoll({
    required this.id,
    required this.postId,
    required this.hasVoted,
    required this.isExpired,
    required this.isAnonymous,
    required this.choices,
    required this.voterUsers,
  });

  /// 总票（每票人数，等于各选项 vote_count 之和）。
  int get totalVotes => choices.fold(0, (sum, c) => sum + c.voteCount);

  factory ColibriPoll.fromJson(Map<String, dynamic> json) {
    final choicesJson = json['choices'];
    final votersJson = json['voter_users'];
    return ColibriPoll(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      postId: json['post_id'] is int
          ? json['post_id']
          : int.tryParse('${json['post_id']}') ?? 0,
      hasVoted: json['has_voted'] == true,
      isExpired: json['is_expired'] == true,
      isAnonymous: json['is_anonymous'] == true,
      choices: choicesJson is List
          ? choicesJson
              .whereType<Map<String, dynamic>>()
              .map((e) => ColibriPollChoice.fromJson(e))
              .toList()
          : [],
      voterUsers: votersJson is List
          ? votersJson
              .whereType<Map<String, dynamic>>()
              .map((e) => ColibriPollVoter.fromJson(e))
              .toList()
          : [],
    );
  }
}

/// 帖子反应（ReactionCollection 项）。
class ColibriReaction {
  final String unifiedId;
  final String? imageUrl;
  final int total;
  final bool hasReacted;

  ColibriReaction({
    required this.unifiedId,
    this.imageUrl,
    required this.total,
    required this.hasReacted,
  });

  factory ColibriReaction.fromJson(Map<String, dynamic> json) {
    return ColibriReaction(
      unifiedId: json['unified_id']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      total: json['total'] is int
          ? json['total']
          : int.tryParse('${json['total']}') ?? 0,
      hasReacted: json['has_reacted'] == true,
    );
  }
}

/// 帖子（TimelineResource）。
class ColibriPost {
  final int id;
  final String content;
  final String type; // text / media / poll
  final String hashId;

  final int authorId;
  final String authorName;
  final String authorUsername;
  final String authorCaption; // 作者个人标签（显示名，网页头像旁/作者行展示）
  final String? authorAvatarUrl;
  final bool authorVerified;

  final List<ColibriPostMedia> media;
  final List<ColibriReaction> reactions;
  final List<Map<String, dynamic>> previewComments;
  final ColibriPoll? poll; // 投票帖子（type == poll 时非空）

  final int viewsCount;
  final int commentsCount;
  final String commentsCountFormatted;

  final String timeAgo;
  final String dateIso;

  final bool isBookmarked;
  final bool isSensitive;
  final bool isAiGenerated;
  final bool isPinned; // 全局置顶帖（后台置顶，Feed 顶部展示，带置顶标识）
  final bool isAd; // 信息流原生广告影子帖
  final bool canDelete;
  final bool canReport;

  /// 原始 API 响应（TimelineResource JSON），收藏本地缓存直接复用，避免二次序列化。
  final Map<String, dynamic> rawJson;

  ColibriPost({
    required this.id,
    required this.content,
    required this.type,
    required this.hashId,
    required this.authorId,
    required this.authorName,
    required this.authorUsername,
    this.authorCaption = '',
    this.authorAvatarUrl,
    required this.authorVerified,
    required this.media,
    required this.reactions,
    required this.previewComments,
    this.poll,
    required this.viewsCount,
    required this.commentsCount,
    required this.commentsCountFormatted,
    required this.timeAgo,
    required this.dateIso,
    required this.isBookmarked,
    required this.isSensitive,
    required this.isAiGenerated,
    this.isPinned = false,
    this.isAd = false,
    required this.canDelete,
    required this.canReport,
    this.rawJson = const {},
  });

  /// 总点赞数（所有反应 total 之和）。
  int get totalLikes => reactions.fold(0, (sum, r) => sum + r.total);

  /// 是否已点赞（仅心形点赞反应 has_reacted）。
  bool get liked =>
      reactions.any((r) => r.unifiedId == colibriLikeUnifiedId && r.hasReacted);

  /// 浏览量缩写（对齐网页 Num::abbreviate：184 / 1.2K / 3.4M）。
  String get viewsCountFormatted => _abbreviate(viewsCount);

  static String _abbreviate(int n) {
    if (n >= 1000000) {
      final v = n / 1000000;
      return '${v >= 10 ? v.round() : v.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '')}M';
    }
    if (n >= 1000) {
      final v = n / 1000;
      return '${v >= 10 ? v.round() : v.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '')}K';
    }
    return '$n';
  }

  factory ColibriPost.fromJson(Map<String, dynamic> json,
      {bool isPinned = false}) {
    final relations = json['relations'] is Map<String, dynamic>
        ? json['relations'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final user = relations['user'] is Map<String, dynamic>
        ? relations['user'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final reactionsJson = relations['reactions'];
    final mediaJson = relations['media'];
    final commentsJson = relations['comments'];
    final pollJson = relations['poll'];

    final views = json['views_count'] is Map<String, dynamic>
        ? json['views_count'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final commentsCount = json['comments_count'] is Map<String, dynamic>
        ? json['comments_count'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final date = json['date'] is Map<String, dynamic>
        ? json['date'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final meta = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final activity = meta['activity'] is Map<String, dynamic>
        ? meta['activity'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final permissions = meta['permissions'] is Map<String, dynamic>
        ? meta['permissions'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return ColibriPost(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      content: json['content']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      hashId: json['hash_id']?.toString() ?? '',
      authorId:
          user['id'] is int ? user['id'] : int.tryParse('${user['id']}') ?? 0,
      authorName: user['name']?.toString() ?? '',
      authorUsername: user['username']?.toString() ?? '',
      authorCaption: user['caption']?.toString() ?? '',
      authorAvatarUrl: user['avatar_url']?.toString(),
      authorVerified: user['verified'] == true,
      media: mediaJson is List
          ? mediaJson
              .whereType<Map<String, dynamic>>()
              .map((e) => ColibriPostMedia.fromJson(e))
              .toList()
          : [],
      reactions: reactionsJson is List
          ? reactionsJson
              .whereType<Map<String, dynamic>>()
              .map((e) => ColibriReaction.fromJson(e))
              .toList()
          : [],
      previewComments: commentsJson is List
          ? commentsJson.whereType<Map<String, dynamic>>().toList()
          : [],
      poll: pollJson is Map<String, dynamic>
          ? ColibriPoll.fromJson(pollJson)
          : null,
      viewsCount: _toInt(views['raw']),
      commentsCount: _toInt(commentsCount['raw']),
      commentsCountFormatted: commentsCount['formatted']?.toString() ?? '0',
      timeAgo: date['time_ago']?.toString() ?? '',
      dateIso: date['iso']?.toString() ?? '',
      isBookmarked: activity['bookmarked'] == true,
      isSensitive: meta['is_sensitive'] == true,
      isAiGenerated: meta['is_ai_generated'] == true,
      isPinned: isPinned,
      isAd: json['is_ad'] == true,
      canDelete: permissions['can_delete'] == true,
      canReport: permissions['can_report'] == true,
      rawJson: json,
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse('$v') ?? 0;
  }

  /// 复制并局部更新（点赞/收藏/投票后刷新对应字段，保留其余数据）。
  ColibriPost copyWith({
    List<ColibriReaction>? reactions,
    bool? isBookmarked,
    List<ColibriPostMedia>? media,
    ColibriPoll? poll,
    int? commentsCount,
    String? commentsCountFormatted,
    bool? isPinned,
    bool? isAd,
  }) {
    return ColibriPost(
      id: id,
      content: content,
      type: type,
      hashId: hashId,
      authorId: authorId,
      authorName: authorName,
      authorUsername: authorUsername,
      authorCaption: authorCaption,
      authorAvatarUrl: authorAvatarUrl,
      authorVerified: authorVerified,
      media: media ?? this.media,
      reactions: reactions ?? this.reactions,
      previewComments: previewComments,
      poll: poll ?? this.poll,
      viewsCount: viewsCount,
      commentsCount: commentsCount ?? this.commentsCount,
      commentsCountFormatted:
          commentsCountFormatted ?? this.commentsCountFormatted,
      timeAgo: timeAgo,
      dateIso: dateIso,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isSensitive: isSensitive,
      isAiGenerated: isAiGenerated,
      isPinned: isPinned ?? this.isPinned,
      isAd: isAd ?? this.isAd,
      canDelete: canDelete,
      canReport: canReport,
      rawJson: rawJson,
    );
  }
}

/// 评论（CommentResource）。
class ColibriComment {
  final int id;
  final int postId;
  final int? parentId;

  /// 顶层主评论 id（主评论自身为 null）；任意层级的回复都归一到同一线程。
  final int? rootId;
  final bool hasParent;
  final String content;

  final int userId;
  final String userName;
  final String userUsername;
  final String? userAvatarUrl;

  // 被回复的父评论摘要（relations.parent）：内容 + 作者昵称/用户名。
  final String parentUserName;
  final String parentUserUsername;
  final String parentContent;

  final List<ColibriReaction> reactions;
  final String timeAgo;
  final bool canDelete;

  /// 线程内回复总数（仅主评论在 threaded 模式下有值）。
  final int repliesTotal;

  /// 折叠态下主评论携带的最新回复预览（threaded 模式）。
  final List<ColibriComment> previewReplies;

  ColibriComment({
    required this.id,
    required this.postId,
    this.parentId,
    this.rootId,
    required this.hasParent,
    required this.content,
    required this.userId,
    required this.userName,
    required this.userUsername,
    this.userAvatarUrl,
    this.parentUserName = '',
    this.parentUserUsername = '',
    this.parentContent = '',
    required this.reactions,
    required this.timeAgo,
    required this.canDelete,
    this.repliesTotal = 0,
    this.previewReplies = const [],
  });

  int get totalLikes => reactions.fold(0, (sum, r) => sum + r.total);
  bool get liked =>
      reactions.any((r) => r.unifiedId == colibriLikeUnifiedId && r.hasReacted);

  /// 是否为主评论（一级节点）。
  bool get isRoot => !hasParent;

  factory ColibriComment.fromJson(Map<String, dynamic> json) {
    final relations = json['relations'] is Map<String, dynamic>
        ? json['relations'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final user = relations['user'] is Map<String, dynamic>
        ? relations['user'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final parent = relations['parent'] is Map<String, dynamic>
        ? relations['parent'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final parentUser = parent['user'] is Map<String, dynamic>
        ? parent['user'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final reactionsJson = relations['reactions'];
    final previewsJson = relations['preview_replies'];
    final date = json['date'] is Map<String, dynamic>
        ? json['date'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final meta = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final permissions = meta['permissions'] is Map<String, dynamic>
        ? meta['permissions'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return ColibriComment(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      postId: json['post_id'] is int
          ? json['post_id']
          : int.tryParse('${json['post_id']}') ?? 0,
      parentId: json['parent_id'] is int
          ? json['parent_id'] as int
          : int.tryParse('${json['parent_id']}'),
      rootId: json['root_id'] is int
          ? json['root_id'] as int
          : int.tryParse('${json['root_id']}'),
      hasParent: json['has_parent'] == true,
      content: json['content']?.toString() ?? '',
      userId:
          user['id'] is int ? user['id'] : int.tryParse('${user['id']}') ?? 0,
      userName: user['name']?.toString() ?? '',
      userUsername: user['username']?.toString() ?? '',
      userAvatarUrl: user['avatar_url']?.toString(),
      parentUserName: parentUser['name']?.toString() ?? '',
      parentUserUsername: parentUser['username']?.toString() ?? '',
      parentContent: parent['content']?.toString() ?? '',
      reactions: reactionsJson is List
          ? reactionsJson
              .whereType<Map<String, dynamic>>()
              .map((e) => ColibriReaction.fromJson(e))
              .toList()
          : [],
      timeAgo: date['time_ago']?.toString() ?? '',
      canDelete: permissions['can_delete'] == true,
      repliesTotal: json['replies_total'] is int
          ? json['replies_total'] as int
          : int.tryParse('${json['replies_total']}') ?? 0,
      previewReplies: previewsJson is List
          ? previewsJson
              .whereType<Map<String, dynamic>>()
              .map(ColibriComment.fromJson)
              .toList()
          : const [],
    );
  }

  ColibriComment copyWith({
    int? id,
    int? postId,
    int? parentId,
    int? rootId,
    bool? hasParent,
    String? content,
    int? userId,
    String? userName,
    String? userUsername,
    String? userAvatarUrl,
    String? parentUserName,
    String? parentUserUsername,
    String? parentContent,
    List<ColibriReaction>? reactions,
    String? timeAgo,
    bool? canDelete,
    int? repliesTotal,
    List<ColibriComment>? previewReplies,
  }) {
    return ColibriComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      parentId: parentId ?? this.parentId,
      rootId: rootId ?? this.rootId,
      hasParent: hasParent ?? this.hasParent,
      content: content ?? this.content,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userUsername: userUsername ?? this.userUsername,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      parentUserName: parentUserName ?? this.parentUserName,
      parentUserUsername: parentUserUsername ?? this.parentUserUsername,
      parentContent: parentContent ?? this.parentContent,
      reactions: reactions ?? this.reactions,
      timeAgo: timeAgo ?? this.timeAgo,
      canDelete: canDelete ?? this.canDelete,
      repliesTotal: repliesTotal ?? this.repliesTotal,
      previewReplies: previewReplies ?? this.previewReplies,
    );
  }
}

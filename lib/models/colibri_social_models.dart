// ColibriPlus 社交数据模型（资料 / 用户列表 / 通知）。

/// @提及联想用户（autocompletes/mentions 返回的精简结构）。
class ColibriMentionUser {
  final int id;
  final String name;
  final String username;
  final String? avatarUrl;

  ColibriMentionUser({
    required this.id,
    required this.name,
    required this.username,
    this.avatarUrl,
  });

  factory ColibriMentionUser.fromJson(Map<String, dynamic> json) {
    return ColibriMentionUser(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
    );
  }
}

/// 用户资料（ProfileResource）。
class ColibriProfile {
  final int id;
  final String name;
  final String username;
  final String caption;
  final String? avatarUrl;
  final String? coverUrl;
  final String bio;
  final bool verified;
  final String? website;
  final String? countryName; // 公开时的国家（country_privacy 为空）
  final String? city; // 公开时的城市（city_privacy 为空）
  final String joinDateFormatted; // join_date.formatted（如 "2024年8月"）

  final int publicationsCount;
  final int followersCount;
  final int followingCount;

  final bool isOwner;
  final bool isFollowing;
  final bool isFollowRequested;
  final bool isBlocked;
  final bool isBlockedBy;
  final bool isMuted;
  final bool canFollow;
  final bool canMessage;
  final bool canStoryReply;
  final bool canBlock;
  final bool canMute;
  final bool canReport;

  ColibriProfile({
    required this.id,
    required this.name,
    required this.username,
    required this.caption,
    this.avatarUrl,
    this.coverUrl,
    required this.bio,
    required this.verified,
    this.website,
    this.countryName,
    this.city,
    this.joinDateFormatted = '',
    required this.publicationsCount,
    required this.followersCount,
    required this.followingCount,
    required this.isOwner,
    required this.isFollowing,
    required this.isFollowRequested,
    required this.isBlocked,
    required this.isBlockedBy,
    required this.isMuted,
    required this.canFollow,
    required this.canMessage,
    required this.canStoryReply,
    required this.canBlock,
    required this.canMute,
    required this.canReport,
  });

  factory ColibriProfile.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final permissions = meta['permissions'] is Map<String, dynamic>
        ? meta['permissions'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final relationship = meta['relationship'] is Map<String, dynamic>
        ? meta['relationship'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final follow = relationship['follow'] is Map<String, dynamic>
        ? relationship['follow'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final block = relationship['block'] is Map<String, dynamic>
        ? relationship['block'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final muting = relationship['muting'] is Map<String, dynamic>
        ? relationship['muting'] as Map<String, dynamic>
        : const <String, dynamic>{};

    int count(dynamic v) => v is Map
        ? (v['raw'] is int ? v['raw'] as int : int.tryParse('${v['raw']}') ?? 0)
        : 0;
    final joinDate = json['join_date'] is Map<String, dynamic>
        ? json['join_date'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return ColibriProfile(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      caption: json['caption']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      coverUrl: json['cover_url']?.toString(),
      bio: json['bio']?.toString() ?? '',
      verified: json['verified'] == true,
      website: json['website']?.toString(),
      countryName: json['country_name']?.toString(),
      city: json['city']?.toString(),
      joinDateFormatted: joinDate['formatted']?.toString() ?? '',
      publicationsCount: count(json['publications_count']),
      followersCount: count(json['followers_count']),
      followingCount: count(json['following_count']),
      isOwner: meta['is_owner'] == true,
      isFollowing: follow['following'] == true,
      isFollowRequested: follow['requested'] == true,
      isBlocked: block['blocking'] == true,
      isBlockedBy: block['blocked_by'] == true,
      isMuted: muting['muting'] == true,
      canFollow: permissions['can_follow'] == true,
      canMessage: permissions['can_message'] == true,
      canStoryReply: permissions['can_story_reply'] == true,
      canBlock: permissions['can_block'] == true,
      canMute: permissions['can_mute'] == true,
      canReport: permissions['can_report'] == true,
    );
  }

  ColibriProfile copyWith({
    int? followersCount,
    bool? isFollowing,
    bool? isFollowRequested,
    bool? isBlocked,
    bool? isMuted,
  }) {
    return ColibriProfile(
      id: id,
      name: name,
      username: username,
      caption: caption,
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
      bio: bio,
      verified: verified,
      website: website,
      countryName: countryName,
      city: city,
      joinDateFormatted: joinDateFormatted,
      publicationsCount: publicationsCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount,
      isOwner: isOwner,
      isFollowing: isFollowing ?? this.isFollowing,
      isFollowRequested: isFollowRequested ?? this.isFollowRequested,
      isBlocked: isBlocked ?? this.isBlocked,
      isBlockedBy: isBlockedBy,
      isMuted: isMuted ?? this.isMuted,
      canFollow: canFollow,
      canMessage: canMessage,
      canStoryReply: canStoryReply,
      canBlock: canBlock,
      canMute: canMute,
      canReport: canReport,
    );
  }

  /// 完整位置串（"国家, 城市"），无则空。
  String get location {
    final parts = [
      if ((countryName ?? '').isNotEmpty) countryName!,
      if ((city ?? '').isNotEmpty) city!
    ];
    return parts.join(', ');
  }

  /// 数字缩写（对齐网页 Num::abbreviate：1.2K / 3.4M）。
  static String abbreviate(int n) {
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
}

/// 个人主页「信息」标签数据（profile/profile/details）。
class ColibriProfileDetails {
  final String joinDate; // ISO 加入时间
  final String location; // "国家, 城市"（按隐私设置返回）
  final String birthdate; // "8 月, 1999" 之类原始串
  final int? age;
  final String gender; // 已本地化的性别文案
  final String website;
  final String lastActive; // "3 小时前"（getTimeAgo）
  final String? email; // 公开时的邮箱
  final String? phone; // 公开时的电话
  final List<ColibriSocialLink> socialLinks;

  ColibriProfileDetails({
    this.joinDate = '',
    this.location = '',
    this.birthdate = '',
    this.age,
    this.gender = '',
    this.website = '',
    this.lastActive = '',
    this.email,
    this.phone,
    this.socialLinks = const [],
  });

  factory ColibriProfileDetails.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ColibriProfileDetails();
    final info = json['info'] is Map<String, dynamic>
        ? json['info'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final contacts = json['contacts'] is Map<String, dynamic>
        ? json['contacts'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final links =
        json['social_links'] is List ? json['social_links'] as List : const [];
    return ColibriProfileDetails(
      joinDate: info['join_date']?.toString() ?? '',
      location: info['location']?.toString() ?? '',
      birthdate: info['birthdate']?.toString() ?? '',
      age: info['age'] is int
          ? info['age'] as int
          : int.tryParse('${info['age']}'),
      gender: info['gender']?.toString() ?? '',
      website: info['website']?.toString() ?? '',
      lastActive: info['last_active']?.toString() ?? '',
      email: contacts['email']?.toString(),
      phone: contacts['phone']?.toString(),
      socialLinks: links
          .whereType<Map<String, dynamic>>()
          .map((e) => ColibriSocialLink.fromJson(e))
          .toList(),
    );
  }
}

/// 社交链接（social_links 项）。
class ColibriSocialLink {
  final String url;
  final String platform;
  final String name;
  final String? iconUrl;

  ColibriSocialLink(
      {required this.url, this.platform = '', this.name = '', this.iconUrl});

  factory ColibriSocialLink.fromJson(Map<String, dynamic> json) {
    return ColibriSocialLink(
      url: json['url']?.toString() ?? '',
      platform: json['platform']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      iconUrl: json['icon_url']?.toString(),
    );
  }
}

/// 用户列表项（PeopleResource / 关注粉丝 / 搜索结果）。
class ColibriPeople {
  final int id;
  final String name;
  final String username;
  final String? avatarUrl;
  final bool verified;
  final String caption;
  final String bio;
  final int followersCount;
  final bool isFollowing;
  final bool isOwner;

  ColibriPeople({
    required this.id,
    required this.name,
    required this.username,
    this.avatarUrl,
    required this.verified,
    required this.caption,
    required this.bio,
    required this.followersCount,
    required this.isFollowing,
    required this.isOwner,
  });

  factory ColibriPeople.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final relationship = meta['relationship'] is Map<String, dynamic>
        ? meta['relationship'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final follow = relationship['follow'] is Map<String, dynamic>
        ? relationship['follow'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final followers = json['followers_count'] is Map<String, dynamic>
        ? json['followers_count'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return ColibriPeople(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      verified: json['verified'] == true,
      caption: json['caption']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      followersCount: followers['raw'] is int
          ? followers['raw'] as int
          : int.tryParse('${followers['raw']}') ?? 0,
      isFollowing: follow['following'] == true,
      isOwner: meta['is_owner'] == true,
    );
  }
}

/// 黑名单项（BlockResource）。
class ColibriBlockedUser {
  final int id;
  final String name;
  final String username;
  final String? avatarUrl;
  final bool verified;

  ColibriBlockedUser({
    required this.id,
    required this.name,
    required this.username,
    this.avatarUrl,
    required this.verified,
  });

  factory ColibriBlockedUser.fromJson(Map<String, dynamic> json) {
    // BlockResource 结构：{ id, relations: { blocked: UserPreview } }
    final relations = json['relations'] is Map<String, dynamic>
        ? json['relations'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final user = relations['blocked'] is Map<String, dynamic>
        ? relations['blocked'] as Map<String, dynamic>
        : json; // 兜底：直接是用户对象

    return ColibriBlockedUser(
      id: user['id'] is int ? user['id'] : int.tryParse('${user['id']}') ?? 0,
      name: user['name']?.toString() ?? '',
      username: user['username']?.toString() ?? '',
      avatarUrl: user['avatar_url']?.toString(),
      verified: user['verified'] == true,
    );
  }
}

/// 通知（NotificationResource）。
class ColibriNotification {
  final String id;
  final String message;
  final String type;
  final Map<String, dynamic> actor;
  final Map<String, dynamic> entity;
  final bool isRead;
  final Map<String, dynamic> metadata;
  final String timeAgo;

  ColibriNotification({
    required this.id,
    required this.message,
    required this.type,
    required this.actor,
    required this.entity,
    required this.isRead,
    required this.metadata,
    required this.timeAgo,
  });

  /// 通知触发者名字（actor 里取）。
  String get actorName => actor['name']?.toString() ?? '';

  /// 通知触发者头像。
  String? get actorAvatar => actor['avatar_url']?.toString();

  /// 关联内容（帖子/评论正文预览，entity.content）。
  String get entityContent => entity['content']?.toString() ?? '';

  /// 关联内容的预览图（entity.preview_lqip_base64）。
  String? get entityPreviewImage => entity['preview_lqip_base64']?.toString();

  /// 是否点赞/表情反应类通知。
  bool get isReaction => type == 'post.reacted' || type == 'comment.reacted';

  /// 反应表情图片（metadata.reaction_image_url）。
  String? get reactionImage => metadata['reaction_image_url']?.toString();

  factory ColibriNotification.fromJson(Map<String, dynamic> json) {
    final actor = json['actor'] is Map<String, dynamic>
        ? json['actor'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final entity = json['entity'] is Map<String, dynamic>
        ? json['entity'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final metadata = json['metadata'] is Map<String, dynamic>
        ? json['metadata'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final date = json['date'] is Map<String, dynamic>
        ? json['date'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return ColibriNotification(
      id: json['id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      actor: actor,
      entity: entity,
      isRead: json['is_read'] == true,
      metadata: metadata,
      timeAgo: date['time_ago']?.toString() ?? '',
    );
  }

  // ===================== 营销通知（marketing.platform）=====================

  /// 平台营销通知（后台批量发送；点击不跳转发送者主页）。
  bool get isMarketing =>
      type == 'marketing.platform' || metadata['marketing'] == true;

  /// 活动标题（entity.title）。
  String get marketingTitle => entity['title']?.toString() ?? '';

  /// Banner 图（metadata.image_url，发送时定格）。
  String? get marketingBannerImage {
    final v = metadata['image_url'] ?? entity['image_url'];
    final s = v?.toString();
    return (s == null || s.isEmpty) ? null : s;
  }

  /// 标题样式（metadata.style：title_size sm/md/lg、title_weight normal/medium/semibold/bold）。
  Map<String, dynamic> get marketingStyle =>
      metadata['style'] is Map<String, dynamic>
          ? metadata['style'] as Map<String, dynamic>
          : const <String, dynamic>{};

  /// 落地链接（查看详情外链）。
  String? get marketingDestinationUrl {
    final v = metadata['destination_url'] ?? entity['destination_url'];
    final s = v?.toString();
    return (s == null || s.isEmpty) ? null : s;
  }

  /// 关联站内帖子快照（metadata.posts，最多 3 条）。
  List<Map<String, dynamic>> get marketingPosts {
    final list = metadata['posts'];
    if (list is! List) return const [];
    return list.whereType<Map<String, dynamic>>().toList();
  }
}

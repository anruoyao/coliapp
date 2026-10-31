import 'package:untitled/models/colibri_post_models.dart';

/// ColibriPlus 故事（Story）数据模型。

/// 故事条条目（FeedResource）。
class ColibriStoryFeed {
  final String storyUuid;
  final String userName;
  final String? avatarUrl;
  final bool isSeen;
  final bool isOwner;

  ColibriStoryFeed({
    required this.storyUuid,
    required this.userName,
    this.avatarUrl,
    required this.isSeen,
    required this.isOwner,
  });

  factory ColibriStoryFeed.fromJson(Map<String, dynamic> json) {
    final relations = json['relations'] is Map<String, dynamic>
        ? json['relations'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final user = relations['user'] is Map<String, dynamic>
        ? relations['user'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return ColibriStoryFeed(
      storyUuid: json['story_uuid']?.toString() ?? '',
      userName: user['name']?.toString() ?? '',
      avatarUrl: user['avatar_url']?.toString(),
      isSeen: json['is_seen'] == true,
      isOwner: json['is_owner'] == true,
    );
  }
}

/// 单个用户的故事（StoryResource）。
class ColibriStory {
  final int id;
  final String storyUuid;
  final int userId;
  final String userName;
  final String? username;
  final String? avatarUrl;
  final List<ColibriStoryFrame> frames;
  final bool isOwner;
  final String url;
  final bool canDelete;
  final bool canReport;
  final bool canHide;

  ColibriStory({
    required this.id,
    required this.storyUuid,
    required this.userId,
    required this.userName,
    this.username,
    this.avatarUrl,
    required this.frames,
    required this.isOwner,
    this.url = '',
    required this.canDelete,
    required this.canReport,
    required this.canHide,
  });

  factory ColibriStory.fromJson(Map<String, dynamic> json) {
    final relations = json['relations'] is Map<String, dynamic>
        ? json['relations'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final user = relations['user'] is Map<String, dynamic>
        ? relations['user'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final framesJson = relations['frames'];
    final meta = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final permissions = json['permissions'] is Map<String, dynamic>
        ? json['permissions'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return ColibriStory(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      storyUuid: json['story_uuid']?.toString() ?? '',
      userId:
          user['id'] is int ? user['id'] : int.tryParse('${user['id']}') ?? 0,
      userName: user['name']?.toString() ?? '',
      username: user['username']?.toString(),
      avatarUrl: user['avatar_url']?.toString(),
      frames: framesJson is List
          ? framesJson
              .whereType<Map<String, dynamic>>()
              .map((e) => ColibriStoryFrame.fromJson(e))
              .toList()
          : [],
      isOwner: meta['is_owner'] == true,
      url: json['url']?.toString() ?? '',
      canDelete: permissions['can_delete'] == true,
      canReport: permissions['can_report'] == true,
      canHide: permissions['can_hide'] == true,
    );
  }
}

/// 故事帧（StoryResource.relations.frames[]）。
class ColibriStoryFrame {
  final int id;
  final String type; // image / video
  final String content;
  final ColibriPostMedia? media;
  final int durationSeconds;
  final bool isSeen;
  final String timeAgo;

  ColibriStoryFrame({
    required this.id,
    required this.type,
    required this.content,
    this.media,
    required this.durationSeconds,
    required this.isSeen,
    required this.timeAgo,
  });

  factory ColibriStoryFrame.fromJson(Map<String, dynamic> json) {
    final activity = json['activity'] is Map<String, dynamic>
        ? json['activity'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final date = json['date'] is Map<String, dynamic>
        ? json['date'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final mediaJson = json['media'];

    ColibriPostMedia? media;
    if (mediaJson is Map<String, dynamic> && mediaJson.isNotEmpty) {
      media = ColibriPostMedia.fromJson(mediaJson);
    }

    return ColibriStoryFrame(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      type: json['type']?.toString() ?? 'image',
      content: json['content']?.toString() ?? '',
      media: media,
      durationSeconds: json['duration_seconds'] is int
          ? json['duration_seconds'] as int
          : int.tryParse('${json['duration_seconds']}') ?? 5,
      isSeen: activity['is_seen'] == true,
      timeAgo: date['time_ago']?.toString() ?? '',
    );
  }
}

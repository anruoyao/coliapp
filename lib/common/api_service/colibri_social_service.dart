import 'package:untitled/common/api_service/colibri_api.dart';
import 'package:untitled/models/colibri_post_models.dart';
import 'package:untitled/models/colibri_social_models.dart';

/// ColibriPlus 社交 API（资料 / 关系 / 通知 / 探索搜索 / 设置）。
class ColibriSocialService {
  static final shared = ColibriSocialService();

  ColibriApi get _api => ColibriApi.shared;

  // ===================== 资料 =====================

  /// 按用户名获取资料。
  Future<ColibriProfile> fetchProfile(String username) async {
    final resp = await _api.get('profile/profile', query: {'id': username});
    final data = resp['data'];
    if (data is! Map<String, dynamic>) throw ColibriApiException('用户不存在');
    return ColibriProfile.fromJson(data);
  }

  /// 用户帖子（filter[type]=posts|media，cursor 分页）。
  /// 注意：colibri 的 profile 路由是双层前缀 `profile/profile/...`。
  Future<List<ColibriPost>> fetchProfilePosts(int userId,
      {int? cursor, String type = 'posts'}) async {
    final resp = await _api.get('profile/profile/posts', query: {
      'id': '$userId',
      'filter[type]': type,
      if (cursor != null && cursor > 0) 'filter[cursor]': '$cursor',
    });
    final data = resp['data'];
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => ColibriPost.fromJson(e))
        .toList();
  }

  /// 个人主页「信息」详情（加入时间/位置/生日/性别/联系方式/社交链接，按隐私设置过滤）。
  Future<ColibriProfileDetails> fetchProfileDetails(int userId) async {
    final resp =
        await _api.get('profile/profile/details', query: {'id': '$userId'});
    final data = resp['data'];
    return ColibriProfileDetails.fromJson(
        data is Map<String, dynamic> ? data : null);
  }

  /// 粉丝/关注列表。
  Future<List<ColibriPeople>> fetchConnections(int userId,
      {required bool following, int? cursor}) async {
    final path =
        following ? 'profile/profile/followings' : 'profile/profile/followers';
    final resp = await _api.get(path, query: {
      'id': '$userId',
      if (cursor != null && cursor > 0) 'cursor': '$cursor',
    });
    final data = resp['data'];
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => ColibriPeople.fromJson(e))
        .toList();
  }

  // ===================== 关系 =====================

  /// 关注/取关/取消请求（toggle）的结果：是否已关注 / 是否请求待批准。
  Future<({bool following, bool requested})> toggleFollow(int userId) async {
    final resp = await _api.post('relations/follow/user', body: {'id': userId});
    final data = resp['data'];
    if (data is Map<String, dynamic>) {
      final relationship = data['relationship'];
      if (relationship is Map<String, dynamic>) {
        final follow = relationship['follow'];
        if (follow is Map<String, dynamic>) {
          return (
            following: follow['following'] == true,
            requested: follow['requested'] == true,
          );
        }
      }
    }
    return (following: false, requested: false);
  }

  /// 批准对方对我的关注请求。
  Future<void> acceptFollowRequest(int userId) async {
    await _api.post('relations/accept/user', body: {'id': userId});
  }

  /// 拒绝对方对我的关注请求。
  Future<void> declineFollowRequest(int userId) async {
    await _api.post('relations/decline/user', body: {'id': userId});
  }

  /// 拉黑/解除（toggle），返回是否已拉黑。
  Future<bool> toggleBlock(int userId) async {
    final resp =
        await _api.post('relations/block/user', body: {'blocked_id': userId});
    final data = resp['data'];
    if (data is Map<String, dynamic>) {
      final relationship = data['relationship'];
      if (relationship is Map<String, dynamic>) {
        final block = relationship['block'];
        if (block is Map<String, dynamic>) {
          return block['blocking'] == true;
        }
      }
    }
    return false;
  }

  /// 静音/取消静音（toggle），返回是否已静音。
  Future<bool> toggleMute(int userId) async {
    final resp =
        await _api.post('relations/mute/user', body: {'muted_id': userId});
    final data = resp['data'];
    if (data is Map<String, dynamic>) {
      final relationship = data['relationship'];
      if (relationship is Map<String, dynamic>) {
        final muting = relationship['muting'];
        if (muting is Map<String, dynamic>) {
          return muting['muting'] == true;
        }
      }
    }
    return false;
  }

  /// 黑名单列表。
  Future<List<ColibriBlockedUser>> fetchBlockedUsers() async {
    final resp = await _api.get('relations/block/list');
    final data = resp['data'];
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => ColibriBlockedUser.fromJson(e))
        .toList();
  }

  /// 静音列表（结构同黑名单，复用 ColibriBlockedUser）。
  Future<List<ColibriBlockedUser>> fetchMutedUsers() async {
    final resp = await _api.get('relations/mute/list');
    final data = resp['data'];
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => ColibriBlockedUser.fromJson(e))
        .toList();
  }

  // ===================== 通知 =====================

  /// 全部通知（拉取后服务端自动标记已读）。
  Future<List<ColibriNotification>> fetchNotifications() async {
    final resp = await _api.get('notifications/all');
    final data = resp['data'];
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => ColibriNotification.fromJson(e))
        .toList();
  }

  Future<int> fetchUnreadNotifications() async {
    final resp = await _api.get('notifications/unread/count');
    final data = resp['data'];
    if (data is Map<String, dynamic>) {
      return data['raw'] is int
          ? data['raw'] as int
          : int.tryParse('${data['raw']}') ?? 0;
    }
    return 0;
  }

  Future<void> deleteNotification(String notificationId) async {
    await _api.delete('notifications/delete',
        body: {'notification_id': notificationId});
  }

  // ===================== 搜索 =====================

  /// @提及联想（autocompletes/mentions，query 最少 2 个字符，按 username 模糊匹配）。
  Future<List<ColibriMentionUser>> searchMentions(String query) async {
    final resp =
        await _api.post('autocompletes/mentions', body: {'query': query});
    final data = resp['data'];
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => ColibriMentionUser.fromJson(e))
        .toList();
  }

  /// 搜索用户（explore/people）。
  Future<List<ColibriPeople>> searchPeople(
      {String query = '', int page = 1}) async {
    final resp = await _api.post('explore/people', body: {
      'filter': {'query': query, 'page': page},
    });
    final data = resp['data'];
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => ColibriPeople.fromJson(e))
        .toList();
  }

  /// 探索帖子。
  Future<List<ColibriPost>> searchPosts({int page = 1, int? onset}) async {
    final resp = await _api.post('explore/posts', body: {
      'filter': {
        'page': page,
        if (onset != null) 'onset': onset,
      },
    });
    final data = resp['data'];
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => ColibriPost.fromJson(e))
        .toList();
  }

  // ===================== 编辑资料 =====================

  /// 拉取当前账户设置（含校验规则与用户资料字段，account/settings）。
  Future<Map<String, dynamic>> fetchAccountSettings() async {
    final resp = await _api.get('settings/account/settings');
    return resp['data'] is Map<String, dynamic>
        ? resp['data'] as Map<String, dynamic>
        : <String, dynamic>{};
  }

  /// 更新基本资料（对齐后端 account/update 所需字段）。
  /// 必填：username、first_name；其余可选。
  Future<void> updateProfile({
    String? username,
    String? firstName,
    String? lastName,
    String? bio,
    String? website,
    String? caption,
    String? gender,
  }) async {
    await _api.put('settings/account/update', body: {
      if (username != null) 'username': username,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (bio != null) 'bio': bio,
      if (website != null) 'website': website,
      if (caption != null) 'caption': caption,
      if (gender != null) 'gender': gender,
    });
  }

  /// 更新头像（multipart，字段名 avatar）。
  Future<String?> updateAvatar(String imagePath) async {
    final resp = await _api.postMultipart('settings/account/avatar/update',
        files: {'avatar': imagePath});
    final data = resp['data'];
    return data is Map ? data['avatar_url']?.toString() : null;
  }

  /// 更新背景图/封面（multipart，字段名 cover）。
  Future<void> updateCover(String imagePath) async {
    await _api.postMultipart('settings/account/cover/update',
        files: {'cover': imagePath});
  }
}

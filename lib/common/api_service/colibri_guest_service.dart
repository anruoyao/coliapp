import 'package:untitled/common/api_service/colibri_api.dart';
import 'package:untitled/models/colibri_post_models.dart';
import 'package:untitled/models/colibri_social_models.dart';

/// 访客 bootstrap（GET guest/v1/bootstrap）解析结果。
class GuestBootstrap {
  /// 后台访客总开关。
  final bool enabled;

  /// 会话认证状态（访客请求恒为 false；携带有效 token 时为 true）。
  final bool authStatus;

  /// 已登录用户数据（auth.user），访客为 null。
  final Map<String, dynamic>? user;

  /// 访客能力矩阵（全部写/互动能力为 false）。
  final Map<String, dynamic> capabilities;

  /// 访客可见导航项（feed/post/profile）。
  final List<String> visibleNav;

  final String version;
  final String name;

  const GuestBootstrap({
    required this.enabled,
    required this.authStatus,
    this.user,
    this.capabilities = const {},
    this.visibleNav = const [],
    this.version = '',
    this.name = '',
  });
}

/// ColibriPlus 访客公开只读 API（/guest/v1/*）。
///
/// 与登录态接口完全隔离：
/// - 独立路由前缀、独立控制器/资源（后端）；
/// - 所有请求不携带 Authorization（[ColibriApi.get] auth=false）；
/// - 仅 GET：精选流 / 帖子详情与评论 / 脱敏公开主页。
class ColibriGuestService {
  static final shared = ColibriGuestService();

  ColibriApi get _api => ColibriApi.shared;

  static const _prefix = 'guest/v1/';

  /// 访客初始化：平台信息 + 认证状态 + 总开关 + 能力矩阵 + 可见导航。
  Future<GuestBootstrap> fetchBootstrap() async {
    final resp = await _api.get('${_prefix}bootstrap', auth: false);
    final data = resp['data'];
    if (data is! Map<String, dynamic>) {
      throw ColibriApiException('访客初始化失败：响应缺少 data');
    }
    final auth = data['auth'] is Map<String, dynamic>
        ? data['auth'] as Map<String, dynamic>
        : <String, dynamic>{};
    final guest = data['guest'] is Map<String, dynamic>
        ? data['guest'] as Map<String, dynamic>
        : <String, dynamic>{};
    final caps = guest['capabilities'] is Map<String, dynamic>
        ? guest['capabilities'] as Map<String, dynamic>
        : <String, dynamic>{};
    final nav =
        guest['visible_nav'] is List ? guest['visible_nav'] as List : const [];
    final user = auth['user'];
    return GuestBootstrap(
      enabled: guest['enabled'] == true,
      authStatus: auth['status'] == true,
      user: user is Map<String, dynamic> ? user : null,
      capabilities: caps,
      visibleNav: nav.map((e) => '$e').toList(),
      version: data['version']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
    );
  }

  /// 精选公开帖子流（固定分页，禁止客户端排序/筛选）。
  Future<List<ColibriPost>> fetchFeed({int page = 1}) async {
    final resp = await _api
        .get('${_prefix}feed', auth: false, query: {'filter[page]': '$page'});
    final data = resp['data'];
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(ColibriPost.fromJson)
        .toList();
  }

  /// 公开帖子详情（作者脱敏概览 + 帖子 + 首批评论）。
  /// 不可见（敏感/封禁作者/不存在）时后端返回 404，抛 [ColibriApiException]。
  /// threaded=true 时只返回主评论（携带回复预览与总数）。
  Future<({ColibriPost post, List<ColibriComment> comments})> fetchPostDetail(
      String hashId,
      {bool threaded = false}) async {
    final resp = await _api.get('${_prefix}post/$hashId', auth: false, query: {
      if (threaded) 'threaded': '1',
    });
    final data = resp['data'];
    if (data is! Map<String, dynamic>) {
      throw ColibriApiException('帖子不存在');
    }
    final postJson = data['post'];
    if (postJson is! Map<String, dynamic>) {
      throw ColibriApiException('帖子不存在');
    }
    final commentsJson = data['comments'];
    final comments = commentsJson is List
        ? commentsJson
            .whereType<Map<String, dynamic>>()
            .map(ColibriComment.fromJson)
            .toList()
        : <ColibriComment>[];
    return (post: ColibriPost.fromJson(postJson), comments: comments);
  }

  /// 主评论游标分页（cursor = 上一页最后一条主评论 id）。threaded=true 为树状模式。
  Future<List<ColibriComment>> fetchPostComments(String hashId,
      {int? cursor, bool threaded = false}) async {
    final resp =
        await _api.get('${_prefix}post/$hashId/comments', auth: false, query: {
      if (cursor != null && cursor > 0) 'cursor': '$cursor',
      if (threaded) 'threaded': '1',
    });
    final data = resp['data'];
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(ColibriComment.fromJson)
        .toList();
  }

  /// 主评论线程下的回复分页（只读）。
  Future<({List<ColibriComment> replies, int total})> fetchCommentReplies(
      int rootId,
      {int? cursor}) async {
    final resp = await _api
        .get('${_prefix}post/comment/$rootId/replies', auth: false, query: {
      if (cursor != null && cursor > 0) 'cursor': '$cursor',
    });
    final data = resp['data'];
    final list = data is List
        ? data
            .whereType<Map<String, dynamic>>()
            .map(ColibriComment.fromJson)
            .toList()
        : <ColibriComment>[];
    final meta = resp['meta'];
    final total = meta is Map<String, dynamic>
        ? int.tryParse('${meta['total']}') ?? list.length
        : list.length;
    return (replies: list, total: total);
  }

  /// 脱敏公开用户主页。
  Future<ColibriProfile> fetchProfile(String username) async {
    final resp = await _api.get('${_prefix}profile/$username', auth: false);
    final data = resp['data'];
    if (data is! Map<String, dynamic>) {
      throw ColibriApiException('用户不存在');
    }
    return ColibriProfile.fromJson(data);
  }

  /// 该用户的公开帖子（type=posts|media，cursor 分页；同样遵守访客可见性边界）。
  Future<List<ColibriPost>> fetchProfilePosts(
    String username, {
    int? cursor,
    String type = 'posts',
  }) async {
    final resp = await _api
        .get('${_prefix}profile/$username/posts', auth: false, query: {
      'filter[type]': type,
      if (cursor != null && cursor > 0) 'cursor': '$cursor',
    });
    final data = resp['data'];
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(ColibriPost.fromJson)
        .toList();
  }
}

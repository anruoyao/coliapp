import 'package:untitled/common/api_service/colibri_api.dart';
import 'package:untitled/models/colibri_post_models.dart';

typedef TranslationResult = ({
  String translatedText,
  String sourceLanguage,
});

/// ColibriPlus 时间线 API（/timeline/* 与 /post/editor/*）。
class ColibriTimelineService {
  static final shared = ColibriTimelineService();

  ColibriApi get _api => ColibriApi.shared;

  /// 翻译用户简介。服务端从资料表读取简介，并跨用户持久化共享翻译结果。
  Future<TranslationResult> translateBio({
    required int profileId,
    required String text,
    required String target,
  }) async {
    final resp = await _api.post('translator/translate', body: {
      'profile_id': profileId,
      'text': text,
      'target': target,
    });
    final data = resp['data'];
    final translatedText =
        data is Map<String, dynamic> ? data['translated_text'] : null;
    if (translatedText is String && translatedText.trim().isNotEmpty) {
      return (
        translatedText: translatedText,
        sourceLanguage: data['source_language']?.toString() ?? '',
      );
    }
    throw ColibriApiException('翻译失败');
  }

  /// 点赞默认表情（unified_id 为十六进制码点，对应 assets/emoji/img-apple-64/{id}.png）。
  static const String likeUnifiedId = '2764-fe0f';

  /// Normalize app locale codes (including zh-Hans and regional variants).
  static String translationTarget(String languageCode) {
    final base = languageCode.toLowerCase().split(RegExp(r'[-_]')).first;
    const supported = {
      'en',
      'zh',
      'ru',
      'ja',
      'ko',
      'fr',
      'de',
      'es',
      'pt',
      'ar',
      'it',
      'tr',
      'pl',
      'uk'
    };
    return supported.contains(base) ? base : 'en';
  }

  static String translationLanguageName(String sourceLanguage) {
    final code = sourceLanguage
        .trim()
        .toLowerCase()
        .replaceAll('_', '-')
        .split('-')
        .first;
    const names = {
      'ar': 'Arabic',
      'bg': 'Bulgarian',
      'bn': 'Bengali',
      'cs': 'Czech',
      'da': 'Danish',
      'de': 'German',
      'el': 'Greek',
      'en': 'English',
      'es': 'Spanish',
      'fa': 'Persian',
      'fi': 'Finnish',
      'fr': 'French',
      'he': 'Hebrew',
      'hi': 'Hindi',
      'hr': 'Croatian',
      'hu': 'Hungarian',
      'id': 'Indonesian',
      'it': 'Italian',
      'ja': 'Japanese',
      'ko': 'Korean',
      'ms': 'Malay',
      'nl': 'Dutch',
      'no': 'Norwegian',
      'pl': 'Polish',
      'pt': 'Portuguese',
      'ro': 'Romanian',
      'ru': 'Russian',
      'sk': 'Slovak',
      'sv': 'Swedish',
      'th': 'Thai',
      'tr': 'Turkish',
      'uk': 'Ukrainian',
      'vi': 'Vietnamese',
      'zh': 'Chinese',
    };
    return names[code] ?? sourceLanguage.trim();
  }

  // ===================== Feed =====================

  /// 拉取关注时间线。分页用 filter[page]（页码），filter[onset] 传已有第一条 id 用于拉取新帖。
  Future<List<ColibriPost>> fetchFeed({int page = 1, int? onset}) async {
    final resp = await _api.get('timeline/feed', query: {
      'filter[page]': '$page',
      if (onset != null) 'filter[onset]': '$onset',
    });
    final data = resp['data'];
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => ColibriPost.fromJson(e))
        .toList();
  }

  /// 拉取推荐时间线（explore：全部作者的帖子，按互动量排序）。
  Future<List<ColibriPost>> fetchRecommendFeed(
      {int page = 1, int? onset}) async {
    final resp = await _api.post('explore/posts', body: {
      'filter': {
        'page': page,
        if (onset != null && onset > 0) 'onset': onset,
      },
    });
    final data = resp['data'];
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => ColibriPost.fromJson(e))
        .toList();
  }

  /// 拉取全局置顶帖子（管理后台置顶，关注 / 推荐 Feed 顶部展示）。
  Future<List<ColibriPost>> fetchGlobalPins() async {
    final resp = await _api.get('pins/posts/global');
    final data = resp['data'];
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => ColibriPost.fromJson(e, isPinned: true))
        .toList();
  }

  /// 帖子详情（含作者与首屏评论）。
  /// threaded=true 时评论只返回主评论，每条带 replies_total + preview_replies（B站式树状）。
  Future<({ColibriPost post, List<ColibriComment> comments})> fetchPostDetail(
      String hashId,
      {bool threaded = false}) async {
    final resp = await _api.get('timeline/post/$hashId', query: {
      if (threaded) 'threaded': '1',
    });
    final data = resp['data'];
    if (data is! Map<String, dynamic>) {
      throw ColibriApiException('帖子不存在');
    }
    final post = ColibriPost.fromJson(data['post'] as Map<String, dynamic>);
    final commentsJson = data['comments'];
    final comments = commentsJson is List
        ? commentsJson
            .whereType<Map<String, dynamic>>()
            .map((e) => ColibriComment.fromJson(e))
            .toList()
        : <ColibriComment>[];
    return (post: post, comments: comments);
  }

  /// 主评论分页（cursor = 上一页最后一条主评论 id）。
  /// threaded=true 仅返回主评论（携带回复预览与总数）。
  Future<List<ColibriComment>> fetchPostComments(String hashId,
      {int? cursor, bool threaded = false}) async {
    final resp = await _api.get('timeline/post/$hashId/comments', query: {
      if (cursor != null && cursor > 0) 'cursor': '$cursor',
      if (threaded) 'threaded': '1',
    });
    final data = resp['data'];
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => ColibriComment.fromJson(e))
        .toList();
  }

  /// 拉取某条主评论线程下的回复（id DESC 游标分页）。
  Future<({List<ColibriComment> replies, int total})> fetchCommentReplies(
      int rootId,
      {int? cursor}) async {
    final resp =
        await _api.get('timeline/post/comment/$rootId/replies', query: {
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

  // ===================== 帖子操作 =====================

  /// 翻译帖子正文。服务端会将结果永久缓存并共享给其他用户。
  Future<TranslationResult> translatePost(
      {required int postId, required String target}) async {
    final resp = await _api.post('translator/translate',
        body: {'post_id': postId, 'target': target});
    final data = resp['data'];
    final text = data is Map<String, dynamic> ? data['translated_text'] : null;
    if (text is String && text.trim().isNotEmpty) {
      return (
        translatedText: text,
        sourceLanguage: data['source_language']?.toString() ?? '',
      );
    }
    throw ColibriApiException('翻译失败');
  }

  /// 点赞/取消点赞（reaction 是 toggle）。
  Future<List<ColibriReaction>> togglePostReaction(int postId,
      {String unifiedId = likeUnifiedId}) async {
    final resp = await _api.post('timeline/post/reaction/add', body: {
      'post_id': postId,
      'unified_id': unifiedId,
    });
    final data = resp['data'];
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => ColibriReaction.fromJson(e))
        .toList();
  }

  /// 收藏/取消收藏（toggle），返回是否已收藏。
  Future<bool> togglePostBookmark(int postId) async {
    final resp =
        await _api.post('timeline/post/bookmarks/add', body: {'id': postId});
    final data = resp['data'];
    if (data is Map<String, dynamic>) return data['bookmarked'] == true;
    return false;
  }

  /// 当前用户收藏的帖子列表（服务端一次返回全部，≤300 条，无游标分页）。
  Future<List<ColibriPost>> fetchBookmarks() async {
    final resp =
        await _api.post('bookmarks/bookmarks', body: {'type': 'posts'});
    final data = resp['data'];
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => ColibriPost.fromJson(e))
        .toList();
  }

  /// 删除帖子。
  Future<void> deletePost(int postId) async {
    await _api.delete('timeline/post/delete', body: {'id': postId});
  }

  // ===================== 举报 =====================

  /// 拉取举报理由。返回 (title, description, reasons: [{title, description}]).
  Future<
      ({
        String title,
        String description,
        List<Map<String, dynamic>> reasons
      })> fetchReportReasons({
    String type = 'post',
  }) async {
    final resp =
        await _api.get('feedback/report/reasons', query: {'type': type});
    final data = resp['data'];
    if (data is! Map<String, dynamic>) throw ColibriApiException('无法获取举报理由');
    final reasons = data['reasons'];
    return (
      title: data['title']?.toString() ?? '举报',
      description: data['description']?.toString() ?? '',
      reasons: reasons is List
          ? reasons.whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[],
    );
  }

  /// 提交举报（type = post/user/group，reason_index 对应理由下标，comment 为可选补充说明）。
  Future<void> sendReport({
    required String type,
    required int reportableId,
    required int reasonIndex,
    String? comment,
  }) async {
    await _api.post('feedback/report/send', body: {
      'type': type,
      'reportable_id': reportableId,
      'reason_index': reasonIndex,
      if (comment != null && comment.trim().isNotEmpty)
        'comment': comment.trim(),
    });
  }

  // ===================== 评论 =====================

  /// 发表评论（可为回复，parentId 非空即回复）。
  /// 返回新评论与服务端最新评论总数（用于本地计数对账）。
  Future<({ColibriComment comment, int? commentsCount})> createComment({
    required int postId,
    required String content,
    int? parentId,
  }) async {
    final resp = await _api.post('timeline/post/comment/create', body: {
      'post_id': postId,
      'content': content,
      if (parentId != null && parentId > 0) 'parent_id': parentId,
    });
    final data = resp['data'];
    if (data is Map<String, dynamic> &&
        data['comment'] is Map<String, dynamic>) {
      return (
        comment:
            ColibriComment.fromJson(data['comment'] as Map<String, dynamic>),
        commentsCount: _parseCommentsCount(data),
      );
    }
    throw ColibriApiException('评论失败');
  }

  /// 删除评论。返回服务端最新评论总数（主评论删除时其全部回复已由数据库级联删除）。
  Future<int?> deleteComment(int commentId) async {
    final resp = await _api
        .delete('timeline/post/comment/delete', body: {'id': commentId});
    final data = resp['data'];
    return data is Map<String, dynamic> ? _parseCommentsCount(data) : null;
  }

  /// 解析响应 data.post.comments_count.raw（服务端历史字段，容错为 int）。
  int? _parseCommentsCount(Map<String, dynamic> data) {
    final post = data['post'];
    if (post is Map<String, dynamic>) {
      final count = post['comments_count'];
      if (count is Map<String, dynamic>) {
        return int.tryParse('${count['raw']}') ??
            int.tryParse('${count['formatted']}');
      }
      if (count is int) return count;
      return int.tryParse('$count');
    }
    return null;
  }

  /// 评论点赞（toggle）。
  Future<List<ColibriReaction>> toggleCommentReaction(int commentId,
      {String unifiedId = likeUnifiedId}) async {
    final resp = await _api.post('timeline/comment/reaction/add', body: {
      'comment_id': commentId,
      'unified_id': unifiedId,
    });
    final data = resp['data'];
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => ColibriReaction.fromJson(e))
        .toList();
  }

  // ===================== 发布 =====================

  /// 进度语义（重要）：
  /// 本地写入完成 ≠ 服务器已收到——TCP 内核发送缓冲（auto-tune 可达 MB 级）+ 连接复用
  /// 会让复用连接上的后续文件「瞬间写完」而真实传输还需数秒。
  /// 因此写入进度映射到 0~0.95，等 HTTP 响应到达（服务器确认收完全部字节）才回调 1.0。
  static double _mapWriteProgress(int sent, int total) {
    final raw = total > 0 ? sent / total : 1.0;
    return (raw * 0.95).clamp(0.0, 0.95);
  }

  int? _parseMediaId(Map<String, dynamic> resp) {
    final data = resp['data'];
    if (data is Map<String, dynamic>) {
      return data['id'] is int
          ? data['id'] as int
          : int.tryParse('${data['id']}');
    }
    return null;
  }

  /// 上传图片到草稿（image 字段）。[onProgress] 为 0~1（0.95=写入完成，1.0=服务器确认）。
  /// 返回 media id（后端响应 data.id），可用于发布前撤回（[deleteMedia]）。
  Future<int?> uploadImage(String path,
      {void Function(double progress)? onProgress}) async {
    final resp = await _api.postMultipart(
      'post/editor/media/image/upload',
      files: {'image': path},
      onSendProgress: (sent, total) =>
          onProgress?.call(_mapWriteProgress(sent, total)),
    );
    onProgress?.call(1.0); // 响应到达 = 服务器已收完
    return _parseMediaId(resp);
  }

  /// 上传视频到草稿（video 字段）。[onProgress] 语义同 [uploadImage]。返回 media id。
  Future<int?> uploadVideo(String path,
      {void Function(double progress)? onProgress}) async {
    final resp = await _api.postMultipart(
      'post/editor/media/video/upload',
      files: {'video': path},
      onSendProgress: (sent, total) =>
          onProgress?.call(_mapWriteProgress(sent, total)),
    );
    onProgress?.call(1.0);
    return _parseMediaId(resp);
  }

  /// 上传音频到草稿（audio 字段）。[onProgress] 语义同 [uploadImage]。返回 media id。
  Future<int?> uploadAudio(String path,
      {void Function(double progress)? onProgress}) async {
    final resp = await _api.postMultipart(
      'post/editor/media/audio/upload',
      files: {'audio': path},
      onSendProgress: (sent, total) =>
          onProgress?.call(_mapWriteProgress(sent, total)),
    );
    onProgress?.call(1.0);
    return _parseMediaId(resp);
  }

  /// 上传文档到草稿（document 字段）。[onProgress] 语义同 [uploadImage]。返回 media id。
  Future<int?> uploadDocument(String path,
      {void Function(double progress)? onProgress}) async {
    final resp = await _api.postMultipart(
      'post/editor/media/document/upload',
      files: {'document': path},
      onSendProgress: (sent, total) =>
          onProgress?.call(_mapWriteProgress(sent, total)),
    );
    onProgress?.call(1.0);
    return _parseMediaId(resp);
  }

  /// 删除草稿媒体（发布前撤回已上传的图片/视频等，传 upload 返回的 media id）。
  /// 后端行为：图片删文件+记录（草稿图片清零时连草稿帖一起删）；视频/音频/文档整草稿删。
  Future<void> deleteMedia(int mediaId) async {
    await _api.delete('post/editor/media/delete', body: {'id': mediaId});
  }

  /// 投票：投某选项（每个用户默认一票，重复投同一选项为取消）。返回最新投票数据。
  Future<ColibriPoll> votePoll(
      {required int pollId, required int choiceIndex}) async {
    final resp = await _api.post('timeline/post/poll/vote', body: {
      'poll_id': pollId,
      'choice_id': choiceIndex,
    });
    final data = resp['data'];
    if (data is Map<String, dynamic>) return ColibriPoll.fromJson(data);
    throw ColibriApiException('投票失败');
  }

  /// 发布帖子（草稿转正式帖）。
  ///
  /// 媒体上传由调用方先行完成（uploadImage/uploadVideo/...），本方法只负责 create：
  /// - [pollOptions] 非空时按「投票帖」发布（先 post/editor/poll/create，再带 poll_options create）。
  /// - 纯文本或媒体已预上传的帖子直接 post/editor/create。
  /// - [isSensitive]/[isAiGenerated] 对应网页端 marks 标记（敏感内容 / AI 生成）。
  Future<void> createPost({
    required String content,
    List<String>? pollOptions,
    bool isSensitive = false,
    bool isAiGenerated = false,
  }) async {
    final body = <String, dynamic>{
      'content': content,
      'marks': {
        'is_sensitive': isSensitive,
        'is_ai_generated': isAiGenerated,
      },
    };
    if (pollOptions != null && pollOptions.isNotEmpty) {
      await _api.post('post/editor/poll/create');
      body['poll_options'] =
          pollOptions.map((o) => {'choice_text': o}).toList();
    }
    await _api.post('post/editor/create', body: body);
  }
}

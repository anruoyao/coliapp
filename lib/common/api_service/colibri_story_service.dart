import 'package:untitled/common/api_service/colibri_api.dart';
import 'package:untitled/models/colibri_story_models.dart';

/// ColibriPlus 故事 API（/stories/* 与 /story/editor/*）。
class ColibriStoryService {
  static final shared = ColibriStoryService();

  ColibriApi get _api => ColibriApi.shared;

  /// 故事条（每个用户一个条目）。无故事时后端返回 404，这里当空列表处理。
  Future<List<ColibriStoryFeed>> fetchFeed() async {
    try {
      final resp = await _api.get('stories/feed');
      final data = resp['data'];
      if (data is! List) return [];
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => ColibriStoryFeed.fromJson(e))
          .toList();
    } on ColibriApiException catch (e) {
      if (e.statusCode == 404) return [];
      rethrow;
    }
  }

  /// 某个用户的故事（含其他用户的故事，用于连续查看）。
  Future<List<ColibriStory>> fetchStories(String storyUuid) async {
    final resp = await _api.get('stories/stories/$storyUuid');
    final data = resp['data'];
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => ColibriStory.fromJson(e))
        .toList();
  }

  /// 标记故事帧已看。
  Future<void> recordView(int frameId) async {
    await _api.post('stories/views/record', body: {'frame_id': frameId});
  }

  /// 删除故事帧（自己的）。
  Future<void> deleteStoryFrame(int frameId) async {
    await _api.delete('stories/delete', body: {'frame_id': frameId});
  }

  /// 发布图片故事：先上传媒体到草稿，再 create。
  Future<void> createStory(
      {required String imagePath, String content = ''}) async {
    await _api.postMultipart(
      'story/editor/media/upload',
      files: {'media_file': imagePath},
    );
    await _api.post('story/editor/create', body: {'content': content});
  }
}

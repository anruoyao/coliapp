import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// 全局媒体播放管理器：保证同一时刻全 App 仅一路媒体在播（音频/视频互斥）。
///
/// - 音频：控制器由本服务持有并共享，Feed 帖子卡片与帖子详情页复用同一实例，
///   从 Feed 打开详情后可无缝续播/暂停，不会出现两路同响。
/// - 视频：控制器由页面组件持有（随组件销毁释放），播放前需 [activateVideo]
///   登记，服务会自动暂停之前正在播放的音频与视频。
class ColibriMediaPlayback extends ChangeNotifier {
  ColibriMediaPlayback._();

  static final ColibriMediaPlayback shared = ColibriMediaPlayback._();

  VideoPlayerController? _audio;
  String? _audioUrl;
  VideoPlayerController? _activeVideo;
  bool _loading = false;

  /// 当前正在播放/已加载的音频地址。
  String? get audioUrl => _audioUrl;

  /// 当前音频控制器（仅当 [isActiveAudio] 时有效）。
  VideoPlayerController? get audioController => _audio;

  /// 该地址是否为当前活跃音频（已初始化或加载中）。
  bool isActiveAudio(String url) => _audioUrl == url && _audio != null;

  /// 该地址音频是否正在初始化。
  bool isLoadingAudio(String url) => _loading && _audioUrl == url;

  /// 切换音频播放：同地址 = 播放/暂停切换；不同地址 = 停掉旧的再播新的。
  Future<void> toggleAudio(String url) async {
    if (url.isEmpty) return;

    final current = _audio;
    if (_audioUrl == url && current != null) {
      if (current.value.isPlaying) {
        await current.pause();
      } else {
        if (current.value.isCompleted) await current.seekTo(Duration.zero);
        await current.play();
      }
      notifyListeners();
      return;
    }

    await _stopAudio();
    await _pauseActiveVideo();

    _audioUrl = url;
    _loading = true;
    notifyListeners();

    VideoPlayerController? c;
    try {
      c = VideoPlayerController.networkUrl(Uri.parse(url));
      _audio = c;
      c.addListener(_notify);
      await c.initialize();
      if (_audio != c) {
        // 加载期间被其他媒体抢占，弃置本地实例
        await c.dispose();
        return;
      }
      await c.play();
      _loading = false;
      notifyListeners();
    } catch (_) {
      _loading = false;
      if (_audio == c) {
        await _stopAudio();
      } else {
        await c?.dispose();
      }
      notifyListeners();
    }
  }

  /// 音频进度跳转（仅对该地址的活跃音频生效）。
  Future<void> seekAudio(String url, Duration position) async {
    if (_audioUrl == url && _audio != null) {
      await _audio!.seekTo(position);
      notifyListeners();
    }
  }

  /// 停止音频并释放控制器。
  Future<void> stopAudio() => _stopAudio();

  // ==================== 视频 ====================

  /// 视频请求播放：暂停当前音频与其他活跃视频，并登记为当前活跃视频。
  Future<void> activateVideo(VideoPlayerController controller) async {
    final old = _activeVideo;
    _activeVideo = controller;
    if (old != null && !identical(old, controller) && old.value.isPlaying) {
      try {
        await old.pause();
      } catch (_) {}
    }
    await _pauseAudio();
    notifyListeners();
  }

  /// 视频组件销毁时注销活跃登记（控制器由组件自行释放）。
  void deactivateVideo(VideoPlayerController controller) {
    if (identical(_activeVideo, controller)) {
      _activeVideo = null;
      notifyListeners();
    }
  }

  // ==================== 内部 ====================

  void _notify() => notifyListeners();

  Future<void> _stopAudio() async {
    final c = _audio;
    _audio = null;
    _audioUrl = null;
    _loading = false;
    if (c != null) {
      c.removeListener(_notify);
      await c.dispose();
    }
    notifyListeners();
  }

  Future<void> _pauseAudio() async {
    final c = _audio;
    if (c != null && c.value.isPlaying) {
      try {
        await c.pause();
      } catch (_) {}
      notifyListeners();
    }
  }

  Future<void> _pauseActiveVideo() async {
    final c = _activeVideo;
    if (c != null && c.value.isPlaying) {
      try {
        await c.pause();
      } catch (_) {}
      notifyListeners();
    }
  }
}

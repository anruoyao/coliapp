import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_timeline_service.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
import 'package:untitled/common/managers/colibri_media_playback.dart';
import 'package:untitled/common/managers/guest_session.dart';
import 'package:untitled/common/widgets/guest_auth_sheet.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/models/colibri_post_models.dart';
import 'package:untitled/utilities/const.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

// ===========================================================================
// 帖子针对不同媒体/投票类型的独立展示组件（对齐网页 Publication* 组件）。
// ===========================================================================

/// 视频帖：帖内直接播放——点击画面播放/暂停，底部控制条含进度条与全屏按钮；
/// 全屏按视频宽高自适应横竖屏。对齐网页 `PublicationVideo.vue`。
class ColibriPostVideo extends StatefulWidget {
  final ColibriPostMedia media;
  final bool resizeThumbnailToDisplayBounds;

  const ColibriPostVideo({
    super.key,
    required this.media,
    this.resizeThumbnailToDisplayBounds = false,
  });

  @override
  State<ColibriPostVideo> createState() => _ColibriPostVideoState();
}

class _ColibriPostVideoState extends State<ColibriPostVideo> {
  VideoPlayerController? _controller;
  bool _loading = false;
  bool _failed = false;
  bool _inFullscreen = false;
  double? _dragMs; // 拖动进度条时的本地值（毫秒）

  bool get _hasThumb =>
      widget.media.thumbnailUrl != null &&
      widget.media.thumbnailUrl!.isNotEmpty;

  @override
  void dispose() {
    final c = _controller;
    if (c != null) {
      ColibriMediaPlayback.shared.deactivateVideo(c);
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _start() async {
    if (_controller != null || _loading || widget.media.sourceUrl.isEmpty)
      return;
    setState(() {
      _loading = true;
      _failed = false;
    });

    VideoPlayerController? c;
    try {
      c = VideoPlayerController.networkUrl(Uri.parse(widget.media.sourceUrl));
      _controller = c;
      await c.initialize();
      if (_controller != c) {
        await c.dispose();
        return;
      }
      await ColibriMediaPlayback.shared.activateVideo(c);
      await c.play();
    } catch (_) {
      if (identical(_controller, c)) {
        _controller = null;
        _failed = true;
      }
      await c?.dispose();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggle() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      if (c.value.isCompleted) await c.seekTo(Duration.zero);
      await ColibriMediaPlayback.shared.activateVideo(c);
      await c.play();
    }
    if (mounted) setState(() {});
  }

  /// 进入全屏：横版视频强制横屏，竖版视频保持竖屏；与帖内共享控制器续播。
  Future<void> _openFullscreen() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    setState(() => _inFullscreen = true);
    await Get.to(() => ColibriFullScreenVideo(controller: c), opaque: false);
    if (mounted) setState(() => _inFullscreen = false);
  }

  /// 视频滚出屏幕时自动暂停（避免看不见画面仍在出声）。
  void _onVisibilityChanged(VisibilityInfo info) {
    if (info.visibleFraction < 0.25 && !_inFullscreen) {
      _controller?.pause();
    }
  }

  String _fmt(num ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    return '${m.toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.media.isProcessing) {
      return Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: cLightBg,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: cPrimary, strokeWidth: 2),
            SizedBox(height: 10),
            Text('视频处理中，请稍后刷新',
                style: TextStyle(fontSize: 13, color: cLightText)),
          ],
        ),
      );
    }

    final c = _controller;
    final initialized = c != null && c.value.isInitialized;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: VisibilityDetector(
        key: Key('colibri_post_video_${widget.media.id}'),
        onVisibilityChanged: _onVisibilityChanged,
        child: Stack(
          children: [
            // 画面层：未播放显示封面，播放中按视频实际宽高自适应
            AspectRatio(
              aspectRatio: initialized && c.value.aspectRatio > 0
                  ? c.value.aspectRatio
                  : 16 / 9,
              child: initialized
                  ? VideoPlayer(c)
                  : (_hasThumb
                      ? MyCachedImage(
                          imageUrl: widget.media.thumbnailUrl!,
                          width: double.infinity,
                          height: double.infinity,
                          cornerRadius: 14,
                          resizeToDisplayBounds:
                              widget.resizeThumbnailToDisplayBounds)
                      : Container(
                          color: cBlack,
                          width: double.infinity,
                          height: double.infinity)),
            ),
            if (!initialized) _buildPosterOverlay(),
            if (!initialized && widget.media.durationText.isNotEmpty)
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(widget.media.durationText,
                      style:
                          const TextStyle(fontSize: 11, color: Colors.white)),
                ),
              ),
            if (initialized) ..._buildPlayerOverlay(c),
          ],
        ),
      ),
    );
  }

  /// 未播放时的封面 + 播放按钮遮罩（整块区域点击播放）。
  Widget _buildPosterOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _loading ? null : _start,
        child: ColoredBox(
          color: Colors.black.withOpacity(0.15),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                      color: Colors.black45, shape: BoxShape.circle),
                  child: _loading
                      ? const SizedBox(
                          width: 34,
                          height: 34,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Icon(
                          _failed
                              ? Icons.refresh_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 34),
                ),
                if (_failed) ...[
                  const SizedBox(height: 8),
                  const Text('播放失败，点击重试',
                      style: TextStyle(fontSize: 12, color: Colors.white)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 播放中的控制层：点击切换播放/暂停 + 底部进度控制条。
  List<Widget> _buildPlayerOverlay(VideoPlayerController c) {
    return [
      // 点击画面切换播放/暂停；暂停时显示大播放键
      Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggle,
          child: ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: c,
            builder: (context, value, _) => Center(
              child: value.isPlaying
                  ? const SizedBox.shrink()
                  : Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                          color: Colors.black45, shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 38),
                    ),
            ),
          ),
        ),
      ),
      // 底部控制条：播放/暂停 + 时间 + 进度条 + 全屏
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: _buildBottomBar(c),
      ),
    ];
  }

  Widget _buildBottomBar(VideoPlayerController c) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: c,
      builder: (context, value, _) {
        final pos = value.position.inMilliseconds;
        final dur = value.duration.inMilliseconds;
        return Container(
          padding: const EdgeInsets.only(left: 8, right: 4, top: 14, bottom: 4),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black54],
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggle,
                child: Icon(
                    value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 22),
              ),
              const SizedBox(width: 4),
              Text(_fmt(_dragMs ?? pos),
                  style: const TextStyle(fontSize: 11, color: Colors.white)),
              Expanded(
                child: SliderTheme(
                  data: const SliderThemeData(
                    trackHeight: 2,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 10),
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value:
                        dur > 0 ? (_dragMs ?? pos).clamp(0, dur).toDouble() : 0,
                    max: dur > 0 ? dur.toDouble() : 1.0,
                    onChanged:
                        dur > 0 ? (v) => setState(() => _dragMs = v) : null,
                    onChangeEnd: (v) {
                      c.seekTo(Duration(milliseconds: v.round()));
                      setState(() => _dragMs = null);
                    },
                  ),
                ),
              ),
              Text(dur > 0 ? _fmt(dur) : widget.media.durationText,
                  style: const TextStyle(fontSize: 11, color: Colors.white)),
              const SizedBox(width: 4),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openFullscreen,
                child: const Icon(Icons.fullscreen_rounded,
                    color: Colors.white, size: 24),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 音频帖：播放/暂停 + 波形进度 + 可拖动进度条（对齐网页 `AudioPlayer.vue`）。
/// 播放状态由 [ColibriMediaPlayback] 全局管理：同一时刻仅一路音频，
/// Feed 与帖子详情共享同一控制器，跨页面续播不会出现两路同响。
class ColibriPostAudio extends StatefulWidget {
  final ColibriPostMedia media;
  final String label;

  const ColibriPostAudio({super.key, required this.media, this.label = ''});

  @override
  State<ColibriPostAudio> createState() => _ColibriPostAudioState();
}

class _ColibriPostAudioState extends State<ColibriPostAudio> {
  double? _dragMs; // 拖动进度条时的本地值（毫秒）

  // 以媒体 id 为种子生成固定波形：同一音频在 Feed/详情中展示一致
  late final List<double> _bars = () {
    final rand = Random(widget.media.id);
    return List.generate(40, (i) {
      final base = rand.nextDouble() * 0.7 + 0.15;
      final edge = 1 - (i - 20).abs() / 20 * 0.3;
      return (base * edge).clamp(0.12, 1.0);
    });
  }();

  String _fmt(num ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    return '${m.toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ColibriMediaPlayback.shared,
      builder: (context, _) {
        final service = ColibriMediaPlayback.shared;
        final url = widget.media.sourceUrl;
        final c = service.isActiveAudio(url) ? service.audioController : null;
        final initialized = c != null && c.value.isInitialized;
        final loading = service.isLoadingAudio(url);
        final playing = initialized && c.value.isPlaying;

        final posMs = initialized ? c.value.position.inMilliseconds : 0;
        final durMs = initialized ? c.value.duration.inMilliseconds : 0;
        final progress = durMs > 0 ? (posMs / durMs).clamp(0.0, 1.0) : 0.0;
        final curText = _fmt(_dragMs ?? posMs);
        final totalText = durMs > 0 ? _fmt(durMs) : widget.media.durationText;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cLightBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              // 播放/暂停按钮
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: url.isEmpty ? null : () => service.toggleAudio(url),
                child: loading && !initialized
                    ? const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: cPrimary))
                    : Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                            color: cPrimary, shape: BoxShape.circle),
                        child: Icon(
                            playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 22),
                      ),
              ),
              const SizedBox(width: 12),
              // 波形进度 + 进度条
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 波形：已播部分高亮，点击跳转
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: initialized && durMs > 0
                              ? (d) => service.seekAudio(
                                    url,
                                    Duration(
                                        milliseconds: (d.localPosition.dx /
                                                constraints.maxWidth *
                                                durMs)
                                            .round()),
                                  )
                              : null,
                          child: SizedBox(
                            height: 24,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: List.generate(_bars.length, (i) {
                                final played =
                                    (i + 0.5) / _bars.length <= progress;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 2),
                                  child: Container(
                                    width: 2,
                                    height: 24 * _bars[i],
                                    decoration: BoxDecoration(
                                      color: played
                                          ? cPrimary
                                          : cLightText.withOpacity(0.35),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 2),
                    // 进度条：当前时间 + 滑块 + 总时长
                    Row(
                      children: [
                        Text(curText,
                            style: const TextStyle(
                                fontSize: 11, color: cLightText)),
                        Expanded(
                          child: SliderTheme(
                            data: const SliderThemeData(
                              trackHeight: 2,
                              thumbShape:
                                  RoundSliderThumbShape(enabledThumbRadius: 5),
                              overlayShape:
                                  RoundSliderOverlayShape(overlayRadius: 10),
                              activeTrackColor: cPrimary,
                              inactiveTrackColor: cLightText,
                              thumbColor: cPrimary,
                            ),
                            child: Slider(
                              value: durMs > 0
                                  ? (_dragMs ?? posMs)
                                      .clamp(0, durMs)
                                      .toDouble()
                                  : 0,
                              max: durMs > 0 ? durMs.toDouble() : 1.0,
                              onChanged: initialized && durMs > 0
                                  ? (v) => setState(() => _dragMs = v)
                                  : null,
                              onChangeEnd: (v) {
                                service.seekAudio(
                                    url, Duration(milliseconds: v.round()));
                                setState(() => _dragMs = null);
                              },
                            ),
                          ),
                        ),
                        Text(totalText,
                            style: const TextStyle(
                                fontSize: 11, color: cLightText)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 文档帖：文件图标 + 文件名 + 大小·扩展名 + 下载（对齐网页 `PublicationDocument.vue`）。
class ColibriPostDocument extends StatelessWidget {
  final ColibriPostMedia media;

  const ColibriPostDocument({super.key, required this.media});

  Future<void> _download() async {
    final url = media.sourceUrl;
    if (url.isEmpty) return;
    try {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.platformDefault,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final ext = (media.extension ?? '').toUpperCase();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: cLightBg),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // 文件格式图标
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: cPrimary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8)),
            child: Text(ext.isEmpty ? '?' : ext,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: cPrimary)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  media.fileName.isNotEmpty ? media.fileName : '附件',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cMainText),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (media.sizeText.isNotEmpty) media.sizeText,
                    if (ext.isNotEmpty) ext.toLowerCase(),
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: cLightText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 下载按钮
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _download,
            child: Container(
              width: 34,
              height: 34,
              decoration:
                  const BoxDecoration(color: cLightBg, shape: BoxShape.circle),
              child: const Icon(Icons.download_rounded,
                  color: cLightText, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

/// 投票帖：公开投票 + 各选项进度条 + 投票操作 + 人数/状态 + 投票用户头像
/// （对齐网页 `PublicationPoll.vue` + `PollChoiceItem.vue`）。
class ColibriPostPoll extends StatelessWidget {
  final ColibriPoll poll;
  final ValueChanged<ColibriPoll> onVote; // 投票成功后回传最新投票数据

  const ColibriPostPoll({super.key, required this.poll, required this.onVote});

  Future<void> _vote(int choiceIndex) async {
    // 访客：只读，点击投票项直接弹登录引导，不发请求
    if (GuestSession.i.isGuest) {
      AuthGate.requireLogin(() {}, feature: '投票');
      return;
    }
    // 已投票或已过期则不可再投（对齐网页）
    if (poll.hasVoted || poll.isExpired) return;
    try {
      final updated = await ColibriTimelineService.shared.votePoll(
        pollId: poll.id,
        choiceIndex: choiceIndex,
      );
      onVote(updated);
    } catch (e) {
      showColibriToast('投票失败',
          message: e.toString(),
          backgroundColor: cRed,
          colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 头部：公开投票
        Row(
          children: [
            const Icon(Icons.public_rounded, size: 16, color: cLightText),
            const SizedBox(width: 4),
            const Text('公开投票',
                style: TextStyle(fontSize: 13, color: cLightText)),
          ],
        ),
        const SizedBox(height: 8),
        // 选项
        ...poll.choices.asMap().entries.map((e) {
          final index = e.key;
          final choice = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _PollChoiceTile(
              choice: choice,
              interactive: !poll.hasVoted && !poll.isExpired,
              onTap: () => _vote(index),
            ),
          );
        }),
        // 底部：票数 - 状态
        Center(
          child: Text(
            '共 ${poll.totalVotes} 票 · ${poll.isExpired ? '已结束' : '进行中'}',
            style: const TextStyle(fontSize: 12, color: cLightText),
          ),
        ),
        // 投票用户头像
        if (poll.voterUsers.isNotEmpty) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              height: 22,
              child: ListView(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                children: poll.voterUsers.map((v) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: CircleAvatar(
                      radius: 11,
                      backgroundColor: cLightBg,
                      backgroundImage:
                          v.avatarUrl != null && v.avatarUrl!.isNotEmpty
                              ? NetworkImage(v.avatarUrl!)
                              : null,
                      child: v.avatarUrl == null || v.avatarUrl!.isEmpty
                          ? const Icon(Icons.person_rounded,
                              color: cLightIcon, size: 12)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// 单个投票选项（进度条 + 选中对勾 + 文字 + 百分比）。
class _PollChoiceTile extends StatelessWidget {
  final ColibriPollChoice choice;
  final bool interactive;
  final VoidCallback onTap;

  const _PollChoiceTile({
    required this.choice,
    required this.interactive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = interactive ? cMainText : cLightText;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: interactive ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          border: Border.all(color: cLightBg),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // 进度条背景
            if (choice.percentage > 0)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: double.infinity,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (choice.percentage / 100).clamp(0.0, 1.0),
                  child: Container(color: cPrimary.withOpacity(0.12)),
                ),
              ),
            // 内容
            Row(
              children: [
                Icon(
                  choice.hasVotedChoice
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: choice.hasVotedChoice ? cGreen : cLightText,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    choice.choiceText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor),
                  ),
                ),
                if (choice.percentage > 0)
                  Text(
                    '${choice.percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: interactive ? textColor : cPrimary),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 全屏视频播放页：与帖内播放共享同一控制器（续播不断点）；
/// 横版视频自动转横屏、竖版视频保持竖屏，沉浸式隐藏系统栏；
/// 退出时恢复竖屏锁定与系统 UI。
class ColibriFullScreenVideo extends StatefulWidget {
  final VideoPlayerController controller;

  const ColibriFullScreenVideo({super.key, required this.controller});

  @override
  State<ColibriFullScreenVideo> createState() => _ColibriFullScreenVideoState();
}

class _ColibriFullScreenVideoState extends State<ColibriFullScreenVideo> {
  double? _dragMs; // 拖动进度条时的本地值（毫秒）

  @override
  void initState() {
    super.initState();
    _enterImmersive();
  }

  /// 横版视频（宽>高）强制横屏，竖版视频保持竖屏；隐藏系统栏。
  Future<void> _enterImmersive() async {
    final ratio = widget.controller.value.aspectRatio;
    if (ratio > 1.0) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _exitImmersive() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
  }

  @override
  void dispose() {
    _exitImmersive();
    super.dispose();
  }

  Future<void> _toggle() async {
    final c = widget.controller;
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      if (c.value.isCompleted) await c.seekTo(Duration.zero);
      await c.play();
    }
  }

  String _fmt(num ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    return '${m.toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: c,
        builder: (context, value, _) {
          final pos = value.position.inMilliseconds;
          final dur = value.duration.inMilliseconds;
          return Stack(
            children: [
              // 画面
              Center(
                child: AspectRatio(
                  aspectRatio:
                      value.aspectRatio > 0 ? value.aspectRatio : 16 / 9,
                  child: VideoPlayer(c),
                ),
              ),
              // 点击切换播放/暂停；暂停时显示大播放键
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggle,
                  child: Center(
                    child: value.isPlaying
                        ? const SizedBox.shrink()
                        : Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                                color: Colors.black45, shape: BoxShape.circle),
                            child: const Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 44),
                          ),
                  ),
                ),
              ),
              // 顶部返回
              Positioned(
                top: 8,
                left: 4,
                child: SafeArea(
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                ),
              ),
              // 底部控制条
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _toggle,
                          child: Icon(
                              value.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 28),
                        ),
                        const SizedBox(width: 8),
                        Text(_fmt(_dragMs ?? pos),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12)),
                        Expanded(
                          child: SliderTheme(
                            data: const SliderThemeData(
                              trackHeight: 2,
                              thumbShape:
                                  RoundSliderThumbShape(enabledThumbRadius: 5),
                              overlayShape:
                                  RoundSliderOverlayShape(overlayRadius: 10),
                              activeTrackColor: Colors.white,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: Colors.white,
                            ),
                            child: Slider(
                              value: dur > 0
                                  ? (_dragMs ?? pos).clamp(0, dur).toDouble()
                                  : 0,
                              max: dur > 0 ? dur.toDouble() : 1.0,
                              onChanged: dur > 0
                                  ? (v) => setState(() => _dragMs = v)
                                  : null,
                              onChangeEnd: (v) {
                                c.seekTo(Duration(milliseconds: v.round()));
                                setState(() => _dragMs = null);
                              },
                            ),
                          ),
                        ),
                        Text(dur > 0 ? _fmt(dur) : '',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12)),
                        const SizedBox(width: 8),
                        // 退出全屏（返回帖内继续播放）
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Get.back(),
                          child: const Icon(Icons.fullscreen_exit_rounded,
                              color: Colors.white, size: 26),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

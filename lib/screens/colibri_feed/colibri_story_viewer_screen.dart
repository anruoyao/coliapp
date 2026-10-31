import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:untitled/common/api_service/colibri_messenger_service.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
import 'package:untitled/common/api_service/colibri_social_service.dart';
import 'package:untitled/common/api_service/colibri_story_service.dart';
import 'package:untitled/common/widgets/colibri_ui.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/models/colibri_story_models.dart';
import 'package:untitled/screens/colibri_chat/chat_detail_screen.dart';
import 'package:untitled/utilities/const.dart';

/// 故事查看器：全屏逐帧查看所有用户的故事。
class StoryViewerScreen extends StatefulWidget {
  final List<ColibriStory> stories;
  final int initialIndex;

  const StoryViewerScreen(
      {super.key, required this.stories, this.initialIndex = 0});

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  late int _storyIndex;
  int _frameIndex = 0;
  Timer? _timer;
  double _progress = 0;
  bool _paused = false;
  bool _contentExpanded = false;

  ColibriStory get _story => widget.stories[_storyIndex];
  ColibriStoryFrame get _frame => _story.frames[_frameIndex];

  @override
  void initState() {
    super.initState();
    _storyIndex = widget.initialIndex;
    _startFrame();
  }

  void _startFrame() {
    _timer?.cancel();
    _progress = 0;
    _contentExpanded = false;
    // 标记已看
    ColibriStoryService.shared.recordView(_frame.id);
    final duration = _frame.durationSeconds <= 0 ? 5 : _frame.durationSeconds;
    final tick = 50; // ms
    final totalTicks = (duration * 1000 / tick).round();
    var ticks = 0;
    _timer = Timer.periodic(Duration(milliseconds: tick), (_) {
      if (_paused) return;
      ticks++;
      _progress = ticks / totalTicks;
      if (mounted) setState(() {});
      if (ticks >= totalTicks) {
        _nextFrame();
      }
    });
  }

  void _nextFrame() {
    if (_frameIndex + 1 < _story.frames.length) {
      setState(() => _frameIndex++);
      _startFrame();
    } else if (_storyIndex + 1 < widget.stories.length) {
      setState(() {
        _storyIndex++;
        _frameIndex = 0;
      });
      _startFrame();
    } else {
      Get.back();
    }
  }

  void _prevFrame() {
    if (_frameIndex > 0) {
      setState(() => _frameIndex--);
      _startFrame();
    } else if (_storyIndex > 0) {
      setState(() {
        _storyIndex--;
        _frameIndex = widget.stories[_storyIndex].frames.length - 1;
      });
      _startFrame();
    }
  }

  Future<void> _deleteCurrent() async {
    if (!_story.isOwner) return;
    final confirmed = await showColibriConfirmDialog(
      context,
      icon: Icons.auto_delete_outlined,
      title: '删除这条故事？',
      message: '故事发布 24 小时后自动消失，删除后立即不可见且无法恢复',
      confirmText: '删除',
      onConfirm: () async {
        try {
          await ColibriStoryService.shared.deleteStoryFrame(_frame.id);
          return true;
        } catch (_) {
          showColibriToast('删除失败',
              message: '请稍后重试', backgroundColor: cRed, colorText: Colors.white);
          return false;
        }
      },
    );
    if (!confirmed || !mounted) return;
    setState(() => _story.frames.removeAt(_frameIndex));
    if (_story.frames.isEmpty) {
      widget.stories.removeAt(_storyIndex);
      if (widget.stories.isEmpty) {
        Get.back();
        return;
      }
      _frameIndex = 0;
    } else if (_frameIndex >= _story.frames.length) {
      _frameIndex = _story.frames.length - 1;
    }
    _startFrame();
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
  }

  /// 帧文字描述（对齐网页 StoryContent）：默认 2 行，点击展开全文，展开时暂停播放。
  Widget _buildContentOverlay() {
    return GestureDetector(
      onTap: () {
        _togglePause();
        setState(() => _contentExpanded = !_contentExpanded);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Text(
          _frame.content,
          maxLines: _contentExpanded ? null : 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: Colors.white, fontSize: 14.5, height: 1.45),
        ),
      ),
    );
  }

  /// 顶部「更多」菜单：对齐网页 StoryHeader 的 ActionSheet。
  /// 删除(仅本人) / 隐藏(他人) / 举报(他人)，其中隐藏与举报网页端为 $comingSoon 占位。
  void _showMoreMenu() {
    _togglePause();
    showColibriBottomSheet<void>(
      Builder(
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_story.canDelete)
                _MenuTile(
                  icon: Icons.delete_outline_rounded,
                  label: '删除故事',
                  danger: true,
                  onTap: () {
                    Get.back();
                    _deleteCurrent();
                  },
                ),
              if (_story.canHide)
                _MenuTile(
                  icon: Icons.visibility_off_outlined,
                  label: '隐藏 ${_story.userName} 的故事',
                  onTap: () {
                    Get.back();
                    _comingSoon();
                  },
                ),
              if (_story.canReport)
                _MenuTile(
                  icon: Icons.report_gmailerrorred_rounded,
                  label: '举报故事',
                  danger: true,
                  onTap: () {
                    Get.back();
                    _comingSoon();
                  },
                ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
      context: context,
      backgroundColor: cWhite,
    );
  }

  void _comingSoon() {
    if (!mounted) return;
    showColibriToast('该功能即将推出', context: context);
  }

  /// 回复故事：对齐网页 StoryReply，创建/打开与作者的聊天并跳转。
  /// 作者「谁能回复我的故事」设置不允许时给出提示。
  Future<void> _replyToStory() async {
    try {
      // 拉取作者资料，检查 can_story_reply（服务端按隐私设置计算）
      final author =
          await ColibriSocialService.shared.fetchProfile(_story.userName);
      if (!mounted) return;
      if (!author.canStoryReply) {
        showColibriToast('对方已限制谁能回复其故事',
            context: context, status: ColibriToastStatus.error);
        return;
      }
      final chatId =
          await ColibriMessengerService.shared.createChat(_story.userId);
      if (!mounted) return;
      Get.to(
          () => ChatDetailScreen(
                chatId: chatId,
                title: _story.userName,
                avatarUrl: _story.avatarUrl,
                isGroup: false,
              ),
          opaque: false);
    } catch (_) {
      if (!mounted) return;
      _comingSoon();
    }
  }

  /// 分享故事：对齐网页 StoryShare（分享故事链接）。
  Future<void> _shareStory() async {
    final link = _story.url.isNotEmpty
        ? _story.url
        : 'https://mariawk.cn/stories/${_story.storyUuid}';
    await SharePlus.instance
        .share(ShareParams(text: link, subject: _story.userName));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _frame.media?.sourceUrl;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;
          // 左侧 1/3 上一帧，右侧 2/3 下一帧
          if (details.globalPosition.dx < width / 3) {
            _prevFrame();
          } else {
            _nextFrame();
          }
        },
        onLongPressStart: (_) => setState(() => _paused = true),
        onLongPressEnd: (_) => setState(() => _paused = false),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 内容
            if (imageUrl != null && imageUrl.isNotEmpty)
              Center(
                child: MyCachedImage(
                    imageUrl: imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    cornerRadius: 0),
              )
            else
              Center(
                child: Text(_frame.content,
                    style: const TextStyle(color: Colors.white, fontSize: 18)),
              ),
            // 半透明遮罩（保证控件可见）
            const DecoratedBox(
              decoration: BoxDecoration(color: Colors.black26),
            ),
            // 顶部进度条
            SafeArea(
              child: Column(
                children: [
                  _ProgressBar(
                      story: _story,
                      frameIndex: _frameIndex,
                      progress: _progress),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white),
                        onPressed: () => Get.back(),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                            _paused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            color: Colors.white),
                        onPressed: _togglePause,
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_horiz_rounded,
                            color: Colors.white),
                        onPressed: _showMoreMenu,
                      ),
                    ],
                  ),
                  const Spacer(),
                  // 底部：文字描述（对齐网页 StoryContent，点击展开）+ 回复/分享 + 用户信息
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_frame.content.isNotEmpty) ...[
                          _buildContentOverlay(),
                          const SizedBox(height: 12),
                        ],
                        if (!_story.isOwner) ...[
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: _replyToStory,
                                  borderRadius: BorderRadius.circular(24),
                                  child: Container(
                                    height: 36,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    alignment: Alignment.centerLeft,
                                    decoration: BoxDecoration(
                                      color: Colors.white12,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: Colors.white54),
                                    ),
                                    child: Text(
                                      '回复 ${_story.userName}',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: const Icon(Icons.share_outlined,
                                    color: Colors.white),
                                onPressed: _shareStory,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.white24,
                              backgroundImage: _story.avatarUrl != null
                                  ? NetworkImage(_story.avatarUrl!)
                                  : null,
                              child: _story.avatarUrl == null
                                  ? const Icon(Icons.person_rounded,
                                      color: Colors.white, size: 16)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(_story.userName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Text(_frame.timeAgo,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 顶部故事帧进度条（当前帧动画进度 + 已看分段）。
class _ProgressBar extends StatelessWidget {
  final ColibriStory story;
  final int frameIndex;
  final double progress;

  const _ProgressBar(
      {required this.story, required this.frameIndex, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(story.frames.length, (i) {
        return Expanded(
          child: Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
            child: i < frameIndex
                ? FractionallySizedBox(
                    widthFactor: 1, child: Container(color: Colors.white))
                : i == frameIndex
                    ? FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(color: Colors.white))
                    : null,
          ),
        );
      }),
    );
  }
}

/// 故事「更多」菜单项。
class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    this.danger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 22, color: danger ? cRed : cMainText),
            const SizedBox(width: 12),
            Text(label,
                style:
                    TextStyle(fontSize: 15, color: danger ? cRed : cMainText)),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:share_plus/share_plus.dart';
import 'package:untitled/common/api_service/colibri_api.dart';
import 'package:untitled/common/api_service/colibri_timeline_service.dart';
import 'package:untitled/common/managers/bookmark_store.dart';
import 'package:untitled/common/managers/haptic_manager.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/allLanguages.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
import 'package:untitled/common/widgets/colibri_markdown_text.dart';
import 'package:untitled/common/widgets/colibri_sensitive_media.dart';
import 'package:untitled/common/widgets/colibri_ui.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'package:untitled/common/widgets/emoji_reaction_picker.dart';
import 'package:untitled/common/widgets/guest_auth_sheet.dart';
import 'package:untitled/common/managers/guest_session.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/colibri_post_models.dart';
import 'package:untitled/screens/colibri_feed/colibri_post_detail_screen.dart';
import 'package:untitled/screens/colibri_feed/colibri_post_media.dart';
import 'package:untitled/screens/colibri_feed/colibri_photo_viewer_screen.dart';
import 'package:untitled/screens/colibri_social/colibri_profile_screen.dart';
import 'package:untitled/screens/profile_screen/full_image_screen.dart';
import 'package:untitled/utilities/const.dart';

/// 帖子卡片（Feed 列表与帖子详情通用）。
class ColibriPostCard extends StatefulWidget {
  final ColibriPost post;
  final VoidCallback? onTap;
  final VoidCallback? onChanged; // 帖子状态变化（删除等）后交由父级刷新
  final ValueChanged<bool>? onBookmarked; // 收藏状态切换成功后回调（true=已收藏）
  final bool resizeMediaToDisplayBounds;
  @visibleForTesting
  final Future<TranslationResult> Function(int postId, String target)?
      translatePost;

  const ColibriPostCard(
      {super.key,
      required this.post,
      this.onTap,
      this.onChanged,
      this.onBookmarked,
      this.resizeMediaToDisplayBounds = false,
      this.translatePost});

  @override
  State<ColibriPostCard> createState() => _ColibriPostCardState();
}

class _ColibriPostCardState extends State<ColibriPostCard> {
  late ColibriPost _post;
  bool _liked = false;
  bool _deleting = false;
  bool _translating = false;
  bool _showTranslation = false;
  String? _translatedText;
  String? _sourceLanguage;
  String? _target;
  int _translationRequest = 0;

  String get _currentTarget => ColibriTimelineService.translationTarget(
        Get.locale?.languageCode ??
            SessionManager.shared.getLang().language.languageCode,
      );

  void _resetTranslation() {
    _translationRequest++;
    _translating = false;
    _showTranslation = false;
    _translatedText = null;
    _sourceLanguage = null;
    _target = _currentTarget;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_target != _currentTarget) _resetTranslation();
  }

  Future<void> _toggleTranslation() async {
    final targetNow = _currentTarget;
    if (_target != targetNow) _resetTranslation();
    if (_translating) return;
    if (GuestSession.i.isGuest) {
      AuthGate.requireLogin(() {}, feature: LKeys.translate.tr);
      return;
    }
    if (_translatedText != null) {
      setState(() => _showTranslation = !_showTranslation);
      return;
    }
    final request = ++_translationRequest;
    final id = _post.id;
    final content = _post.content;
    final target = _currentTarget;
    bool isCurrent() =>
        mounted &&
        request == _translationRequest &&
        id == _post.id &&
        content == _post.content &&
        target == _currentTarget;
    setState(() => _translating = true);
    try {
      final result = widget.translatePost != null
          ? await widget.translatePost!(id, target)
          : await ColibriTimelineService.shared
              .translatePost(postId: id, target: target);
      if (!isCurrent()) return;
      setState(() {
        _translatedText = result.translatedText;
        _sourceLanguage = result.sourceLanguage;
        _showTranslation = true;
      });
    } catch (e) {
      if (isCurrent()) {
        showColibriToast(LKeys.translationFailed.tr,
            message: e.toString(),
            backgroundColor: cRed,
            colorText: Colors.white);
      }
    } finally {
      if (isCurrent()) setState(() => _translating = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _liked = _post.liked;
  }

  /// 防御性同步：父级列表数据刷新（同一位置 widget 换了 post）时，
  /// State 内的内容副本必须跟随，否则会画旧帖（列表同时用 ValueKey 双保险）。
  @override
  void didUpdateWidget(covariant ColibriPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_post.id != widget.post.id || _post.content != widget.post.content) {
      _resetTranslation();
      _post = widget.post;
      _liked = _post.liked;
    }
  }

  Future<void> _toggleLike(
      [String unifiedId = ColibriTimelineService.likeUnifiedId]) async {
    // 访客：不发请求，弹登录引导
    if (GuestSession.i.isGuest) {
      AuthGate.requireLogin(() {}, feature: '点赞和表情反应');
      return;
    }
    try {
      final reactions = await ColibriTimelineService.shared
          .togglePostReaction(_post.id, unifiedId: unifiedId);
      setState(() {
        _post = _post.copyWith(reactions: reactions);
        _liked = _post.liked;
      });
      HapticManager.shared.light();
    } catch (_) {}
  }

  /// 投票成功后更新帖子内嵌的投票数据。
  void _handlePollVote(ColibriPoll newPoll) {
    if (GuestSession.i.isGuest) {
      AuthGate.requireLogin(() {}, feature: '投票');
      return;
    }
    setState(() => _post = _post.copyWith(poll: newPoll));
    HapticManager.shared.medium();
  }

  Future<void> _toggleBookmark() async {
    if (GuestSession.i.isGuest) {
      AuthGate.requireLogin(() {}, feature: '收藏');
      return;
    }
    final added = !BookmarkStore.i.isBookmarked(_post.id);
    try {
      // 全局 Store：乐观更新 ids/posts（所有页面卡片即时响应）+ 服务端确认 + 失败回滚
      final result = await BookmarkStore.i.toggle(_post);
      if (!mounted) return;
      // 反馈提示：底部中央弹出「已添加到收藏 / 已取消收藏」（带动画，自动消失）
      showColibriBookmarkToast(context, bookmarked: result);
      HapticManager.shared.selection();
      widget.onBookmarked?.call(result);
    } catch (e) {
      if (mounted) {
        showColibriToast(added ? '收藏失败' : '取消收藏失败',
            message: e.toString(),
            backgroundColor: cRed,
            colorText: Colors.white);
      }
    }
  }

  Future<void> _delete() async {
    if (_deleting) return;
    final confirmed = await showColibriConfirmDialog(
      context,
      icon: Icons.delete_outline_rounded,
      title: '删除这条帖子？',
      message: '帖子及其评论、点赞将被永久删除，无法恢复',
      confirmText: '删除',
      onConfirm: () async {
        setState(() => _deleting = true);
        try {
          await ColibriTimelineService.shared.deletePost(_post.id);
          return true;
        } catch (e) {
          showColibriToast('删除失败',
              message: e.toString(),
              backgroundColor: cRed,
              colorText: Colors.white);
          return false;
        } finally {
          _deleting = false;
        }
      },
    );
    if (!confirmed || !mounted) return;
    widget.onChanged?.call();
    if (Navigator.of(context).canPop()) Get.back(); // 详情页删除后返回；列表由 onChanged 刷新
    showColibriToast('已删除',
        message: '', backgroundColor: cGreen, colorText: Colors.white);
  }

  String get _postLink => 'https://mariawk.cn/publication/${_post.hashId}';

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _postLink));
    if (mounted) {
      showColibriToast('已复制链接',
          message: '', backgroundColor: cGreen, colorText: Colors.white);
    }
  }

  Future<void> _copyContent() async {
    await Clipboard.setData(ClipboardData(text: _post.content));
    if (mounted) {
      showColibriToast('已复制文本',
          message: '', backgroundColor: cGreen, colorText: Colors.white);
    }
  }

  Future<void> _share() async {
    try {
      await SharePlus.instance
          .share(ShareParams(text: _postLink, subject: _post.authorName));
    } catch (_) {}
  }

  Future<void> _report() async {
    if (!mounted) return;
    await showColibriBottomSheet<void>(
      _ColibriReportLoaderSheet(
        reportType: 'post',
        reportableId: _post.id,
      ),
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      constraints: const BoxConstraints(maxHeight: 520),
    );
  }

  Future<void> _openPost() async {
    await Get.to(() => ColibriPostDetailScreen(post: _post), opaque: false);
  }

  void _openAuthor() {
    final username =
        _post.authorUsername.trim().replaceFirst(RegExp(r'^@'), '');
    if (username.isNotEmpty) {
      Get.to(() => ColibriProfileScreen(username: username), opaque: false);
    }
  }

  void _showMoreMenu() {
    final guest = GuestSession.i.isGuest;
    showColibriSheet(
      context,
      title: '帖子操作',
      items: [
        // 访客：反应/收藏为登录后能力，菜单中直接隐藏（操作栏图标点击仍会弹引导）
        if (!guest)
          ColibriSheetItem(
            icon: Icons.add_reaction_rounded,
            label: '添加反应',
            onTap: () => showReactionPicker(
              context,
              onSelect: (code) => _toggleLike(code),
            ),
          ),
        ColibriSheetItem(
            icon: Icons.arrow_outward_rounded, label: '打开帖子', onTap: _openPost),
        if (!guest)
          ColibriSheetItem(
            icon: BookmarkStore.i.isBookmarked(_post.id)
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            label: BookmarkStore.i.isBookmarked(_post.id) ? '取消收藏' : '收藏',
            onTap: _toggleBookmark,
          ),
        if (_post.content.isNotEmpty)
          ColibriSheetItem(
              icon: Icons.text_fields_rounded,
              label: '复制文本',
              onTap: _copyContent),
        ColibriSheetItem(
            icon: Icons.link_rounded, label: '复制链接', onTap: _copyLink),
        ColibriSheetItem(icon: Icons.share_rounded, label: '分享', onTap: _share),
        if (_post.canDelete)
          ColibriSheetItem(
              icon: Icons.delete_outline_rounded,
              label: '删除',
              onTap: _delete,
              danger: true),
        if (_post.canReport)
          ColibriSheetItem(
              icon: Icons.report_gmailerrorred_rounded,
              label: '举报',
              onTap: _report,
              danger: true),
      ],
    );
  }

  /// 表情反应胶囊（对齐网页 ReactionsViewer）：表情图 + 数量；自己点过则高亮，点按切换该表情。
  Widget _buildReactionChip(ColibriReaction reaction) {
    final url = reaction.imageUrl;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _toggleLike(reaction.unifiedId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color:
              reaction.hasReacted ? cPrimary.withValues(alpha: 0.14) : cLightBg,
          borderRadius: BorderRadius.circular(20),
          border: reaction.hasReacted
              ? Border.all(color: cPrimary.withValues(alpha: 0.5))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (url != null && url.isNotEmpty)
              MyCachedImage(
                  imageUrl: url,
                  width: 18,
                  height: 18,
                  cornerRadius: 0,
                  resizeToDisplayBounds: widget.resizeMediaToDisplayBounds)
            else
              const SizedBox(width: 18, height: 18),
            const SizedBox(width: 4),
            Text(
              reaction.total > 0 ? '${reaction.total}' : '',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: reaction.hasReacted ? cPrimary : cLightText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 按帖子类型铺内容（对齐网页：image/gif→图，video→视频，audio→音频，document→文档，poll→投票）。
  List<Widget> _buildTypeContent() {
    final post = _post;
    final media = post.media;

    if (post.type == 'poll' && post.poll != null) {
      return [
        const SizedBox(height: 8),
        ColibriPostPoll(poll: post.poll!, onVote: _handlePollVote),
      ];
    }

    // 视频/音频/文档：单媒体为主，取首个对应类型媒体
    if (media.isNotEmpty) {
      final video = media.where((m) => m.isVideo).toList();
      final audio = media.where((m) => m.isAudio).toList();
      final document = media.where((m) => m.isDocument).toList();
      final gif = media.where((m) => m.isGif).toList();
      final image = media.where((m) => m.isImage).toList();

      if (video.isNotEmpty) {
        return [
          const SizedBox(height: 8),
          ColibriSensitiveMedia(
            sensitive: post.isSensitive,
            child: ColibriPostVideo(
              media: video.first,
              resizeThumbnailToDisplayBounds: widget.resizeMediaToDisplayBounds,
            ),
          ),
        ];
      }
      if (audio.isNotEmpty) {
        return [
          const SizedBox(height: 8),
          ColibriPostAudio(media: audio.first, label: post.authorName),
        ];
      }
      if (document.isNotEmpty) {
        return [
          const SizedBox(height: 8),
          ...document.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ColibriPostDocument(media: m),
              )),
        ];
      }
      if (gif.isNotEmpty) {
        return [
          const SizedBox(height: 8),
          ColibriSensitiveMedia(
            sensitive: post.isSensitive,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Get.to(
                  () => FullImageScreen(
                      image: gif.first.sourceUrl, tag: 'post_gif_${post.id}'),
                  opaque: false),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MyCachedImage(
                    imageUrl: gif.first.sourceUrl,
                    width: double.infinity,
                    height: 220,
                    cornerRadius: 12,
                    resizeToDisplayBounds: widget.resizeMediaToDisplayBounds),
              ),
            ),
          ),
        ];
      }
      if (image.isNotEmpty) {
        return [
          const SizedBox(height: 8),
          if (image.length == 1)
            ColibriSensitiveMedia(
              sensitive: post.isSensitive,
              child: _AdaptivePostImage(
                url: image[0].sourceUrl,
                resizeToDisplayBounds: widget.resizeMediaToDisplayBounds,
              ),
            )
          else
            ColibriSensitiveMedia(
              sensitive: post.isSensitive,
              child: _MediaGrid(
                images: image,
                postId: post.id,
                resizeToDisplayBounds: widget.resizeMediaToDisplayBounds,
              ),
            ),
        ];
      }
    }

    return const [];
  }

  @override
  Widget build(BuildContext context) {
    if (_target != _currentTarget) _resetTranslation();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 作者行
            Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _openAuthor,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: cLightBg,
                    backgroundImage: _post.authorAvatarUrl != null
                        ? NetworkImage(_post.authorAvatarUrl!)
                        : null,
                    child: _post.authorAvatarUrl == null
                        ? const Icon(Icons.person_rounded, color: cLightIcon)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _openAuthor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(_post.authorName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: cMainText)),
                            ),
                            if (_post.authorVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded,
                                  color: cBlueTick, size: 16),
                            ],
                            if (_post.isPinned) ...[
                              const SizedBox(width: 6),
                              const _PinnedBadge(),
                            ],
                            if (_post.isAd) ...[
                              const SizedBox(width: 6),
                              _AdBadge(label: LKeys.ad.tr),
                            ],
                          ],
                        ),
                        // 第二行：有个人标签(caption)则显示「标签 · 时间」，否则回退「@用户名 · 时间」（与网页一致）
                        Text(
                          _post.authorCaption.isNotEmpty
                              ? '${_post.authorCaption} · ${_post.timeAgo}'
                              : '@${_post.authorUsername} · ${_post.timeAgo}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(fontSize: 12, color: cLightText),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz_rounded, color: cLightText),
                  onPressed: _showMoreMenu,
                ),
              ],
            ),
            // 内容（Markdown 富文本渲染：粗体/斜体/删除线/下划线/高亮/代码/链接/@提及）
            if (_post.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              ColibriMarkdownText(
                _showTranslation && _translatedText != null
                    ? _translatedText!
                    : _post.content,
                style: const TextStyle(
                    fontSize: 15, color: cMainText, height: 1.4),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: _translating ? null : _toggleTranslation,
                  icon: _translating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(
                          _showTranslation
                              ? Icons.translate_rounded
                              : Icons.g_translate_rounded,
                          size: 16),
                  label: Text(_showTranslation &&
                          (_sourceLanguage?.isNotEmpty ?? false)
                      ? LKeys.translatedFrom.trParams({
                          'language':
                              ColibriTimelineService.translationLanguageName(
                                  _sourceLanguage!),
                        })
                      : (_showTranslation
                          ? LKeys.showOriginal.tr
                          : LKeys.translate.tr)),
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
                ),
              ),
            ],
            // AI 生成标签：正文底部，AI 图标 + 文字（琥珀色，与网页端一致）
            if (_post.isAiGenerated) ...[
              const SizedBox(height: 8),
              const _AiGeneratedBadge(),
            ],
            // 媒体 / 投票：按帖子类型分发展示（对齐网页 TimelinePublication 的分支渲染）
            ..._buildTypeContent(),
            // 表情反应胶囊行（对齐网页 ReactionsViewer：图+数量，点按切换该表情）
            if (_post.reactions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _post.reactions.map(_buildReactionChip).toList(),
              ),
            ],
            // 操作栏
            const SizedBox(height: 10),
            Row(
              children: [
                // ♥ 直接切换点赞；笑脸打开完整的表情反应选择器。
                _ActionIcon(
                  icon: _liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: _liked ? cRed : cLightText,
                  label: _totalReactions > 0 ? '$_totalReactions' : '',
                  onTap: () => _toggleLike(),
                ),
                const SizedBox(width: 16),
                _ActionIcon(
                  icon: Icons.emoji_emotions_outlined,
                  color: cLightText,
                  onTap: () {
                    if (GuestSession.i.isGuest) {
                      AuthGate.requireLogin(() {}, feature: '表情反应');
                      return;
                    }
                    showReactionPicker(
                      context,
                      onSelect: (code) => _toggleLike(code),
                    );
                  },
                ),
                const SizedBox(width: 16),
                _ActionIcon(
                  icon: Icons.chat_bubble_outline_rounded,
                  color: cLightText,
                  label: _post.commentsCount > 0
                      ? _post.commentsCountFormatted
                      : '',
                  onTap: widget.onTap,
                ),
                const SizedBox(width: 16),
                // 书签状态由全局 Store 驱动：在任何页面收藏/取消，此处即时更新
                Obx(() {
                  final marked = BookmarkStore.i.isBookmarked(_post.id);
                  return _ActionIcon(
                    icon: marked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: marked ? cPrimary : cLightText,
                    onTap: _toggleBookmark,
                  );
                }),
                const Spacer(),
                // 浏览量（只读：眼睛 + 缩写数字，右对齐，0 时不显示；图标比操作图标小一号）
                if (_post.viewsCount > 0)
                  _ActionIcon(
                    icon: Icons.visibility_outlined,
                    color: cLightText,
                    label: _post.viewsCountFormatted,
                    iconSize: 15,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 全部反应总数（♥ 旁显示）。
  int get _totalReactions => _post.reactions.fold(0, (sum, r) => sum + r.total);
}

/// 单图自适应展示（对齐网页端：单图按自然比例全高显示）。
/// 图片解析出宽高比后：高度 = 可用宽度 / 比例；超过屏高 62% 时封顶裁剪（cover 取中间）
/// 并显示「查看长图」角标，防止超长图刷屏。
class _AdaptivePostImage extends StatefulWidget {
  final String url;
  final bool resizeToDisplayBounds;

  const _AdaptivePostImage({
    required this.url,
    this.resizeToDisplayBounds = false,
  });

  @override
  State<_AdaptivePostImage> createState() => _AdaptivePostImageState();
}

class _AdaptivePostImageState extends State<_AdaptivePostImage> {
  double? _aspect; // 宽/高
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveAspect();
  }

  @override
  void didUpdateWidget(covariant _AdaptivePostImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.resizeToDisplayBounds != widget.resizeToDisplayBounds) {
      _aspect = null;
      _resolveAspect();
    }
  }

  @override
  void dispose() {
    _removeImageListener();
    super.dispose();
  }

  void _removeImageListener() {
    final stream = _stream;
    final listener = _listener;
    if (stream != null && listener != null) stream.removeListener(listener);
    _stream = null;
    _listener = null;
  }

  void _resolveAspect() {
    _removeImageListener();
    final logicalWidth = MediaQuery.sizeOf(context).width - 32;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = widget.resizeToDisplayBounds && logicalWidth > 0
        ? (logicalWidth * pixelRatio).ceil()
        : null;
    final provider = ResizeImage.resizeIfNeeded(
      cacheWidth,
      null,
      CachedNetworkImageProvider(widget.url, cacheKey: widget.url),
    );
    final stream = provider.resolve(createLocalImageConfiguration(context));
    late final ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      final w = info.image.width;
      final h = info.image.height;
      if (w > 0 && h > 0 && mounted) {
        setState(() => _aspect = w / h);
      }
      stream.removeListener(listener);
      if (identical(_stream, stream)) {
        _stream = null;
        _listener = null;
      }
    });
    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    final aspect = _aspect;
    // 宽高比未解析（图片加载中）：保持原 220 高度占位
    if (aspect == null || aspect <= 0) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _open,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: MyCachedImage(
              imageUrl: widget.url,
              width: double.infinity,
              height: 220,
              cornerRadius: 12,
              resizeToDisplayBounds: widget.resizeToDisplayBounds),
        ),
      );
    }

    // 可用宽度 = 屏宽 - 卡片水平 padding（16*2）
    final width = MediaQuery.of(context).size.width - 32;
    final maxHeight = MediaQuery.of(context).size.height * 0.62;
    var height = width / aspect;
    final capped = height > maxHeight;
    if (capped) height = maxHeight;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _open,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: double.infinity,
              height: height,
              // 未超限：高度=精确比例高度（cover 无裁剪）；超限：cover 裁中间
              child: MyCachedImage(
                  imageUrl: widget.url,
                  width: double.infinity,
                  height: height,
                  cornerRadius: 12,
                  resizeToDisplayBounds: widget.resizeToDisplayBounds),
            ),
          ),
          if (capped)
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_in_full_rounded,
                        color: Colors.white, size: 13),
                    SizedBox(width: 4),
                    Text('查看长图',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _open() {
    Get.to(() => ColibriPhotoViewerScreen(images: [widget.url]), opaque: false);
  }
}

/// 媒体多图网格（2 列，点击任意图进入多图查看器并定位到该图）。
class _MediaGrid extends StatelessWidget {
  final List<ColibriPostMedia> images;
  final int postId;
  final bool resizeToDisplayBounds;

  const _MediaGrid({
    required this.images,
    required this.postId,
    this.resizeToDisplayBounds = false,
  });

  @override
  Widget build(BuildContext context) {
    final urls = images.map((m) => m.sourceUrl).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1, // 正方形格子，对齐主流社交布局
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final img = images[index];
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Get.to(
              () => ColibriPhotoViewerScreen(
                    images: urls,
                    initialIndex: index,
                  ),
              opaque: false),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: MyCachedImage(
                imageUrl: img.sourceUrl,
                width: double.infinity,
                height: double.infinity,
                cornerRadius: 10,
                resizeToDisplayBounds: resizeToDisplayBounds),
          ),
        );
      },
    );
  }
}

/// AI 生成内容标签：帖子正文底部（对齐网页端 amber-500 的 ai-icon + 文案）。
class _AiGeneratedBadge extends StatelessWidget {
  const _AiGeneratedBadge();

  static const _amber = Color(0xFFF59E0B); // tailwind amber-500，与网页端一致

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.auto_awesome_rounded, size: 14, color: _amber),
        SizedBox(width: 4),
        Text('AI 生成',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: _amber)),
      ],
    );
  }
}

/// Native ad disclosure shown beside the post author.
class _AdBadge extends StatelessWidget {
  final String label;

  const _AdBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: cLightBg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.campaign_outlined, size: 11, color: cLightText),
          const SizedBox(width: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: cLightText)),
        ],
      ),
    );
  }
}

/// 置顶帖标签：图钉图标 + 「置顶」文案（对齐网页端 pin-02 置顶标识，
/// 仅全局置顶帖在 Feed 顶部展示时出现）。
class _PinnedBadge extends StatelessWidget {
  const _PinnedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: cPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.push_pin_rounded, size: 11, color: cPrimary),
          SizedBox(width: 2),
          Text('置顶',
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, color: cPrimary)),
        ],
      ),
    );
  }
}

/// 操作小图标 + 文案。
class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;
  final double iconSize;

  const _ActionIcon({
    required this.icon,
    required this.color,
    this.label = '',
    this.onTap,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: iconSize),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 13, color: color)),
          ],
        ],
      ),
    );
  }
}

typedef ColibriReportInfo = ({
  String title,
  String description,
  List<Map<String, dynamic>> reasons,
});

class _ColibriReportLoaderSheet extends StatefulWidget {
  final String reportType;
  final int reportableId;

  const _ColibriReportLoaderSheet({
    required this.reportType,
    required this.reportableId,
  });

  @override
  State<_ColibriReportLoaderSheet> createState() =>
      _ColibriReportLoaderSheetState();
}

class _ColibriReportLoaderSheetState extends State<_ColibriReportLoaderSheet> {
  late Future<ColibriReportInfo> _reasonsFuture;

  @override
  void initState() {
    super.initState();
    _reasonsFuture = _loadReasons();
  }

  Future<ColibriReportInfo> _loadReasons() {
    return ColibriTimelineService.shared.fetchReportReasons(
      type: widget.reportType,
    );
  }

  void _retry() {
    setState(() => _reasonsFuture = _loadReasons());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ColibriReportInfo>(
      future: _reasonsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _ColibriReportLoadingSheet();
        }
        final info = snapshot.data;
        if (snapshot.hasError || info == null || info.reasons.isEmpty) {
          return _ColibriReportErrorSheet(onRetry: _retry);
        }
        return ColibriReportSheet(
          reportType: widget.reportType,
          reportableId: widget.reportableId,
          info: info,
        );
      },
    );
  }
}

class _ColibriReportLoadingSheet extends StatelessWidget {
  const _ColibriReportLoadingSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
          SizedBox(width: 12),
          Text('正在加载举报选项'),
        ],
      ),
    );
  }
}

class _ColibriReportErrorSheet extends StatelessWidget {
  final VoidCallback onRetry;

  const _ColibriReportErrorSheet({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('举报选项加载失败'),
          const SizedBox(height: 14),
          TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

/// 举报两步弹层：第一步选理由，第二步确认 + 可选补充说明。
/// 429 限流时弹层保持打开，展示服务端文案 + 下次可举报倒计时；422 敏感词错误内联显示在输入框下。
class ColibriReportSheet extends StatefulWidget {
  final String reportType;
  final int reportableId;
  final ColibriReportInfo info;

  const ColibriReportSheet({
    super.key,
    required this.reportType,
    required this.reportableId,
    required this.info,
  });

  @override
  State<ColibriReportSheet> createState() => _ColibriReportSheetState();
}

class _ColibriReportSheetState extends State<ColibriReportSheet> {
  static const _amber = Color(0xFFD97706);
  static const _amberSoft = Color(0xFFFFF6E5);

  final _commentController = TextEditingController();

  int? _reasonIndex;
  bool _submitting = false;
  String? _commentError;
  String? _rateLimitMessage;
  int _rateLimitSeconds = 0;
  Timer? _countdownTimer;
  @override
  void dispose() {
    _countdownTimer?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();

    setState(() => _rateLimitSeconds = seconds);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() => _rateLimitSeconds = _rateLimitSeconds - 1);

      if (_rateLimitSeconds <= 0) {
        timer.cancel();

        setState(() {
          _rateLimitSeconds = 0;
          _rateLimitMessage = null;
        });
      }
    });
  }

  String get _countdownText {
    final hours = _rateLimitSeconds ~/ 3600;
    final minutes = (_rateLimitSeconds % 3600) ~/ 60;
    final seconds = _rateLimitSeconds % 60;

    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(hours)}:${two(minutes)}:${two(seconds)}';
  }

  Future<void> _submit() async {
    if (_submitting || _reasonIndex == null || _rateLimitSeconds > 0) return;

    setState(() {
      _submitting = true;
      _commentError = null;
    });

    try {
      await ColibriTimelineService.shared.sendReport(
        type: widget.reportType,
        reportableId: widget.reportableId,
        reasonIndex: _reasonIndex!,
        comment: _commentController.text,
      );

      if (mounted) {
        Navigator.of(context).pop();
        showColibriToast('已提交举报',
            message: '感谢你的反馈，我们会尽快处理',
            backgroundColor: cGreen,
            colorText: Colors.white);
      }
    } on ColibriApiException catch (e) {
      if (!mounted) return;

      // 429 举报限流：弹层保持打开，展示规则文案与倒计时
      if (e.statusCode == 429) {
        final retryAfter = e.data?['retry_after'];

        setState(() {
          _submitting = false;
          _rateLimitMessage = e.message;
        });

        if (retryAfter is int && retryAfter > 0) {
          _startCountdown(retryAfter);
        }

        return;
      }

      // 422 补充说明含敏感词：错误内联显示在输入框下
      if (e.statusCode == 422 && e.errors?['comment'] != null) {
        final commentErrors = e.errors!['comment'];

        setState(() {
          _submitting = false;
          _commentError = commentErrors is List && commentErrors.isNotEmpty
              ? commentErrors.first.toString()
              : e.message;
        });

        return;
      }

      setState(() => _submitting = false);
      Navigator.of(context).pop();
      showColibriToast('举报失败',
          message: e.message, backgroundColor: cRed, colorText: Colors.white);
    } catch (e) {
      if (!mounted) return;

      setState(() => _submitting = false);
      Navigator.of(context).pop();
      showColibriToast('举报失败',
          message: e.toString(),
          backgroundColor: cRed,
          colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassLens(
      style: const LiquidGlassStyle(
        shape: LiquidGlassShape.continuousRoundedRectangle(
          cornerRadius: 28,
          clipQuality: LiquidGlassClipQuality.exact,
          borderWidth: 0.8,
          lightIntensity: 1,
          lightDirection: 45,
          borderType: OpticalBorder(
            borderSaturation: 1.1,
            ambientIntensity: 0.9,
            borderSolidity: 0.75,
          ),
        ),
        appearance: LiquidGlassAppearance(
          color: Color(0xF7FFFFFF),
          blur: LiquidGlassBlur(sigmaX: 2, sigmaY: 2),
        ),
        refraction: LiquidGlassRefraction(
          distortion: 0.07,
          distortionWidth: 16,
          chromaticAberration: 0.0005,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, top: 8),
              child: SizedBox(
                height: 42,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: '关闭',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: cBlack),
                        style: IconButton.styleFrom(
                          backgroundColor: cWhite,
                          minimumSize: const Size(42, 42),
                          shape: const CircleBorder(),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    Text(
                      _reasonIndex == null ? widget.info.title : '确认举报',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: cMainText),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: cLightBg, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _reasonIndex == null
                    ? widget.info.description
                    : '可补充更多细节或证据链接，帮助我们更快核实',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: cLightText),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: _reasonIndex == null
                  ? _buildReasonStep()
                  : _buildConfirmStep(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 第一步：选择理由，点选后进入确认步骤。
  Widget _buildReasonStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('选择举报原因',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: cMainText)),
          const SizedBox(height: 4),
          ...List.generate(widget.info.reasons.length, (i) {
            final reason = widget.info.reasons[i];
            return InkWell(
              onTap: () => setState(() => _reasonIndex = i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reason['title']?.toString() ?? '',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cMainText)),
                    const SizedBox(height: 2),
                    Text(reason['description']?.toString() ?? '',
                        style:
                            const TextStyle(fontSize: 12, color: cLightText)),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCommentField({required bool limited}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('补充说明（可选）',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: cMainText)),
        const SizedBox(height: 6),
        TextField(
          controller: _commentController,
          maxLines: 4,
          minLines: 3,
          maxLength: 500,
          enabled: !limited,
          style: const TextStyle(fontSize: 14, color: cMainText),
          decoration: InputDecoration(
            hintText: '补充更多细节或证据链接（可选）',
            hintStyle: const TextStyle(fontSize: 13, color: cLightText),
            filled: true,
            fillColor: cBG,
            counterStyle: const TextStyle(fontSize: 11, color: cLightText),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: _commentError != null ? cRed : Colors.transparent),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: _commentError != null ? cRed : Colors.transparent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: _commentError != null ? cRed : cPrimary),
            ),
          ),
        ),
        if (_commentError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_commentError!,
                style: const TextStyle(fontSize: 12, color: cRed)),
          ),
      ],
    );
  }

  /// 第二步：所选理由回显 + 补充说明 + 限流横幅 + 提交按钮。
  Widget _buildConfirmStep() {
    final reason = widget.info.reasons[_reasonIndex!];
    final limited = _rateLimitSeconds > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 所选理由回显 + 换理由入口
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
                color: cLightBg, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                const Icon(Icons.flag_rounded, size: 18, color: cRed),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reason['title']?.toString() ?? '',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cMainText),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _reasonIndex = null),
                  child: const Text('换个理由',
                      style: TextStyle(
                          fontSize: 12,
                          color: cPrimary,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildCommentField(limited: limited),
          // 限流横幅：服务端文案 + 实时倒计时
          if (_rateLimitMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _amberSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _amber.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 18, color: _amber),
                      SizedBox(width: 8),
                      Text('举报次数已达上限',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: cMainText)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(_rateLimitMessage!,
                      style: const TextStyle(
                          fontSize: 12, color: cDarkText, height: 1.4)),
                  if (limited)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined,
                              size: 15, color: _amber),
                          const SizedBox(width: 6),
                          const Text('距下次可举报还有 ',
                              style: TextStyle(fontSize: 12, color: cDarkText)),
                          Text(
                            _countdownText,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _amber,
                                fontFeatures: [FontFeature.tabularFigures()]),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // 提交按钮：提交中/限流中禁用
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: (_submitting || limited) ? null : _submit,
              style: TextButton.styleFrom(
                backgroundColor: cPrimary,
                disabledBackgroundColor: cLightBg,
                foregroundColor: Colors.white,
                disabledForegroundColor: cLightText,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.2, color: Colors.white))
                  : const Text('发送举报',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

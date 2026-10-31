import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/widgets/colibri_markdown_text.dart';
import 'package:untitled/common/widgets/colibri_ui.dart';
import 'package:untitled/common/api_service/colibri_timeline_service.dart';
import 'package:untitled/common/widgets/emoji_reaction_picker.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/models/colibri_post_models.dart';
import 'package:untitled/screens/colibri_feed/comments/comment_thread_controller.dart';
import 'package:untitled/utilities/const.dart';

/// 评论区统一交互回调（主评论/回复共用）。
class CommentActions {
  final void Function(ColibriComment comment) onAvatarTap;
  final void Function(ColibriComment comment) onReplyTap;
  final void Function(ColibriComment comment, String unifiedId) onLikeTap;
  final void Function(ColibriComment comment) onDeleteTap;
  final void Function(ColibriComment comment) onCopyTap;

  const CommentActions({
    required this.onAvatarTap,
    required this.onReplyTap,
    required this.onLikeTap,
    required this.onDeleteTap,
    required this.onCopyTap,
  });
}

/// 一条主评论线程：主评论 + 树状缩进回复区（折叠预览 / 展开全部）。
class CommentThreadView extends StatelessWidget {
  final CommentThread thread;
  final CommentActions actions;
  final void Function(CommentThread thread) onToggleExpand;
  final void Function(CommentThread thread) onLoadMoreReplies;

  const CommentThreadView({
    super.key,
    required this.thread,
    required this.actions,
    required this.onToggleExpand,
    required this.onLoadMoreReplies,
  });

  @override
  build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
          child: CommentTile(
            comment: thread.root,
            isReply: false,
            actions: actions,
          ),
        ),
        // 有回复时才渲染缩进卡片
        Obx(() => thread.total.value > 0
            ? Padding(
                padding: const EdgeInsets.only(
                    left: 46, right: 12, top: 2, bottom: 6),
                child: _RepliesContainer(
                  thread: thread,
                  actions: actions,
                  onToggleExpand: () => onToggleExpand(thread),
                  onLoadMore: () => onLoadMoreReplies(thread),
                ),
              )
            : const SizedBox.shrink()),
      ],
    );
  }
}

/// 回复区：浅灰圆角卡片 + 左侧层级竖线，AnimatedSize 驱动展开/折叠过渡。
///
/// 展开态结构（关键：即使有上百条回复，收起入口也永远可见）：
/// - 顶部常驻「全部 N 条回复 ∧」头部，不随回复滚动，点按即收起；
/// - 回复列表在有界高度（屏幕高 55%）内独立滚动，不会把整页撑得很长；
/// - 「查看更多回复」位于内部列表末尾。
class _RepliesContainer extends StatelessWidget {
  final CommentThread thread;
  final CommentActions actions;
  final VoidCallback onToggleExpand;
  final VoidCallback onLoadMore;

  const _RepliesContainer({
    required this.thread,
    required this.actions,
    required this.onToggleExpand,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 层级关系竖线
        Container(
            width: 2.5,
            margin: const EdgeInsets.only(top: 6, bottom: 6, right: 8),
            color: cPrimary.withValues(alpha: 0.35)),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: cLightBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Obx(() {
              final expanded = thread.expanded.value;
              return AnimatedSize(
                alignment: Alignment.topCenter,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: expanded ? _buildExpanded(context) : _buildCollapsed(),
              );
            }),
          ),
        ),
      ],
    );
  }

  /// 折叠态：最新 2 条回复预览 + 「共 N 条回复 >」。
  Widget _buildCollapsed() {
    final previews = thread.previewReplies;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(previews.length, (i) {
            final comment = previews[i];
            return _ReplySlideIn(
              key: ValueKey('reply_${comment.id}'),
              child: Column(
                children: [
                  if (i > 0)
                    Divider(
                        height: 14,
                        thickness: 0.6,
                        color: cBlack.withValues(alpha: 0.06)),
                  CommentTile(
                      comment: comment,
                      isReply: true,
                      preview: true,
                      actions: actions),
                ],
              ),
            );
          }),
          _ThreadFooter(
            thread: thread,
            onToggleExpand: onToggleExpand,
          ),
        ],
      ),
    );
  }

  /// 展开态：常驻收起头部 + 有界独立滚动列表。
  Widget _buildExpanded(BuildContext context) {
    final maxListHeight = MediaQuery.of(context).size.height * 0.55;
    final replies = thread.loadedReplies;

    final listChildren = <Widget>[
      ...List.generate(replies.length, (i) {
        final comment = replies[i];
        return _ReplySlideIn(
          key: ValueKey('reply_${comment.id}'),
          child: Column(
            children: [
              if (i > 0)
                Divider(
                    height: 14,
                    thickness: 0.6,
                    color: cBlack.withValues(alpha: 0.06)),
              CommentTile(comment: comment, isReply: true, actions: actions),
            ],
          ),
        );
      }),
      // 「查看更多回复」跟随内部列表，在内容最末尾
      Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 2),
        child: _ExpandedLoadMore(thread: thread, onLoadMore: onLoadMore),
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 常驻头部：任何滚动位置都可一键收起
        _CollapseHeader(count: thread.total.value, onTap: onToggleExpand),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxListHeight),
          child: thread.loadingFirst.value
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: cPrimary, strokeWidth: 2)),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(10, 2, 10, 6),
                  shrinkWrap: true,
                  // Clamping：内部列表滚到边界后拖动可自然传递给外层页面
                  physics: const ClampingScrollPhysics(),
                  children: listChildren,
                ),
        ),
      ],
    );
  }
}

/// 展开态常驻头部：「全部 N 条回复」+ 收起按钮。
class _CollapseHeader extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _CollapseHeader({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 10, 4),
        child: Row(
          children: [
            Text('全部 $count 条回复',
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: cGreen)),
            const Spacer(),
            const Text('收起',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: cGreen)),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_up_rounded,
                size: 16, color: cGreen),
          ],
        ),
      ),
    );
  }
}

/// 展开态内部列表底部的「查看更多」/ 加载中 / 重试。
class _ExpandedLoadMore extends StatelessWidget {
  final CommentThread thread;
  final VoidCallback onLoadMore;

  const _ExpandedLoadMore({required this.thread, required this.onLoadMore});

  @override
  Widget build(BuildContext context) {
    if (thread.actionError.value) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onLoadMore,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('回复加载失败，点击重试',
              style: TextStyle(fontSize: 12.5, color: cRed)),
        ),
      );
    }
    if (!thread.hasMore) return const SizedBox(height: 4);
    if (thread.loadingMore.value) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
              height: 15,
              width: 15,
              child:
                  CircularProgressIndicator(color: cPrimary, strokeWidth: 2)),
        ),
      );
    }
    final remaining = (thread.total.value - thread.loadedReplies.length)
        .clamp(0, thread.total.value);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onLoadMore,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('查看更多回复${remaining > 0 ? '（$remaining）' : ''}',
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: cGreen)),
            const SizedBox(width: 2),
            const Icon(Icons.expand_more_rounded, size: 16, color: cGreen),
          ],
        ),
      ),
    );
  }
}

/// 折叠态底部入口：「共 N 条回复 >」。
class _ThreadFooter extends StatelessWidget {
  final CommentThread thread;
  final VoidCallback onToggleExpand;

  const _ThreadFooter({required this.thread, required this.onToggleExpand});

  @override
  Widget build(BuildContext context) {
    final total = thread.total.value;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: _FooterButton(
        onTap: onToggleExpand,
        icon: Icons.keyboard_arrow_down_rounded,
        iconAfter: true,
        label: total > thread.previewReplies.length ? '共 $total 条回复' : '展开回复',
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final bool iconAfter;
  final String label;

  const _FooterButton(
      {required this.onTap,
      required this.icon,
      required this.iconAfter,
      required this.label});

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, size: 16, color: cGreen);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!iconAfter) ...[iconWidget, const SizedBox(width: 2)],
            Text(label,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: cGreen)),
            if (iconAfter) ...[const SizedBox(width: 2), iconWidget],
          ],
        ),
      ),
    );
  }
}

/// 单条评论（主评论/回复复用，密度不同）。
class CommentTile extends StatelessWidget {
  final ColibriComment comment;
  final bool isReply;

  /// 折叠预览态：内容最多 2 行（点击展开），操作区弱化。
  final bool preview;
  final CommentActions actions;

  const CommentTile({
    super.key,
    required this.comment,
    required this.isReply,
    required this.actions,
    this.preview = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = isReply ? 26.0 : 38.0;
    final nameSize = isReply ? 12.5 : 13.5;
    final contentSize = isReply ? 13.5 : 14.5;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => actions.onAvatarTap(comment),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: comment.userName.isNotEmpty
                      ? comment.userName
                      : '@${comment.userUsername}',
                  style: TextStyle(
                      fontSize: nameSize,
                      fontWeight: FontWeight.w700,
                      color: cMainText),
                ),
                TextSpan(
                    text: ' · ${comment.timeAgo}',
                    style: const TextStyle(fontSize: 11.5, color: cLightText)),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 3),
        // 回复：行内「回复 @某某：」前缀（绿色），与正文自然换行，清晰表达层级关系
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            if (comment.hasParent && comment.parentUserUsername.isNotEmpty)
              Text(
                '回复 @${comment.parentUserUsername}：',
                style: TextStyle(
                    fontSize: contentSize,
                    color: cGreen,
                    fontWeight: FontWeight.w600,
                    height: 1.4),
              ),
            ColibriMarkdownText(
              comment.content,
              style: TextStyle(
                  fontSize: contentSize, color: cMainText, height: 1.4),
              maxLines: preview ? 2 : null,
              overflow: preview ? TextOverflow.ellipsis : null,
            ),
          ],
        ),
        if (!preview) ...[
          const SizedBox(height: 4),
          _ActionRow(comment: comment, isReply: isReply, actions: actions),
        ],
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => actions.onAvatarTap(comment),
          child: MyCachedImage(
            imageUrl: comment.userAvatarUrl,
            height: avatarSize,
            width: avatarSize,
            cornerRadius: avatarSize,
          ),
        ),
        SizedBox(width: isReply ? 8 : 10),
        Expanded(child: body),
        if (!preview) _MoreButton(comment: comment, actions: actions),
      ],
    );
  }
}

/// 回复 / 表情反应胶囊行。
class _ActionRow extends StatelessWidget {
  final ColibriComment comment;
  final bool isReply;
  final CommentActions actions;

  const _ActionRow(
      {required this.comment, required this.isReply, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () =>
              actions.onLikeTap(comment, ColibriTimelineService.likeUnifiedId),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Icon(
              comment.liked
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: comment.liked ? cRed : cLightText,
              size: isReply ? 14 : 16,
            ),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => showReactionPicker(
            context,
            onSelect: (code) => actions.onLikeTap(comment, code),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Icon(Icons.emoji_emotions_outlined,
                color: cLightText, size: isReply ? 14 : 16),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => actions.onReplyTap(comment),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text('回复',
                style: TextStyle(
                    fontSize: isReply ? 11.5 : 12,
                    fontWeight: FontWeight.w600,
                    color: cGreen)),
          ),
        ),
        ...comment.reactions.map((r) => ReactionChip(
              reaction: r,
              compact: isReply,
              onTap: () => actions.onLikeTap(comment, r.unifiedId),
            )),
      ],
    );
  }
}

/// 评论表情反应胶囊（图 + 数量 + 高亮）。
class ReactionChip extends StatelessWidget {
  final ColibriReaction reaction;
  final bool compact;
  final VoidCallback onTap;

  const ReactionChip(
      {super.key,
      required this.reaction,
      required this.onTap,
      this.compact = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 7, vertical: compact ? 2 : 3),
        decoration: BoxDecoration(
          color: reaction.hasReacted
              ? cPrimary.withValues(alpha: 0.14)
              : cBlack.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: reaction.hasReacted
              ? Border.all(color: cPrimary.withValues(alpha: 0.5))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MyCachedImage(
                imageUrl: reaction.imageUrl,
                width: 15,
                height: 15,
                cornerRadius: 0),
            if (reaction.total > 0) ...[
              const SizedBox(width: 3),
              Text(
                '${reaction.total}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: reaction.hasReacted ? cGreen : cLightText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  final ColibriComment comment;
  final CommentActions actions;

  const _MoreButton({required this.comment, required this.actions});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showMenu(context),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(Icons.more_horiz_rounded, color: cLightText, size: 18),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showColibriSheet(
      context,
      title: '评论操作',
      items: [
        ColibriSheetItem(
            icon: Icons.reply_rounded,
            label: '回复',
            onTap: () => actions.onReplyTap(comment)),
        ColibriSheetItem(
            icon: Icons.text_fields_rounded,
            label: '复制文本',
            onTap: () => actions.onCopyTap(comment)),
        if (comment.canDelete)
          ColibriSheetItem(
            icon: Icons.delete_outline_rounded,
            label: '删除',
            danger: true,
            onTap: () => actions.onDeleteTap(comment),
          ),
      ],
    );
  }
}

/// 新回复出现时的轻微淡入 + 上移动画（同 key 复用不会重放）。
class _ReplySlideIn extends StatefulWidget {
  final Widget child;

  const _ReplySlideIn({super.key, required this.child});

  @override
  State<_ReplySlideIn> createState() => _ReplySlideInState();
}

class _ReplySlideInState extends State<_ReplySlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );
  late final Animation<double> _opacity =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _offset =
      Tween(begin: const Offset(0, 0.12), end: Offset.zero).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

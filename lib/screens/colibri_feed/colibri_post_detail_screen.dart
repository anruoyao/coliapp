import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_timeline_service.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
import 'package:untitled/common/managers/guest_session.dart';
import 'package:untitled/common/managers/haptic_manager.dart';
import 'package:untitled/common/widgets/colibri_mentions.dart';
import 'package:untitled/common/widgets/colibri_ui.dart';
import 'package:untitled/common/widgets/guest_auth_sheet.dart';
import 'package:untitled/models/colibri_post_models.dart';
import 'package:untitled/screens/colibri_feed/colibri_post_card.dart';
import 'package:untitled/screens/colibri_feed/comments/comment_thread_controller.dart';
import 'package:untitled/screens/colibri_feed/comments/comment_widgets.dart';
import 'package:untitled/screens/colibri_social/colibri_profile_screen.dart';
import 'package:untitled/utilities/const.dart';

class ColibriPostDetailScreen extends StatefulWidget {
  final ColibriPost post;

  const ColibriPostDetailScreen({super.key, required this.post});

  @override
  State<ColibriPostDetailScreen> createState() =>
      _ColibriPostDetailScreenState();
}

class _ColibriPostDetailScreenState extends State<ColibriPostDetailScreen> {
  late final ColibriPost _initialPost;
  late final String _controllerTag;
  late final CommentThreadController _controller;
  final TextEditingController _commentInput = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initialPost = widget.post;
    _controllerTag =
        'comments_${widget.post.id}_${DateTime.now().microsecondsSinceEpoch}';
    _controller =
        Get.put(CommentThreadController(_initialPost), tag: _controllerTag);
  }

  @override
  void dispose() {
    _commentInput.dispose();
    _commentFocus.dispose();
    _scrollController.dispose();
    Get.delete<CommentThreadController>(tag: _controllerTag);
    super.dispose();
  }

  Future<void> _sendComment() async {
    if (GuestSession.i.isGuest) {
      AuthGate.requireLogin(() {}, feature: '评论');
      return;
    }
    final content = _commentInput.text.trim();
    if (content.isEmpty) return;
    final ok = await _controller.send(content);
    if (!mounted) return;
    if (ok) {
      _commentInput.clear();
      HapticManager.shared.light();
    } else {
      showColibriToast('评论失败',
          message: '请稍后重试', backgroundColor: cRed, colorText: Colors.white);
    }
  }

  void _onReplyTap(ColibriComment comment) {
    if (GuestSession.i.isGuest) {
      AuthGate.requireLogin(() {}, feature: '回复评论');
      return;
    }
    _controller.setReplyTarget(comment);
    _commentFocus.requestFocus();
  }

  Future<void> _onLikeTap(ColibriComment comment, String unifiedId) async {
    if (GuestSession.i.isGuest) {
      AuthGate.requireLogin(() {}, feature: '评论点赞');
      return;
    }
    try {
      final reactions =
          await ColibriTimelineService.shared.toggleCommentReaction(
        comment.id,
        unifiedId: unifiedId,
      );
      _controller.applyReactions(comment.id, reactions);
      HapticManager.shared.light();
    } catch (_) {}
  }

  Future<void> _onDeleteTap(ColibriComment comment) async {
    final confirmed = await showColibriConfirmDialog(
      context,
      icon: comment.isRoot
          ? Icons.speaker_notes_off_outlined
          : Icons.delete_outline_rounded,
      title: comment.isRoot ? '删除这条评论？' : '删除这条回复？',
      message: comment.isRoot ? '评论及其全部回复将被永久删除，无法恢复' : '回复将被永久删除，无法恢复',
      confirmText: '删除',
      onConfirm: () async {
        try {
          await _controller.delete(comment);
          return true;
        } catch (_) {
          showColibriToast('删除失败',
              message: '请稍后重试', backgroundColor: cRed, colorText: Colors.white);
          return false;
        }
      },
    );
    if (confirmed) HapticManager.shared.medium();
  }

  CommentActions get _actions => CommentActions(
        onAvatarTap: (c) {
          if (c.userUsername.isNotEmpty) {
            Get.to(() => ColibriProfileScreen(username: c.userUsername),
                opaque: false);
          }
        },
        onReplyTap: _onReplyTap,
        onLikeTap: _onLikeTap,
        onDeleteTap: _onDeleteTap,
        onCopyTap: (c) => Clipboard.setData(ClipboardData(text: c.content)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cWhite,
      appBar: AppBar(
        backgroundColor: cWhite,
        surfaceTintColor: cWhite,
        elevation: 0,
        title: const Text('帖子',
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 17, color: cMainText)),
        leading: BackButton(color: cBlack, onPressed: () => Get.back()),
      ),
      body: Obx(() {
        if (_controller.loading.value) {
          return const Center(
              child: CircularProgressIndicator(color: cPrimary));
        }
        return Column(
          children: [
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.metrics.pixels >=
                      notification.metrics.maxScrollExtent - 400) {
                    _controller.loadMoreRoots();
                  }
                  return false;
                },
                child: ListView(
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    ColibriPostCard(post: _controller.post, onTap: null),
                    _buildHeader(),
                    if (_controller.threads.isEmpty)
                      const ColibriEmptyState(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: '还没有评论',
                        subtitle: '抢沙发，说点什么吧',
                        topSpacing: 24,
                      )
                    else
                      ..._controller.threads.map((thread) => CommentThreadView(
                            key: ValueKey('thread_${thread.rootId}'),
                            thread: thread,
                            actions: _actions,
                            onToggleExpand: (t) => _controller.toggleExpand(t),
                            onLoadMoreReplies: (t) =>
                                _controller.loadMoreReplies(t),
                          )),
                    Obx(() => _controller.loadingMoreRoots.value
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: cPrimary, strokeWidth: 2.2)),
                            ),
                          )
                        : const SizedBox(height: 12)),
                    const SizedBox(height: 70),
                  ],
                ),
              ),
            ),
            _buildInputBar(),
          ],
        );
      }),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
      child: Row(
        children: [
          const Text('评论',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: cMainText)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2.5),
            decoration: BoxDecoration(
              color: cPrimary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_controller.post.commentsCount}',
              style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w700, color: cGreen),
            ),
          ),
          const Spacer(),
          if (_controller.post.viewsCount > 0) ...[
            const Icon(Icons.visibility_outlined, size: 13, color: cLightText),
            const SizedBox(width: 4),
            Text(_controller.post.viewsCountFormatted,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: cLightText)),
          ],
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    if (GuestSession.i.isGuest) {
      return SafeArea(
        top: false,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => AuthGate.requireLogin(() {}, feature: '评论'),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: cLightBg,
              borderRadius: BorderRadius.circular(23),
              border:
                  Border.all(color: cPrimary.withValues(alpha: 0.35), width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 16, color: cLightText),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('登录后发表评论…',
                      style: TextStyle(color: cLightText, fontSize: 14.5)),
                ),
                const Text('去登录',
                    style: TextStyle(
                        color: cGreen,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: const BoxDecoration(
            color: cWhite, border: Border(top: BorderSide(color: cLightBg))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() {
              final target = _controller.replyTarget.value;
              return AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: target == null
                    ? const SizedBox.shrink()
                    : Container(
                        key: ValueKey('reply_chip_${target.id}'),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: cPrimary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.reply_rounded,
                                size: 15, color: cGreen),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '回复 @${target.userUsername}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: cGreen),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _controller.setReplyTarget(null),
                              child: const Icon(Icons.close_rounded,
                                  size: 16, color: cLightText),
                            ),
                          ],
                        ),
                      ),
              );
            }),
            Row(
              children: [
                Expanded(
                  child: Obx(() {
                    final target = _controller.replyTarget.value;
                    final hint = target != null
                        ? '回复 @${target.userUsername}...'
                        : '写评论...';
                    return MentionField(
                      controller: _commentInput,
                      focusNode: _commentFocus,
                      hintText: hint,
                      hintStyle:
                          const TextStyle(color: cLightText, fontSize: 14.5),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendComment(),
                      suggestionsAbove: true,
                      suggestionsMaxHeight: 220,
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle:
                            const TextStyle(color: cLightText, fontSize: 14.5),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 11),
                        filled: true,
                        fillColor: cLightBg,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide:
                              const BorderSide(color: cPrimary, width: 1.4),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendComment,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                        color: cPrimary, shape: BoxShape.circle),
                    child: Obx(() => _controller.sending.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: Padding(
                              padding: EdgeInsets.all(2),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.2, color: cWhite),
                            ),
                          )
                        : const Icon(Icons.send_rounded,
                            color: cWhite, size: 19)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

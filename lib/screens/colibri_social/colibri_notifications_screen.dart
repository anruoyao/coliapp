import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_social_service.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'package:untitled/common/api_service/colibri_timeline_service.dart';
import 'package:untitled/common/managers/reverb_service.dart';
import 'package:untitled/common/widgets/colibri_ui.dart';
import 'package:untitled/models/colibri_social_models.dart';
import 'package:untitled/screens/colibri_feed/colibri_post_detail_screen.dart';
import 'package:untitled/screens/colibri_social/colibri_profile_screen.dart';
import 'package:untitled/utilities/const.dart';
import 'package:url_launcher/url_launcher.dart';

/// 通知列表。
/// [asTab] 为 true 时作为主页底部 Tab 使用（无返回键）。
class ColibriNotificationsScreen extends StatefulWidget {
  final bool asTab;

  const ColibriNotificationsScreen({super.key, this.asTab = false});

  @override
  State<ColibriNotificationsScreen> createState() =>
      _ColibriNotificationsScreenState();
}

class _ColibriNotificationsScreenState
    extends State<ColibriNotificationsScreen> {
  final List<ColibriNotification> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    // 实时：收到新社交通知广播自动刷新列表
    ReverbService.shared.on(ReverbService.eventNotification, (_) => _load());
  }

  @override
  void dispose() {
    ReverbService.shared.off(ReverbService.eventNotification, (_) => _load());
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ColibriSocialService.shared.fetchNotifications();
      setState(() => _notifications
        ..clear()
        ..addAll(list));
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(ColibriNotification n) async {
    try {
      await ColibriSocialService.shared.deleteNotification(n.id);
      setState(() => _notifications.removeWhere((x) => x.id == n.id));
    } catch (_) {}
  }

  void _confirmDelete(ColibriNotification n) {
    showColibriBottomSheet<void>(
      _DeleteNotificationSheet(onConfirm: () => _delete(n)),
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.36),
      useSafeArea: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 420, maxHeight: 280),
    );
  }

  void _openActor(ColibriNotification n) {
    final username = n.actor['username']?.toString();
    if (username != null && username.isNotEmpty) {
      Get.to(() => ColibriProfileScreen(username: username), opaque: false);
    }
  }

  /// 关注请求类通知（未被处理过时展示 同意/拒绝 按钮）。
  bool _isPendingFollowRequest(ColibriNotification n) {
    return n.type == 'user.followed-requested' &&
        n.metadata['is_approved'] != true;
  }

  int? _followRequestActorId(ColibriNotification n) {
    final v = n.entity['id'];
    if (v is int) return v;
    return int.tryParse('${v ?? ''}');
  }

  Future<void> _acceptFollow(ColibriNotification n) async {
    final actorId = _followRequestActorId(n);
    if (actorId == null) return;
    try {
      await ColibriSocialService.shared.acceptFollowRequest(actorId);
      showColibriToast('已同意关注请求',
          message: '', backgroundColor: cGreen, colorText: Colors.white);
      // 服务端会清掉该请求者的所有请求通知；本地也按请求者移除，避免重复请求残留
      setState(() => _notifications
          .removeWhere((x) => _followRequestActorId(x) == actorId));
    } catch (e) {
      showColibriToast('操作失败',
          message: e.toString(),
          backgroundColor: cRed,
          colorText: Colors.white);
    }
  }

  Future<void> _declineFollow(ColibriNotification n) async {
    final actorId = _followRequestActorId(n);
    if (actorId == null) return;
    try {
      await ColibriSocialService.shared.declineFollowRequest(actorId);
      showColibriToast('已拒绝关注请求',
          message: '', backgroundColor: cLightBg, colorText: cMainText);
      // 服务端会清掉该请求者的所有请求通知；本地也按请求者移除
      setState(() => _notifications
          .removeWhere((x) => _followRequestActorId(x) == actorId));
    } catch (e) {
      showColibriToast('操作失败',
          message: e.toString(),
          backgroundColor: cRed,
          colorText: Colors.white);
    }
  }

  /// 点击跳转：对齐网页端 NotificationItem 的 notificationRoute 逻辑。
  /// 营销通知（marketing.platform）为平台批量内容，点击不跳转发送者主页；
  /// 帖子/评论类 → 帖子详情；关注类 → 对方主页；其余回退到触发者主页。
  Future<void> _handleTap(ColibriNotification n) async {
    final type = n.type;
    final entity = n.entity;

    // 平台营销通知：整卡不跳转（仅帖子迷你卡与「查看详情」可交互）
    if (n.isMarketing) {
      return;
    }

    // 帖子相关通知 → 帖子详情（post.reacted / post.commented / post.mentioned）
    String? postHash;
    if (type.startsWith('post.')) {
      postHash = entity['hash_id']?.toString();
    }
    // 评论相关通知 → 其所属帖子详情（comment.mentioned / comment.reacted）
    else if (type.startsWith('comment.')) {
      postHash = entity['post_hash_id']?.toString();
    }

    if (await _openPost(postHash)) return;

    // 关注类（user.followed / user.follow-accepted / user.followed-requested / account-linked）
    final profileUsername = entity['username']?.toString();
    if (profileUsername != null && profileUsername.isNotEmpty) {
      await Get.to(() => ColibriProfileScreen(username: profileUsername),
          opaque: false);
      return;
    }

    _openActor(n);
  }

  /// 跳转帖子详情。[hashId] 为空或加载失败时返回 false（调用方继续回退逻辑）。
  Future<bool> _openPost(String? hashId) async {
    if (hashId == null || hashId.isEmpty) return false;
    try {
      final detail =
          await ColibriTimelineService.shared.fetchPostDetail(hashId);
      if (!mounted) return true;
      await Get.to(() => ColibriPostDetailScreen(post: detail.post),
          opaque: false);
      return true;
    } catch (_) {
      // 帖子已删除等异常场景 → 由调用方回退
      return false;
    }
  }

  /// 「查看详情」：营销落地链接走系统浏览器外链。
  Future<void> _openDestination(ColibriNotification n) async {
    final url = n.marketingDestinationUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// 渲染单条通知，对齐网页端 NotificationItem 布局：
  /// 头像 + 「加粗昵称 + 动作说明 + 引用的内容/评论预览 (+表情)」 + 时间 + 右侧内容预览图。
  Widget _buildItem(ColibriNotification n) {
    // 营销通知：专属富媒体卡片（Banner + 样式化标题 + 帖子迷你卡）
    if (n.isMarketing) {
      return _buildMarketingItem(n);
    }

    final content = n.entityContent;
    final previewImage = n.entityPreviewImage;
    const descStyle = TextStyle(
      fontSize: 14,
      color: cMainText,
      height: 1.35,
      fontWeight: FontWeight.w400,
    );

    final title = Text.rich(
      TextSpan(
        style: descStyle,
        children: [
          if (n.actorName.isNotEmpty)
            TextSpan(
              text: n.actorName,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: cMainText),
            ),
          TextSpan(text: n.actorName.isNotEmpty ? ' ${n.message}' : n.message),
          if (content.isNotEmpty)
            TextSpan(
                text: ' - "$content"',
                style: const TextStyle(color: cLightText)),
        ],
      ),
    );

    return InkWell(
      onTap: () => _handleTap(n),
      onLongPress: () => _confirmDelete(n),
      child: Container(
        // 未读通知：软绿底色突出
        color: n.isRead ? null : cPrimary.withValues(alpha: 0.07),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: cLightBg,
                  backgroundImage: n.actorAvatar != null
                      ? NetworkImage(n.actorAvatar!)
                      : null,
                  child: n.actorAvatar == null
                      ? const Icon(Icons.person_rounded, color: cLightIcon)
                      : null,
                ),
                if (!n.isRead)
                  const Positioned(
                    right: 0,
                    top: 0,
                    child: CircleAvatar(radius: 5.5, backgroundColor: cPrimary),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      title,
                      if (n.isReaction && n.reactionImage != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Image.network(
                            n.reactionImage!,
                            width: 18,
                            height: 18,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(n.timeAgo,
                      style: const TextStyle(fontSize: 12, color: cLightText)),
                ],
              ),
            ),
            if (previewImage != null && previewImage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    previewImage,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            // 关注请求：右侧展示 同意 / 拒绝 按钮
            if (_isPendingFollowRequest(n))
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _declineFollow(n),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: cLightBg,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text('拒绝',
                          style: TextStyle(
                              fontSize: 13,
                              color: cMainText,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _acceptFollow(n),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: cPrimary,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text('同意',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// 营销通知卡片：对齐 Web 端营销卡片设计。
  /// 系统头像 + 样式化标题 + 正文 + Banner 图 + 帖子迷你卡（可点进详情）+ 时间/查看详情。
  /// 整卡不可点击跳转（平台批量内容，不进「发送者主页」）。
  Widget _buildMarketingItem(ColibriNotification n) {
    final style = n.marketingStyle;
    final banner = n.marketingBannerImage;
    final posts = n.marketingPosts;
    final body = n.entityContent;

    // 标题样式映射（与 Web 端一致）：sm=13 / md=15 / lg=17；normal~bold → w400~w700
    const sizeMap = {'sm': 13.0, 'md': 15.0, 'lg': 17.0};
    const weightMap = {
      'normal': FontWeight.w400,
      'medium': FontWeight.w500,
      'semibold': FontWeight.w600,
      'bold': FontWeight.w700,
    };
    final titleSize = sizeMap[style['title_size']?.toString()] ?? 15.0;
    final titleWeight =
        weightMap[style['title_weight']?.toString()] ?? FontWeight.w600;

    return Container(
      // 未读通知：软主色底色突出
      color: n.isRead ? null : cPrimary.withValues(alpha: 0.07),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部：系统头像 + 样式化标题 + 未读点
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: cLightBg,
                    backgroundImage: n.actorAvatar != null
                        ? NetworkImage(n.actorAvatar!)
                        : null,
                    child: n.actorAvatar == null
                        ? const Icon(Icons.campaign_rounded, color: cLightIcon)
                        : null,
                  ),
                  if (!n.isRead)
                    const Positioned(
                      right: 0,
                      top: 0,
                      child:
                          CircleAvatar(radius: 5.5, backgroundColor: cPrimary),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    n.marketingTitle,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: titleWeight,
                      color: cMainText,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 正文（通知内容，保留换行）
          if (body.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 34),
              child: Text(
                body,
                style: const TextStyle(
                    fontSize: 14, color: cMainText, height: 1.45),
              ),
            ),

          // Banner 图（全宽圆角）
          if (banner != null)
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 34),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: Image.network(
                    banner,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

          // 关联站内帖子迷你卡（最多 3 条，点击进帖子详情）
          if (posts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 34),
              child: Column(
                children: [
                  for (final post in posts) ...[
                    _buildMarketingPostCard(post),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),

          // 底部行：时间 + 查看详情（外链）
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 34),
            child: Row(
              children: [
                Text(n.timeAgo,
                    style: const TextStyle(fontSize: 12, color: cLightText)),
                const Spacer(),
                if (n.marketingDestinationUrl != null)
                  GestureDetector(
                    onTap: () => _openDestination(n),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('查看详情',
                            style: TextStyle(
                                fontSize: 13,
                                color: cPrimary,
                                fontWeight: FontWeight.w600)),
                        SizedBox(width: 2),
                        Icon(Icons.open_in_new_rounded,
                            size: 14, color: cPrimary),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 帖子迷你卡：缩略图 + 摘要（两行截断）+ 作者与统计。点击跳帖子详情。
  Widget _buildMarketingPostCard(Map<String, dynamic> post) {
    final hashId = post['hash_id']?.toString();
    final cover = post['cover_url']?.toString();
    final excerpt = post['excerpt']?.toString() ?? '';
    final author = post['author_name']?.toString() ?? '';
    final reactions = post['reactions_count'];
    final comments = post['comments_count'];

    return GestureDetector(
      onTap: () => _openPost(hashId),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cLightBg.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (cover != null && cover.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  cover,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    excerpt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cMainText,
                        height: 1.3),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (author.isNotEmpty) author,
                      '$reactions 赞同',
                      '$comments 评论',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: cLightText),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: cLightText),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cWhite,
      appBar: AppBar(
        backgroundColor: cWhite,
        surfaceTintColor: cWhite,
        elevation: 0,
        title: const Text('通知',
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 17, color: cMainText)),
        leading: widget.asTab
            ? null
            : BackButton(color: cBlack, onPressed: () => Get.back()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: cPrimary))
          : RefreshIndicator(
              color: cPrimary,
              onRefresh: _load,
              child: _notifications.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        ColibriEmptyState(
                          icon: Icons.notifications_none_rounded,
                          title: '暂无通知',
                          subtitle: '有新动态时会在这里提醒你',
                          topSpacing: 90,
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: cLightBg),
                      itemBuilder: (context, index) =>
                          _buildItem(_notifications[index]),
                    ),
            ),
    );
  }
}

class _DeleteNotificationSheet extends StatelessWidget {
  final VoidCallback onConfirm;

  const _DeleteNotificationSheet({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cWhite,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '删除通知',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cMainText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '确定删除这条通知吗？',
              style: TextStyle(fontSize: 14, color: cLightText),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onConfirm();
                  },
                  child: const Text(
                    '删除',
                    style: TextStyle(color: Colors.red),
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

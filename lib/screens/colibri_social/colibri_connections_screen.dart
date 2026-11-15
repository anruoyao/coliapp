import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_social_service.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/colibri_social_models.dart';
import 'package:untitled/screens/colibri_social/colibri_profile_screen.dart';
import 'package:untitled/utilities/const.dart';

/// 粉丝 / 关注列表。
class ColibriConnectionsScreen extends StatefulWidget {
  final int userId;
  final String title;
  final bool following;

  const ColibriConnectionsScreen(
      {super.key,
      required this.userId,
      required this.title,
      required this.following});

  @override
  State<ColibriConnectionsScreen> createState() =>
      _ColibriConnectionsScreenState();
}

class _ColibriConnectionsScreenState extends State<ColibriConnectionsScreen> {
  /// 与服务端 `take(30)` 一致：返回不满一页即说明已到末尾。
  static const int _pageSize = 30;

  final List<ColibriPeople> _people = [];
  bool _loading = true;
  bool _loadingMore = false;
  int? _cursor;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ColibriSocialService.shared
          .fetchConnections(widget.userId, following: widget.following);
      setState(() {
        _people
          ..clear()
          ..addAll(list);
        _cursor = _nextCursor(list);
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 下一页游标 = 最后一条的「关注记录 id」（cursor_id），不是用户 id。
  /// 不满一页 / cursor_id 缺失时返回 null，停止继续加载，避免同一页无限重复。
  int? _nextCursor(List<ColibriPeople> list) {
    if (list.length < _pageSize) return null;
    return list.last.cursorId;
  }

  Future<void> _loadMore() async {
    if (_cursor == null || _loadingMore) return;
    _loadingMore = true;
    try {
      final list = await ColibriSocialService.shared.fetchConnections(
          widget.userId,
          following: widget.following,
          cursor: _cursor);
      if (!mounted) return;
      setState(() {
        _people.addAll(list);
        _cursor = _nextCursor(list);
      });
    } catch (_) {
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> _toggleFollow(ColibriPeople p) async {
    try {
      final result = await ColibriSocialService.shared.toggleFollow(p.id);
      if (result.requested) {
        showColibriToast(LKeys.socialFollowRequestSent.tr,
            message: LKeys.socialPendingApproval.tr,
            backgroundColor: cPrimary,
            colorText: Colors.white);
      }
      final following = result.following;
      setState(() {
        final idx = _people.indexWhere((x) => x.id == p.id);
        if (idx != -1) {
          _people[idx] = ColibriPeople(
            id: p.id,
            cursorId: p.cursorId,
            name: p.name,
            username: p.username,
            avatarUrl: p.avatarUrl,
            verified: p.verified,
            caption: p.caption,
            bio: p.bio,
            followersCount: p.followersCount,
            isFollowing: following,
            isOwner: p.isOwner,
          );
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cWhite,
      appBar: AppBar(
        backgroundColor: cWhite,
        elevation: 0,
        title: Text(widget.title,
            style:
                const TextStyle(fontWeight: FontWeight.bold, color: cMainText)),
        leading: BackButton(color: cBlack, onPressed: () => Get.back()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: cPrimary))
          : _people.isEmpty
              ? Center(
                  child: Text(LKeys.profileNoneYet.tr,
                      style: const TextStyle(color: cLightText)))
              : NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200)
                      _loadMore();
                    return false;
                  },
                  child: ListView.separated(
                    itemCount: _people.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: cLightBg),
                    itemBuilder: (context, index) {
                      final p = _people[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cLightBg,
                          backgroundImage: p.avatarUrl != null
                              ? NetworkImage(p.avatarUrl!)
                              : null,
                          child: p.avatarUrl == null
                              ? const Icon(Icons.person_rounded,
                                  color: cLightIcon)
                              : null,
                        ),
                        title: Row(
                          children: [
                            Flexible(
                                child: Text(p.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 15, color: cMainText))),
                            if (p.verified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded,
                                  color: cBlueTick, size: 16),
                            ],
                          ],
                        ),
                        subtitle: Text('@${p.username}',
                            style: const TextStyle(
                                fontSize: 12, color: cLightText)),
                        trailing: p.isOwner
                            ? null
                            : OutlinedButton(
                                onPressed: () => _toggleFollow(p),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor:
                                      p.isFollowing ? cLightBg : cPrimary,
                                  foregroundColor:
                                      p.isFollowing ? cMainText : Colors.white,
                                  side: BorderSide.none,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                ),
                                child: Text(
                                    p.isFollowing
                                        ? LKeys.socialFollowing.tr
                                        : LKeys.feedFollow.tr,
                                    style: const TextStyle(fontSize: 13)),
                              ),
                        onTap: () => Get.to(
                            () => ColibriProfileScreen(username: p.username),
                            opaque: false),
                      );
                    },
                  ),
                ),
    );
  }
}

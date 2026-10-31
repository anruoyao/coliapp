import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_social_service.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
import 'package:untitled/common/managers/haptic_manager.dart';
import 'package:untitled/common/widgets/colibri_ui.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/models/colibri_post_models.dart';
import 'package:untitled/models/colibri_social_models.dart';
import 'package:untitled/screens/colibri_feed/colibri_post_card.dart';
import 'package:untitled/screens/colibri_feed/colibri_post_detail_screen.dart';
import 'package:untitled/screens/colibri_social/colibri_profile_screen.dart';
import 'package:untitled/utilities/const.dart';

/// 搜索页：用户 / 帖子。
class ColibriSearchScreen extends StatefulWidget {
  const ColibriSearchScreen({super.key});

  @override
  State<ColibriSearchScreen> createState() => _ColibriSearchScreenState();
}

class _ColibriSearchScreenState extends State<ColibriSearchScreen> {
  final TextEditingController _query = TextEditingController();
  int _tab = 0; // 0 用户 1 帖子
  final List<ColibriPeople> _people = [];
  final List<ColibriPost> _posts = [];
  bool _loading = false;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    // 进入即加载推荐用户（explore/people 空查询 = 按粉丝量排序的推荐作者）
    _loadRecommendUsers();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendUsers() async {
    try {
      final list = await ColibriSocialService.shared.searchPeople(query: '');
      if (!mounted) return;
      setState(() {
        _people
          ..clear()
          ..addAll(list);
        _searched = true;
      });
    } catch (_) {}
  }

  Future<void> _search() async {
    final q = _query.text.trim();
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _searched = true;
    });
    try {
      if (_tab == 0) {
        final list = await ColibriSocialService.shared.searchPeople(query: q);
        setState(() => _people
          ..clear()
          ..addAll(list));
      } else {
        final list = await ColibriSocialService.shared.searchPosts();
        setState(() => _posts
          ..clear()
          ..addAll(list));
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow(ColibriPeople p) async {
    try {
      final result = await ColibriSocialService.shared.toggleFollow(p.id);
      // 关注/取消关注成功：与主页关注按钮一致的轻振动
      HapticManager.shared.light();
      if (result.requested) {
        showColibriToast('已发送关注请求',
            message: '等待对方批准',
            backgroundColor: cPrimary,
            colorText: Colors.white);
      }
      final following = result.following;
      setState(() {
        final idx = _people.indexWhere((x) => x.id == p.id);
        if (idx != -1) {
          _people[idx] = ColibriPeople(
            id: p.id,
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
        surfaceTintColor: cWhite,
        elevation: 0,
        title: _buildSearchField(),
        leading: BackButton(color: cBlack, onPressed: () => Get.back()),
      ),
      body: Column(
        children: [
          ColibriCapsuleTabs(
            labels: const ['用户', '帖子'],
            selectedIndex: _tab,
            onChanged: (i) {
              setState(() => _tab = i);
              if (_searched) _search();
            },
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: cPrimary))
                : !_searched
                    ? const ColibriEmptyState(
                        icon: Icons.search_rounded,
                        title: '输入关键词搜索',
                        subtitle: '查找用户或感兴趣的帖子',
                        topSpacing: 60,
                      )
                    : _tab == 0
                        ? (_people.isEmpty
                            ? const ColibriEmptyState(
                                icon: Icons.person_search_rounded,
                                title: '没有找到用户',
                                subtitle: '换个关键词试试',
                                topSpacing: 60,
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.only(top: 6, bottom: 24),
                                itemCount: _people.length,
                                itemBuilder: (context, index) {
                                  final p = _people[index];
                                  return _UserTile(
                                    person: p,
                                    onFollow: () => _toggleFollow(p),
                                    onTap: () => Get.to(
                                        () => ColibriProfileScreen(
                                            username: p.username),
                                        opaque: false),
                                  );
                                },
                              ))
                        : (_posts.isEmpty
                            ? const ColibriEmptyState(
                                icon: Icons.travel_explore_rounded,
                                title: '没有找到帖子',
                                subtitle: '换个关键词试试',
                                topSpacing: 60,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 24),
                                itemCount: _posts.length,
                                itemBuilder: (context, index) {
                                  final p = _posts[index];
                                  return ColibriPostCard(
                                    key: ValueKey('search_${p.id}'),
                                    post: p,
                                    onTap: () => Get.to(
                                        () => ColibriPostDetailScreen(post: p),
                                        opaque: false),
                                  );
                                },
                              )),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _query,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _search(),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: '搜索用户或帖子',
        hintStyle: const TextStyle(color: cLightText, fontSize: 15),
        isDense: true,
        prefixIcon:
            const Icon(Icons.search_rounded, color: cLightIcon, size: 22),
        suffixIcon: _query.text.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  _query.clear();
                  setState(() {});
                },
                child: const Icon(Icons.cancel_rounded,
                    color: cLightIcon, size: 19),
              )
            : null,
        filled: true,
        fillColor: cLightBg,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: cPrimary, width: 1.4),
        ),
      ),
    );
  }
}

/// 用户搜索结果行：头像 + 名字/认证 + @handle + 关注胶囊按钮。
class _UserTile extends StatelessWidget {
  final ColibriPeople person;
  final VoidCallback onFollow;
  final VoidCallback onTap;

  const _UserTile(
      {required this.person, required this.onFollow, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Row(
          children: [
            MyCachedProfileImage(
              imageUrl: person.avatarUrl,
              width: 48,
              height: 48,
              fullName: person.name,
              cornerRadius: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(person.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: cMainText)),
                      ),
                      if (person.verified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded,
                            color: cBlueTick, size: 16),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('@${person.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 12.5, color: cLightText)),
                ],
              ),
            ),
            if (!person.isOwner) ...[
              const SizedBox(width: 10),
              ColibriPillButton(
                text: person.isFollowing ? '已关注' : '关注',
                filled: !person.isFollowing,
                height: 34,
                radius: 12,
                minWidth: 84,
                onTap: onFollow,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

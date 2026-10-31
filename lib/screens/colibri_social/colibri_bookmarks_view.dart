import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/managers/bookmark_store.dart';
import 'package:untitled/common/widgets/colibri_ui.dart';
import 'package:untitled/common/widgets/colibri_skeleton.dart';
import 'package:untitled/screens/colibri_feed/colibri_post_card.dart';
import 'package:untitled/screens/colibri_feed/colibri_post_detail_screen.dart';
import 'package:untitled/utilities/const.dart';

/// 个人页「收藏」标签内容：已收藏帖子列表。
///
/// 状态全部来自全局 [BookmarkStore]（唯一真相）：
/// - 书签图标/取消收藏由 store.ids 驱动，与 Feed 卡片全局同步，无需手动刷新；
/// - 每张卡片带 ValueKey(post.id)：插入/移除时 State 与帖子严格绑定，不重复不乱序；
/// - 下拉刷新 = 与服务端对齐；上拉加载更多 = 本地分页（服务端一次返回全量 ≤300）。
class ColibriBookmarksView extends StatefulWidget {
  const ColibriBookmarksView({super.key});

  @override
  State<ColibriBookmarksView> createState() => _ColibriBookmarksViewState();
}

class _ColibriBookmarksViewState extends State<ColibriBookmarksView> {
  final BookmarkStore _store = BookmarkStore.i;

  @override
  void initState() {
    super.initState();
    // 可见时确保至少同步过一次（缓存秒开 + 后台对齐）
    WidgetsBinding.instance.addPostFrameCallback((_) => _store.onEnterHome());
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 无缓存、首次加载：全屏加载圈
      if (_store.loading.value && _store.posts.isEmpty) {
        return ColibriSkeletonPosts(onRefresh: _store.pullRefresh);
      }
      // 空状态（保留下拉刷新能力）
      if (_store.posts.isEmpty) {
        return RefreshIndicator(
          color: cPrimary,
          onRefresh: _store.pullRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              ColibriEmptyState(
                icon: Icons.bookmark_border_rounded,
                title: '还没有收藏的帖子',
                subtitle: '看到喜欢的帖子，点卡片右下角的书签按钮即可收藏到这里',
              ),
            ],
          ),
        );
      }

      final visible = _store.visiblePosts;
      return NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200)
            _store.loadMore();
          return false;
        },
        child: RefreshIndicator(
          color: cPrimary,
          onRefresh: _store.pullRefresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 6, bottom: 24),
            itemCount: visible.length + (_store.hasMore ? 1 : 0),
            separatorBuilder: (context, index) {
              if (index < visible.length - 1) {
                return const Divider(
                  height: 1,
                  thickness: 1,
                  color: cLightBg,
                );
              }
              return const SizedBox.shrink();
            },
            itemBuilder: (context, index) {
              if (index >= visible.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: cPrimary, strokeWidth: 2.4),
                    ),
                  ),
                );
              }
              final p = visible[index];
              return ColibriPostCard(
                key: ValueKey('bookmark_${p.id}'),
                post: p,
                // 取消收藏后卡片由 store 自动从列表移除，这里无需手动处理
                onTap: () => Get.to(() => ColibriPostDetailScreen(post: p),
                    opaque: false),
              );
            },
          ),
        ),
      );
    });
  }
}

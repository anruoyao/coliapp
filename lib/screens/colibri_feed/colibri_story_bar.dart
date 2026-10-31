import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled/common/api_service/colibri_story_service.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
import 'package:untitled/common/api_service/colibri_api.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/managers/upload_limits_service.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/models/colibri_story_models.dart';
import 'package:untitled/screens/colibri_feed/colibri_story_composer_screen.dart';
import 'package:untitled/screens/colibri_feed/colibri_story_viewer_screen.dart';
import 'package:untitled/utilities/const.dart';

/// 故事条（Feed 顶部横滑）：我的发布入口 / 好友故事（未看渐变环）。
class ColibriStoryBar extends StatefulWidget {
  const ColibriStoryBar({super.key});

  @override
  State<ColibriStoryBar> createState() => _ColibriStoryBarState();
}

class _ColibriStoryBarState extends State<ColibriStoryBar> {
  List<ColibriStoryFeed> _stories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    SessionManager.shared
        .refreshColibriUser(ColibriApi.shared.fetchBootstrapUser)
        .catchError((_) {});
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ColibriStoryService.shared.fetchFeed();
      setState(() => _stories = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openStory(ColibriStoryFeed item) async {
    try {
      final stories =
          await ColibriStoryService.shared.fetchStories(item.storyUuid);
      if (stories.isEmpty) return;
      final idx = stories.indexWhere((s) => s.storyUuid == item.storyUuid);
      await Get.to(
          () => StoryViewerScreen(
              stories: stories, initialIndex: idx < 0 ? 0 : idx),
          opaque: false);
      _load();
    } catch (_) {}
  }

  /// 发布流程：选图 → 编辑页（加文字）→ 发布。
  Future<void> _createStory() async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;

    // 本地预检测：超出后台配置的图片大小限制时立即提示
    final msg = await UploadLimitsService.shared
        .check(File(file.path).lengthSync(), 'image');
    if (msg != null) {
      showColibriToast('图片过大',
          message: msg, backgroundColor: cRed, colorText: Colors.white);
      return;
    }

    final published = await Get.to<bool>(
        () => ColibriStoryComposerScreen(imagePath: file.path),
        opaque: false);
    if (published == true) {
      showColibriToast('已发布',
          message: '故事发布成功', backgroundColor: cGreen, colorText: Colors.white);
      _load();
    }
  }

  String? get _myAvatar {
    return SessionManager.shared.colibriUserRx['avatar_url']?.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      // 加载骨架：一排灰色圆占位
      return SizedBox(
        height: 102,
        child: Row(
          children: List.generate(
              4,
              (i) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: CircleAvatar(radius: 29, backgroundColor: cLightBg),
                  )),
        ),
      );
    }
    return SizedBox(
      height: 102,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          // 我的：发布入口（头像 + 绿色加号徽章）
          Obx(() => _StoryItem(
                label: '我的故事',
                avatarUrl: _myAvatar,
                isAdd: true,
                onTap: _createStory,
              )),
          ..._stories.map((s) => _StoryItem(
                label: s.userName,
                avatarUrl: s.avatarUrl,
                seen: s.isSeen,
                onTap: () => _openStory(s),
              )),
        ],
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  final String label;
  final String? avatarUrl;
  final bool seen;
  final bool isAdd;
  final VoidCallback onTap;

  const _StoryItem(
      {required this.label,
      this.avatarUrl,
      this.seen = false,
      this.isAdd = false,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 头像 + 环
                  Container(
                    width: 64,
                    height: 64,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isAdd
                          ? null
                          : seen
                              ? null
                              : const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [cGradientGreen1, cGradientGreen2],
                                ),
                      color: isAdd ? cPrimarySoft : (seen ? cLightBg : null),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: cWhite),
                      padding: const EdgeInsets.all(2),
                      child: ClipOval(
                        child: MyCachedProfileImage(
                          imageUrl: avatarUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fullName: label,
                          cornerRadius: 60,
                        ),
                      ),
                    ),
                  ),
                  // 发布入口：绿色加号徽章
                  if (isAdd)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: cPrimary,
                          shape: BoxShape.circle,
                          border: Border.all(color: cWhite, width: 2.2),
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: cBlack, size: 15),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            SizedBox(
              height: 14,
              width: 66,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isAdd
                      ? FontWeight.w700
                      : (seen ? FontWeight.w500 : FontWeight.w600),
                  color: isAdd ? cGreen : (seen ? cLightText : cMainText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/reel_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/logger.dart';
import 'package:untitled/common/managers/my_debouncer.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/enums/reel_page_type.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/reel_comments_model.dart';
import 'package:untitled/models/reel_model.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/screens/reels_screen/reel/reel_page_controller.dart';
import 'package:video_player/video_player.dart';

class ReelsScreenController extends BaseController {
  RxMap<int, ReelPlayerEntry> players = <int, ReelPlayerEntry>{}.obs;

  RxList<Reel> reels = <Reel>[].obs;
  RxInt position = 0.obs;

  String? hashtag;
  User? user;
  ReelPageType reelPageType;

  PageController pageController = PageController();
  Future<void> Function()? onFetchMoreData;
  Future<void> Function()? onRefresh;

  TextEditingController commentTextController = TextEditingController();

  /// 正在发布评论（防重复提交）
  bool isSendingComment = false;

  ReelsScreenController({
    required this.reels,
    required this.position,
    this.user,
    this.hashtag,
    required this.reelPageType,
    required this.onFetchMoreData,
    required this.onRefresh,
  });

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: position.value);
  }

  @override
  void onClose() {
    super.onClose();
    disposeAllController();
  }

  Future<void> _fetchMoreData() async {
    if (position >= reels.length - 3) {
      Future.delayed(Duration(seconds: 1), () async {
        await onFetchMoreData?.call().then((value) {
          _initializeControllerAtIndex(position.value + 1);
        });
      });
    }
  }

  void pauseAllPlayers() {
    final keys = players.keys.toList(); // 👈 COPY
    for (var i in keys) {
      _stopControllerAtIndex(i);
    }
  }

  void initVideoPlayer() async {
    /// Initialize 1st video
    await _initializeControllerAtIndex(position.value);

    /// Play 1st video
    _playControllerAtIndex(position.value);

    /// Initialize 2nd vide
    if (position >= 0) {
      await _initializeControllerAtIndex(position.value - 1);
    }
    await _initializeControllerAtIndex(position.value + 1);
  }

  void _playNextReel(int index) {
    pauseAllPlayers();
    _initializeControllerAtIndex(index);
    _initializeControllerAtIndex(index + 1);
    _initializeControllerAtIndex(index - 1);

    _disposeAllExcept(index);
  }

  void _playPreviousReel(int index) {
    pauseAllPlayers();
    _initializeControllerAtIndex(index);
    _initializeControllerAtIndex(index + 1);
    _initializeControllerAtIndex(index - 1);

    _disposeAllExcept(index);
  }

  void _disposeAllExcept(int index) {
    final validIndexes = {index - 1, index, index + 1};

    final keys = players.keys.toList(); // 👈 COPY

    for (final i in keys) {
      if (!validIndexes.contains(i)) {
        _disposeControllerAtIndex(i);
        players.remove(i);
      }
    }
  }

  Future<void> _initializeControllerAtIndex(int index) async {
    if (index < 0 || index >= reels.length) return;

    /// 🔒 HARD GUARD (no race possible)
    if (players[index]?.status == PlayerStatus.initializing ||
        players[index]?.status == PlayerStatus.initialized) {
      return;
    }

    /// 🔒 Mark initializing IMMEDIATELY
    players[index] = ReelPlayerEntry(status: PlayerStatus.initializing);

    try {
      late VideoPlayerController controller;

      final reel = reels[index];
      if (reel.id == -1) {
        controller = VideoPlayerController.file(
          File(reel.content ?? ''),
        );
      } else {
        controller = VideoPlayerController.networkUrl(
          Uri.parse(reel.content ?? ''),
        );
      }

      await controller.initialize();
      controller.setLooping(true);

      players[index] = ReelPlayerEntry(
        controller: controller,
        status: PlayerStatus.initialized,
      );

      Loggers.info("🚀 INITIALIZED $index");

      if (index == position.value) {
        _playControllerAtIndex(index);
      }
    } catch (e) {
      Loggers.error("❌ INIT FAILED $index $e");

      _disposeControllerAtIndex(index);
    }
  }

  void _playControllerAtIndex(int index) {
    final entry = players[index];
    final controller = entry?.controller;

    if (controller == null) return;
    if (!controller.value.isInitialized) return;

    controller.play();

    MyDebouncer.shared.run(milliseconds: 3000, () {
      _increaseViewsCount(reels[index]);
    });
    Loggers.info('🚀🚀🚀 PLAYING $index');
  }

  void _increaseViewsCount(Reel? reel) async {
    int reelId = reel?.id?.toInt() ?? -1;
    if (reel == null) {
      return Loggers.error('Post not found');
    }
    if (reelId == -1) {
      return;
    }

    bool status = await ReelService.shared.increaseViewCount(reelId: reelId);
    if (status) {
      reel.viewsCount = (reel.viewsCount ?? 0) + 1;
      reels[reels.indexWhere((element) => element.id == reelId)].viewsCount =
          reel.viewsCount;
    }
  }

  void _stopControllerAtIndex(int index) {
    if (reels.length > index && index >= 0) {
      final controller = players[index]?.controller;
      if (controller != null) {
        controller.pause();
        controller.seekTo(const Duration()); // Reset position
        Loggers.info('🚀🚀🚀 STOPPED $index');
      }
    }
  }

  void _disposeControllerAtIndex(int index) {
    ReelPlayerEntry? entry = players[index];
    if (entry == null) return;
    if (entry.status == PlayerStatus.disposed ||
        entry.status == PlayerStatus.none) return;

    final controller = entry.controller;

    if (controller != null) {
      if (entry.listener != null) {
        controller.removeListener(entry.listener!);
      }
      controller.pause();
      controller.dispose();
    }

    entry.controller = null;
    entry.listener = null;
    entry.status = PlayerStatus.disposed;
    players[index] = entry;

    Loggers.info("🗑 DISPOSED $index");
  }

  Future<void> disposeAllController() async {
    final entries = players.entries.toList(); // 👈 COPY

    for (var entry in entries) {
      final controller = entry.value.controller;
      final listener = entry.value.listener;

      if (listener != null) {
        controller?.removeListener(listener);
      }

      controller?.pause();
      await controller?.dispose();
    }

    players.clear();
  }

  void onPageChanged(int index) {
    if (index > position.value) {
      _fetchMoreData();

      _playNextReel(index);
    } else {
      _playPreviousReel(index);
    }
    position.value = index;

    _playControllerAtIndex(index);
  }

  void updatePageController(bool reset) {
    if (reset) {
      if (pageController.hasClients) {
        pageController.jumpToPage(0); // Reset to first page
      } else {
        pageController = PageController(initialPage: 0);
      }
    }
  }

  void addComment() async {
    // 防止重复提交：发送中直接忽略点击
    if (isSendingComment) return;
    if (commentTextController.text.trim().isEmpty) return;
    Reel reel = reels[position.value];
    if (Get.isRegistered<ReelController>(tag: reel.id?.toString() ?? '')) {
      var reelController =
          Get.find<ReelController>(tag: reel.id?.toString() ?? '');

      isSendingComment = true;
      try {
        var text = commentTextController.text.trim();
        ReelComment? comment;
        try {
          comment = await ReelService.shared
              .addComment(comment: text, reelId: reel.id ?? 0);
        } catch (_) {
          comment = null;
        }

        // 响应可能在传输中丢失（服务端其实已写入）：拉取最新评论对账
        comment ??= await confirmCommentPosted(reel.id ?? 0, text);

        if (comment != null) {
          commentTextController.clear();
          reelController.reel.update((val) {
            val?.commentsCount =
                (reelController.reel.value?.commentsCount ?? 0) + 1;
          });
        } else {
          showSnackBar(LKeys.someThingWentWrong.tr, type: SnackBarType.error);
        }
      } finally {
        isSendingComment = false;
      }
    }
  }

  /// 对账：在服务端最新一页评论中查找"我发的、内容一致"的评论，确认发布是否已生效
  Future<ReelComment?> confirmCommentPosted(num reelId, String text) async {
    try {
      var latest =
          await ReelService.shared.fetchComments(reelId: reelId, start: 0);
      var myUserId = SessionManager.shared.getUserID();
      for (var c in latest) {
        if (c.userId == myUserId && (c.description ?? '') == text) {
          return c;
        }
      }
    } catch (_) {}
    return null;
  }

  void onRefreshPage() async {
    await onRefresh?.call();
    position.value = 0;
    await disposeAllController();
    initVideoPlayer();
  }
}

class ReelPlayerEntry {
  VideoPlayerController? controller;
  VoidCallback? listener;
  PlayerStatus status;

  ReelPlayerEntry(
      {this.controller, this.listener, this.status = PlayerStatus.none});
}

enum PlayerStatus { none, initializing, initialized, disposed }

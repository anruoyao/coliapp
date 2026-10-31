import 'package:flutter/cupertino.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/moderator_service.dart';
import 'package:untitled/common/api_service/reel_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/reel_comments_model.dart';
import 'package:untitled/models/reel_model.dart';
import 'package:untitled/screens/reels_screen/reel/reel_page_controller.dart';
import 'package:untitled/screens/sheets/confirmation_sheet.dart';
import 'package:untitled/utilities/const.dart';

class ReelCommentController extends BaseController {
  final ReelController reelController;
  RxList<ReelComment> comments = RxList();
  TextEditingController textEditingController = TextEditingController();

  /// 正在发布评论（用于发送按钮 loading + 防重复提交）
  RxBool isSendingComment = false.obs;

  /// 正在拉取评论（防止并发请求叠加 loading 弹窗）
  bool isFetchingComments = false;

  ReelCommentController(this.reelController);

  Reel? get reel => reelController.reel.value;

  @override
  void onReady() {
    fetchComments();
    super.onReady();
  }

  Future<void> fetchComments() async {
    if (isFetchingComments) {
      return;
    }
    isFetchingComments = true;
    if (comments.isEmpty) {
      startLoading();
    }
    try {
      comments.addAll(await ReelService.shared
          .fetchComments(reelId: reel?.id ?? 0, start: comments.length));
    } finally {
      stopLoading();
      isFetchingComments = false;
    }
  }

  Future<void> addComment() async {
    // 防止重复提交：发送中直接忽略点击
    if (isSendingComment.value) {
      return;
    }
    var text = textEditingController.text.trim();
    if (text.isEmpty) {
      return;
    }
    isSendingComment.value = true;

    ReelComment? comment;
    try {
      comment = await ReelService.shared
          .addComment(comment: text, reelId: reel?.id ?? 0);
    } catch (_) {
      comment = null;
    }

    // 响应可能在传输中丢失（服务端其实已写入）：拉取最新评论对账
    comment ??= await findJustPostedComment(text);

    isSendingComment.value = false;

    if (comment != null) {
      comment.user = SessionManager.shared.getUser();
      comments.insert(0, comment);
      textEditingController.clear();
      reelController.reel.update((val) {
        val?.commentsCount =
            (reelController.reel.value?.commentsCount ?? 0) + 1;
      });
    } else {
      showSnackBar(LKeys.someThingWentWrong.tr, type: SnackBarType.error);
    }
  }

  /// 对账：在服务端最新一页评论中查找刚发布的评论（列表按新到旧排序，取首个匹配即最新）
  Future<ReelComment?> findJustPostedComment(String text) async {
    try {
      var latest = await ReelService.shared
          .fetchComments(reelId: reel?.id ?? 0, start: 0);
      var myUserId = SessionManager.shared.getUserID();
      var localIds = comments.map((e) => e.id).toSet();
      for (var c in latest) {
        if (c.userId == myUserId &&
            (c.description ?? '') == text &&
            !localIds.contains(c.id)) {
          return c;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> deleteComment(ReelComment comment) async {
    bool success = false;
    try {
      success = await ReelService.shared.deleteComment(comment.id ?? 0);
    } catch (_) {
      success = false;
    }

    // 响应可能在传输中丢失（服务端其实已删除）：对账确认
    if (!success) {
      success = !(await commentStillOnServer(comment.id ?? 0));
    }

    if (success) {
      comments.removeWhere((element) => element.id == comment.id);
      reelController.reel.update((val) {
        val?.commentsCount =
            (reelController.reel.value?.commentsCount ?? 0) - 1;
      });
    } else {
      showSnackBar(LKeys.someThingWentWrong.tr, type: SnackBarType.error);
    }
  }

  /// 对账：翻页拉取评论，确认指定评论是否仍存在于服务端
  Future<bool> commentStillOnServer(num commentId) async {
    try {
      int start = 0;
      int checked = 0;
      // 只需覆盖"本地已加载的 + 一页"的范围（用户只能删除看到的评论）
      int target = comments.length + Limits.pagination;
      while (checked < target) {
        var page = await ReelService.shared
            .fetchComments(reelId: reel?.id ?? 0, start: start);
        if (page.isEmpty) {
          return false;
        }
        if (page.any((c) => c.id == commentId)) {
          return true;
        }
        checked += page.length;
        start += page.length;
      }
      return true; // 没翻完，保守处理为"仍存在"
    } catch (_) {
      return true; // 查询失败，保守处理为"仍存在"
    }
  }

  void deleteCommentByModerator(ReelComment comment) {
    showColibriBottomSheet(ConfirmationSheet(
      desc: LKeys.deleteCommentDisc,
      buttonTitle: LKeys.delete,
      onTap: () {
        stopLoading();
        ModeratorService.shared
            .deleteReelComment(commentId: comment.id?.toInt() ?? 0);
        comments.removeWhere((element) => element.id == comment.id);
        reelController.reel.value?.commentsCount =
            (reelController.reel.value?.commentsCount ?? 0) - 1;
        reelController.update(['comment']);
        update();
      },
    ));
  }
}

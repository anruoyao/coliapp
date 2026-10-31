import 'package:flutter/cupertino.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/moderator_service.dart';
import 'package:untitled/common/api_service/post_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/comments_model.dart';
import 'package:untitled/models/posts_model.dart';
import 'package:untitled/screens/post/post_controller.dart';
import 'package:untitled/screens/sheets/confirmation_sheet.dart';
import 'package:untitled/utilities/const.dart';

class CommentController extends BaseController {
  final Post post;
  final PostController postController;
  List<Comment> comments = [];
  TextEditingController textEditingController = TextEditingController();

  /// 正在发布评论（用于发送按钮 loading + 防重复提交）
  /// 使用 RxBool 以便 Obx 自动响应，不依赖 GetBuilder 的 update() 刷新
  RxBool isSendingComment = false.obs;

  /// 正在拉取评论（防止并发请求叠加 loading 弹窗）
  bool isFetchingComments = false;

  CommentController(this.post, this.postController);

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
      await PostService.shared.fetchComments(post.id ?? 0, comments.length,
          (comments) {
        stopLoading();
        this.comments.addAll(comments);
        update();
      });
    } catch (_) {
      stopLoading();
    } finally {
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

    Comment? comment = await PostService.shared.addComment(text, post.id ?? 0);

    // 响应可能在传输中丢失（服务端其实已写入）：拉取最新评论对账，
    // 找到"我发的、内容一致、本地列表还没有的"评论则视为发布成功
    comment ??= await findJustPostedComment(text);

    isSendingComment.value = false;
    if (comment != null) {
      comment.user = SessionManager.shared.getUser();
      comments.insert(0, comment);
      textEditingController.clear();
      postController.post.commentsCount += 1;
      postController.update(['comment']);
      postController.update();
      update();
    } else {
      showSnackBar(LKeys.someThingWentWrong.tr, type: SnackBarType.error);
    }
  }

  /// 对账：在服务端最新一页评论中查找刚发布的评论（列表按新到旧排序，取首个匹配即最新）
  Future<Comment?> findJustPostedComment(String text) async {
    try {
      var latest = await PostService.shared.fetchCommentsPage(post.id ?? 0, 0);
      var myUserId = SessionManager.shared.getUserID();
      var localIds = comments.map((e) => e.id).toSet();
      for (var c in latest) {
        if (c.userId == myUserId &&
            (c.desc ?? '') == text &&
            !localIds.contains(c.id)) {
          return c;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> deleteComment(Comment comment) async {
    bool success = await PostService.shared.deleteComment(comment.id ?? 0);

    // 响应可能在传输中丢失（服务端其实已删除）：对账确认
    if (!success) {
      success = !(await commentStillOnServer(comment.id ?? 0));
    }

    if (success) {
      comments.removeWhere((element) => element.id == comment.id);
      postController.post.commentsCount = postController.post.commentsCount > 0
          ? postController.post.commentsCount - 1
          : 0;
      postController.update(['comment']);
      update();
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
        var page =
            await PostService.shared.fetchCommentsPage(post.id ?? 0, start);
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

  void deleteCommentByModerator(Comment comment) {
    showColibriBottomSheet(ConfirmationSheet(
      desc: LKeys.deleteCommentDisc,
      buttonTitle: LKeys.delete,
      onTap: () {
        stopLoading();
        ModeratorService.shared.deleteComment(
            commentId: comment.id?.toInt() ?? 0,
            completion: () {
              stopLoading();
              comments.removeWhere((element) => element.id == comment.id);
              postController.post.commentsCount -= 1;
              postController.update(['comment']);
              update();
            });
      },
    ));
  }

  void likeDislikeComment(Comment comment) {
    // startLoading();
    var index = comments.indexWhere(
      (element) => element.id == comment.id,
    );
    print(comments.map(
      (e) => e.toJson(),
    ));
    print(comment.isLike);
    comments[index].isLike = comment.isLike == 1 ? 0 : 1;
    comments[index].commentLikeCount = comment.isLike == 1
        ? (comments[index].commentLikeCount ?? 0) + 1
        : (comments[index].commentLikeCount ?? 0) - 1;
    update();
    PostService.shared.likeDislike(comment.id ?? 0, (_) {
      // stopLoading();
    });
  }
}

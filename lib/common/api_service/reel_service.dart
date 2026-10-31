import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/common_response.dart';
import 'package:untitled/models/reel_comment_model.dart';
import 'package:untitled/models/reel_comments_model.dart';
import 'package:untitled/models/reel_model.dart';
import 'package:untitled/models/reels_model.dart';
import 'package:untitled/utilities/const.dart';
import 'package:untitled/utilities/params.dart';
import 'package:untitled/utilities/web_service.dart';

import 'new_api_service.dart';

class ReelService {
  static var shared = ReelService();

  Future<Reel?> uploadReel({
    required String description,
    required XFile content,
    required XFile thumbnail,
    required String hashtags,
    required String interestIds,
    required int? musicId,
  }) async {
    ReelModel model = await NewApiService.shared.multiPartCallApi(
      filesMap: {
        Param.content: [content],
        Param.thumbnail: [thumbnail],
      },
      url: WebService.uploadReel,
      param: {
        Param.userId: SessionManager.shared.getUserID(),
        Param.description: description,
        Param.interestIds: interestIds,
        Param.hashtags: hashtags,
        Param.musicId: musicId,
      },
      fromJson: ReelModel.fromJson,
    );

    if (model.status == false) {
      BaseController.share.showSnackBar(model.message ?? '');
    }
    return model.data;
  }

  Future<List<Reel>> fetchExploreReels({
    required int start,
    required int type,
  }) async {
    ReelsModel model = await NewApiService.shared.call(
        url: WebService.fetchReelsOnExplore,
        param: {
          Param.myUserId: SessionManager.shared.getUserID(),
          Param.start: start,
          Param.limit: Limits.pagination,
          Param.type: type,
        },
        fromJson: ReelsModel.fromJson);
    return model.data ?? [];
  }

  Future<List<Reel>> searchReels(
      {required int start, required String keyword, num? interestId}) async {
    ReelsModel model = await NewApiService.shared.call(
        url: WebService.searchReelsByInterestId,
        param: {
          Param.interestId: interestId,
          Param.userId: SessionManager.shared.getUserID(),
          Param.start: start,
          Param.limit: Limits.pagination,
          Param.keyword: keyword,
        },
        fromJson: ReelsModel.fromJson);
    return model.data ?? [];
  }

  Future<Reel?> likeDislikeReel({required int reelId}) async {
    ReelModel model = await NewApiService.shared.call(
        url: WebService.likeDislikeReel,
        param: {
          Param.userId: SessionManager.shared.getUserID(),
          Param.reelId: reelId,
        },
        fromJson: ReelModel.fromJson);
    return model.data;
  }

  Future<ReelComment?> addComment(
      {required String comment, required num reelId}) async {
    var params = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.description: comment,
      Param.reelId: reelId,
    };
    ReelCommentModel model = await NewApiService.shared.call(
      url: WebService.addReelComment,
      param: params,
      fromJson: ReelCommentModel.fromJson,
    );

    return model.data;
  }

  Future<List<ReelComment>> fetchComments(
      {required num reelId, required int start}) async {
    var params = {
      Param.start: start,
      Param.reelId: reelId,
      Param.limit: Limits.pagination,
      Param.userId: SessionManager.shared.getUserID(),
    };
    ReelCommentsModel model = await NewApiService.shared.call(
      url: WebService.fetchReelComments,
      param: params,
      fromJson: ReelCommentsModel.fromJson,
    );
    return model.data ?? [];
  }

  Future<bool> deleteComment(num commentId) async {
    var params = {
      Param.myUserId: SessionManager.shared.getUserID(),
      Param.commentId: commentId,
    };
    CommonResponse model = await NewApiService.shared.call(
        url: WebService.deleteReelComment,
        param: params,
        fromJson: CommonResponse.fromJson);
    return model.status ?? false;
  }

  Future<List<Reel>> fetchReelsByHashtag(String tag, int start) async {
    var param = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.start: start,
      Param.tag: tag,
      Param.limit: Limits.pagination,
    };
    ReelsModel model = await NewApiService.shared.call(
        param: param,
        url: WebService.fetchReelsByHashtag,
        fromJson: ReelsModel.fromJson);

    return model.data ?? [];
  }

  Future<List<Reel>> fetchReelsByMusic(
      {required int musicId, required int start}) async {
    var param = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.start: start,
      Param.musicId: musicId,
      Param.limit: Limits.pagination,
    };
    ReelsModel model = await NewApiService.shared.call(
      param: param,
      url: WebService.fetchReelsByMusic,
      fromJson: ReelsModel.fromJson,
    );

    return model.data ?? [];
  }

  Future<bool> increaseViewCount({required num reelId}) async {
    var param = {Param.reelId: reelId};
    CommonResponse obj = await NewApiService.shared.call(
      url: WebService.increaseReelViewCount,
      param: param,
      fromJson: CommonResponse.fromJson,
    );

    return obj.status ?? false;
  }

  Future<bool> deleteReel({required num reelId}) async {
    var param = {
      Param.reelId: reelId,
      Param.userId: SessionManager.shared.getUserID(),
    };
    CommonResponse obj = await NewApiService.shared.call(
      url: WebService.deleteReel,
      param: param,
      fromJson: CommonResponse.fromJson,
    );

    return obj.status ?? false;
  }

  Future<void> reportReel(
      {required num reelId,
      required String reason,
      required String desc}) async {
    var param = {Param.reelId: reelId, Param.reason: reason, Param.desc: desc};
    CommonResponse obj = await NewApiService.shared.call(
      url: WebService.reportReel,
      param: param,
      fromJson: CommonResponse.fromJson,
    );

    if (obj.status == true) {
      Get.back();
      Get.back();
      BaseController.share.showSnackBar(LKeys.reportAddedSuccessfully.tr,
          type: SnackBarType.success);
    }
  }

  Future<List<Reel>> fetchReelsByUser(
      {required num userId, required int start}) async {
    var param = {
      Param.myUserId: SessionManager.shared.getUserID(),
      Param.userId: userId,
      Param.start: start,
      Param.limit: Limits.pagination,
    };
    ReelsModel model = await NewApiService.shared.call(
      param: param,
      url: WebService.fetchReelsByUserId,
      fromJson: ReelsModel.fromJson,
    );

    return model.data ?? [];
  }

  Future<List<Reel>> fetchSavedReels({required int start}) async {
    var param = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.start: start,
      Param.limit: Limits.pagination,
    };
    ReelsModel model = await NewApiService.shared.call(
      param: param,
      url: WebService.fetchSavedReels,
      fromJson: ReelsModel.fromJson,
    );

    return model.data ?? [];
  }

  Future<Reel?> fetchReelById({required num reelId}) async {
    var param = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.reelId: reelId,
    };
    ReelModel model = await NewApiService.shared.call(
      param: param,
      url: WebService.fetchReelById,
      fromJson: ReelModel.fromJson,
    );

    return model.data;
  }
}

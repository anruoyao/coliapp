import 'package:untitled/common/api_service/new_api_service.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/models/common_response.dart';
import 'package:untitled/utilities/params.dart';
import 'package:untitled/utilities/web_service.dart';

import 'api_service.dart';

class ModeratorService {
  static var shared = ModeratorService();

  void deletePost({required int postID, required Function() completion}) {
    var param = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.postId: postID.toString(),
    };

    ApiService.shared.call(
      param: param,
      url: WebService.moderator.deletePostByModerator,
      completion: (p0) {
        var response = CommonResponse.fromJson(p0);
        if (response.status == true) {
          completion();
        }
      },
    );
  }

  void blockUser({required int userId, required Function() completion}) {
    var param = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.toUserId: userId.toString(),
    };

    ApiService.shared.call(
      param: param,
      url: WebService.moderator.userBlockByModerator,
      completion: (p0) {
        var response = CommonResponse.fromJson(p0);
        if (response.status == true) {
          completion();
        }
      },
    );
  }

  void deleteComment({required int commentId, required Function() completion}) {
    var param = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.commentId: commentId.toString(),
    };

    ApiService.shared.call(
      param: param,
      url: WebService.moderator.deleteCommentByModerator,
      completion: (p0) {
        var response = CommonResponse.fromJson(p0);
        if (response.status == true) {
          completion();
        }
      },
    );
  }

  void deleteRoom({required int roomId, required Function() completion}) {
    var param = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.roomId: roomId.toString(),
    };

    ApiService.shared.call(
      param: param,
      url: WebService.moderator.deleteRoomByModerator,
      completion: (p0) {
        var response = CommonResponse.fromJson(p0);
        if (response.status == true) {
          completion();
        }
      },
    );
  }

  void deleteStory({required int storyId, required Function() completion}) {
    var param = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.storyId: storyId.toString(),
    };

    ApiService.shared.call(
      param: param,
      url: WebService.moderator.deleteStoryByModerator,
      completion: (p0) {
        var response = CommonResponse.fromJson(p0);
        if (response.status == true) {
          completion();
        }
      },
    );
  }

  Future<void> deleteReel({required int reelId}) async {
    var param = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.reelId: reelId.toString(),
    };
    await NewApiService.shared.call(
      url: WebService.moderator.deleteReelByModerator,
      param: param,
      fromJson: CommonResponse.fromJson,
    );
  }

  Future<void> deleteReelComment({required int commentId}) async {
    var param = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.reelCommentId: commentId.toString(),
    };
    await NewApiService.shared.call(
      param: param,
      url: WebService.moderator.deleteReelCommentByModerator,
      fromJson: CommonResponse.fromJson,
    );
  }
}

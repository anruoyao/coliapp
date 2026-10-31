import 'dart:convert';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled/common/api_service/api_service.dart';
import 'package:untitled/common/api_service/new_api_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/logger.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/comment_model.dart';
import 'package:untitled/models/comments_model.dart';
import 'package:untitled/models/common_response.dart';
import 'package:untitled/models/post_users_model.dart';
import 'package:untitled/models/posts_model.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/models/room_model.dart';
import 'package:untitled/models/search_hashtags_model.dart';
import 'package:untitled/models/single_feed_model.dart';
import 'package:untitled/models/upload_file.dart';
import 'package:untitled/screens/add_post_screen/add_post_controller.dart';
import 'package:untitled/utilities/const.dart';
import 'package:untitled/utilities/params.dart';
import 'package:untitled/utilities/web_service.dart';

class PostService {
  static var shared = PostService();

  Future<void> searchPosts(
      String query, int start, Function(List<Post> posts) completion) async {
    var param = {
      Param.keyword: query,
      Param.start: start,
      Param.limit: Limits.pagination,
      Param.userId: SessionManager.shared.getUserID(),
    };
    await ApiService.shared.call(
        url: WebService.searchPost,
        param: param,
        completion: (response) {
          List<Post>? posts = PostsModel.fromJson(response).data;
          if (posts != null) {
            completion(posts);
          }
        });
  }

  Future<List<Post>> searchPostsWithInterest(
      {required String query,
      required int start,
      required num interestId}) async {
    var param = {
      Param.keyword: query,
      Param.start: start,
      Param.limit: Limits.pagination,
      Param.userId: SessionManager.shared.getUserID(),
      Param.interestId: interestId,
    };

    PostsModel model = await NewApiService.shared.call(
      url: WebService.searchPostByInterestId,
      param: param,
      fromJson: PostsModel.fromJson,
    );

    return model.data ?? [];
  }

  void searchHashtags(
      String query, int start, Function(List<SearchTag> posts) completion) {
    var param = {
      Param.keyword: query,
      Param.start: start,
      Param.limit: Limits.pagination,
      Param.userId: SessionManager.shared.getUserID(),
    };
    ApiService.shared.call(
        url: WebService.searchHashtag,
        param: param,
        completion: (response) {
          List<SearchTag>? posts = SearchHashtagsModel.fromJson(response).data;
          if (posts != null) {
            completion(posts);
          }
        });
  }

  void uploadFile(XFile file, Function(String) completion) {
    ApiService.shared.multiPartCallApi(
      url: WebService.uploadFile,
      filesMap: {
        'uploadFile': [file]
      },
      completion: (response) {
        String? fileURL = UploadFile.fromJson(response).data;
        if (fileURL != null) {
          completion(fileURL);
        }
      },
    );
  }

  void fetchPost(int postId, Function(Post? post) completion) {
    var param = {
      Param.postId: postId,
      Param.myUserId: SessionManager.shared.getUserID()
    };
    ApiService.shared.call(
      url: WebService.fetchPostByPostId,
      param: param,
      completion: (response) {
        Post? post = SingleFeedModel.fromJson(response).data;
        completion(post);
      },
    );
  }

  void fetchPostsByHashtag(
      String tag, int start, Function(List<Post>) completion) {
    var param = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.start: start,
      Param.tag: tag,
      Param.limit: Limits.pagination.toString()
    };
    ApiService.shared.call(
      param: param,
      url: WebService.fetchPostsByHashtag,
      completion: (data) {
        var obj = PostsModel.fromJson(data).data;
        if (obj != null) {
          completion(obj);
        }
      },
    );
  }

  /// 删除评论：成功返回 true；请求失败或业务失败（status=false）返回 false，不会悬挂回调
  Future<bool> deleteComment(num commentId) async {
    var params = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.commentId: commentId,
    };
    bool success = false;
    try {
      await ApiService.shared.call(
        url: WebService.deleteComment,
        param: params,
        completion: (response) {
          success = CommonResponse.fromJson(response).status == true;
        },
      );
    } catch (e) {
      Loggers.error("deleteComment failed: $e");
      return false;
    }
    return success;
  }

  void likeDislike(num commentId, Function(Comment comment) completion) {
    var params = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.commentId: commentId,
    };
    ApiService.shared.call(
      url: WebService.likeDislikeComment,
      param: params,
      completion: (response) {
        Comment? comment = CommentModel.fromJson(response).data;
        if (comment != null) {
          completion(comment);
        }
      },
    );
  }

  void fetchUsersWhoLikedPost(
      {required int postId, required Function(List<User> users) completion}) {
    Map<String, dynamic> param = {
      Param.postId: postId,
      Param.userId: SessionManager.shared.getUserID(),
    };
    ApiService.shared.call(
      url: WebService.fetchUsersWhoLikedPost,
      param: param,
      completion: (response) {
        var users = PostUsersModel.fromJson(response).data;
        if (users != null) {
          completion(users.map((e) => e.user ?? User()).toList());
        }
      },
    );
  }

  /// 发布评论：成功返回 Comment；请求失败或业务失败（status=false）返回 null，不会悬挂回调
  Future<Comment?> addComment(String comment, num postId) async {
    var params = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.desc: comment,
      Param.postId: postId
    };
    Comment? result;
    try {
      await ApiService.shared.call(
        url: WebService.addComment,
        param: params,
        completion: (response) {
          result = CommentModel.fromJson(response).data;
        },
      );
    } catch (e) {
      Loggers.error("addComment failed: $e");
      return null;
    }
    return result;
  }

  Future<void> fetchComments(num postId, int start,
      Function(List<Comment> comments) completion) async {
    var params = {
      Param.start: start,
      Param.postId: postId,
      Param.limit: Limits.pagination,
      Param.myUserId: SessionManager.shared.getUserID(),
    };
    await ApiService.shared.call(
      url: WebService.fetchComments,
      param: params,
      completion: (response) {
        var comments = CommentsModel.fromJson(response).data;
        if (comments != null) {
          completion(comments);
        }
      },
    );
  }

  /// 拉取一页评论并直接返回列表；失败返回空列表。
  /// 用于"发布/删除评论的响应在传输中丢失"后的对账查询。
  Future<List<Comment>> fetchCommentsPage(num postId, int start) async {
    List<Comment> result = [];
    try {
      await fetchComments(postId, start, (fetched) {
        result = fetched;
      });
    } catch (e) {
      Loggers.error("fetchCommentsPage failed: $e");
    }
    return result;
  }

  void reportPost(num postId, String reason, String desc) {
    var param = {Param.postId: postId, Param.reason: reason, Param.desc: desc};
    ApiService.shared.call(
      url: WebService.reportPost,
      param: param,
      completion: (response) {
        var obj = CommonResponse.fromJson(response);
        if (obj.status == true) {
          Get.back();
          Get.back();
          BaseController.share.showSnackBar(LKeys.reportAddedSuccessfully.tr,
              type: SnackBarType.success);
        }
      },
    );
  }

  Future<void> fetchUserPosts(
      int userID, int start, Function(List<Post> posts) completion) async {
    var param = {
      Param.myUserId: SessionManager.shared.getUserID(),
      Param.userId: userID.toString(),
      Param.start: start.toString(),
      Param.limit: Limits.pagination.toString()
    };
    await ApiService.shared.call(
        param: param,
        url: WebService.fetchPostByUser,
        completion: (data) {
          var obj = PostsModel.fromJson(data).data;
          if (obj != null) {
            completion(obj);
          }
        });
  }

  void uploadPost({
    required String desc,
    required String tags,
    required PostType contentType,
    String? urlPreview,
    required List<XFile> images,
    XFile? video,
    XFile? audioFile,
    required Function(int bytes, int totalBytes) onProgress,
    required Function(Post feed) completion,
    required String thumbnailPath,
    required List<double> waves,
    required String interestIds,
  }) {
    var param = {
      Param.linkPreviewJson: urlPreview,
      Param.desc: desc,
      Param.tags: tags,
      Param.userId: SessionManager.shared.getUserID(),
      Param.contentType: contentType.value.toString(),
      Param.audioWaves: jsonEncode(waves),
      Param.interestIds: interestIds,
    };
    ApiService.shared.multiPartCallApi(
      url: WebService.addPost,
      param: param,
      filesMap: {
        Param.contents: contentType == PostType.image
            ? images
            : contentType == PostType.video
                ? [video]
                : [audioFile],
        Param.thumbnailArray: [XFile(thumbnailPath)]
      },
      completion: (data) {
        var post = SingleFeedModel.fromJson(data).data;
        if (post != null) {
          completion(post);
        }
      },
    );
  }

  void likePost(int postID, Function() completion) {
    var param = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.postId: postID.toString()
    };

    ApiService.shared.call(
      param: param,
      url: WebService.likePost,
      completion: (p0) {
        var response = CommonResponse.fromJson(p0);
        if (response.status == true) {
          completion();
        }
      },
    );
  }

  void deletePost(int postID, Function() completion) {
    var param = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.postId: postID.toString()
    };

    ApiService.shared.call(
      param: param,
      url: WebService.deleteMyPost,
      completion: (p0) {
        var response = CommonResponse.fromJson(p0);
        if (response.status == true) {
          completion();
        }
      },
    );
  }

  void dislikePost(int postID, Function() completion) {
    var param = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.postId: postID.toString()
    };

    ApiService.shared.call(
      param: param,
      url: WebService.dislikePost,
      completion: (p0) {
        var response = CommonResponse.fromJson(p0);
        if (response.status == true) {
          completion();
        }
      },
    );
  }

  Future<void> fetchPosts({
    required bool shouldSendSuggestedRoom,
    required int start,
    required Function(List<Post> posts, List<Room> suggestedRooms) completion,
  }) async {
    var param = {
      Param.myUserId: SessionManager.shared.getUserID(),
      Param.limit: Limits.pagination.toString(),
      Param.start: start,
      Param.shouldSendSuggestedRoom: shouldSendSuggestedRoom ? 1 : 0,
      Param.fetchPostType:
          SessionManager.shared.getSettings()?.fetchPostType ?? 0,
    };
    await ApiService.shared.call(
        param: param,
        url: WebService.fetchPosts,
        completion: (data) {
          var obj = PostsModel.fromJson(data).data;
          var rooms = PostsModel.fromJson(data).suggestedRooms;
          if (obj != null) {
            completion(obj, rooms ?? []);
          }
        });
  }
}

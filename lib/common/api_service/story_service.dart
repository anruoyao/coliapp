import 'package:image_picker/image_picker.dart';
import 'package:untitled/common/api_service/api_service.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/models/common_response.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/models/story.dart';
import 'package:untitled/models/users_model.dart';
import 'package:untitled/utilities/params.dart';
import 'package:untitled/utilities/web_service.dart';

class StoryService {
  static var shared = StoryService();

  Future<void> fetchStories(Function(List<User> storyUsers) completion) async {
    var param = {Param.myUserId: SessionManager.shared.getUserID()};
    await ApiService.shared.call(
      url: WebService.fetchStories,
      param: param,
      completion: (response) {
        var data = UsersModel.fromJson(response).data;
        if (data != null) {
          completion(data);
        }
      },
    );
  }

  void fetchStoryById(
      {required int storyId, required Function(Story? story) completion}) {
    var param = {
      Param.myUserId: SessionManager.shared.getUserID(),
      Param.storyId: storyId,
    };
    ApiService.shared.call(
      url: WebService.fetchStoryByID,
      param: param,
      completion: (response) {
        var data = StoryModel.fromJson(response).data;
        completion(data);
      },
    );
  }

  void viewStory(num storyId, Function() completion) {
    var param = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.storyId: storyId
    };
    ApiService.shared.call(
      url: WebService.viewStory,
      param: param,
      completion: (response) {
        var status = CommonResponse.fromJson(response).status;
        if (status == true) {
          completion();
        }
      },
    );
  }

  void createStory(
      {required String fileURL,
      String? thumbnail,
      required int type,
      required double duration,
      required Function() completion}) {
    var param = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.type: type,
      Param.duration: duration,
    };
    var filesParam = {
      Param.content: [XFile(fileURL)]
    };
    if (thumbnail != null && thumbnail.isNotEmpty) {
      filesParam[Param.thumbnail] = [XFile(thumbnail)];
    }
    ApiService.shared.multiPartCallApi(
      url: WebService.createStory,
      param: param,
      filesMap: filesParam,
      completion: (response) {
        var status = CommonResponse.fromJson(response).status;
        if (status == true) {
          completion();
        }
      },
    );
  }

  void deleteStory(num storyId, Function() completion) {
    var param = {
      Param.myUserId: SessionManager.shared.getUserID(),
      Param.storyId: storyId
    };
    ApiService.shared.call(
      url: WebService.deleteStory,
      param: param,
      completion: (response) {
        var status = CommonResponse.fromJson(response).status;
        if (status == true) {
          completion();
        }
      },
    );
  }
}

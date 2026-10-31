import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/library/story_view/story_view.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/utilities/const.dart';

class StoryModel {
  StoryModel({
    this.status,
    this.message,
    this.data,
  });

  StoryModel.fromJson(dynamic json) {
    status = json['status'];
    message = json['message'];
    data = json['data'] != null ? Story.fromJson(json['data']) : null;
  }

  bool? status;
  String? message;
  Story? data;
}

class Story {
  Story({
    this.id,
    this.userId,
    this.type,
    this.duration,
    this.content,
    this.viewByUserIds,
    this.createdAt,
    this.updatedAt,
    this.user,
    this.thumbnail,
  });

  Story.fromJson(dynamic json) {
    id = json['id'];
    userId = json['user_id'];
    type = json['type'];
    duration = json['duration'];
    content = json['content'];
    thumbnail = json['thumbnail'];
    viewByUserIds = json['view_by_user_ids'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
  }

  num? id;
  num? userId;
  num? type;
  num? duration;
  String? content;
  String? viewByUserIds;
  String? createdAt;
  String? updatedAt;
  User? user;
  String? thumbnail;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['user_id'] = userId;
    map['type'] = type;
    map['duration'] = duration;
    map['content'] = content;
    map['thumbnail'] = thumbnail;
    map['view_by_user_ids'] = viewByUserIds;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['user'] = user;
    return map;
  }

  bool isWatchedByMe() {
    var arr = viewByUserIds?.split(',') ?? [];
    return arr.contains(SessionManager.shared.getUserID().toString());
  }

  List<String> viewedByUsersIds() {
    return viewByUserIds?.split(',') ?? [];
  }

  StoryItem toStoryItem(StoryController controller) {
    if (type == 1) {
      return StoryItem.pageVideo(
        story: this,
        content?.addBaseURL() ?? '',
        controller: controller,
        duration: Duration(seconds: (duration ?? Limits.storyDuration).toInt()),
        shown: isWatchedByMe(),
        id: id ?? 0,
        viewedByUsersIds: viewedByUsersIds(),
      );
    } else if (type == 0) {
      return StoryItem.pageImage(
        story: this,
        url: content?.addBaseURL() ?? '',
        duration: Duration(seconds: Limits.storyDuration),
        controller: controller,
        shown: isWatchedByMe(),
        id: id ?? 0,
        viewedByUsersIds: viewedByUsersIds(),
      );
    } else {
      return StoryItem.text(
        story: this,
        title: content ?? '',
        backgroundColor: cBlack,
        shown: isWatchedByMe(),
        id: id ?? 0,
        viewedByUsersIds: viewedByUsersIds(),
      );
    }
  }

  DateTime get date => DateTime.parse(createdAt ?? '');

  String? get thumbnailForReply {
    if (type == 1) return thumbnail;
    return content;
  }
}

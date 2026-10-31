import 'dart:convert';

import 'package:untitled/common/managers/url_extractor/parsers/base_parser.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/models/room_model.dart';
import 'package:untitled/screens/add_post_screen/add_post_controller.dart';

class PostsModel {
  bool? status;
  String? message;
  List<Post>? data;
  List<Room>? suggestedRooms;

  PostsModel({
    this.status,
    this.message,
    this.data,
    this.suggestedRooms,
  });

  factory PostsModel.fromJson(dynamic json) => PostsModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<Post>.from(json["data"]!.map((x) => Post.fromJson(x))),
        suggestedRooms: json["suggestedRooms"] == null
            ? []
            : List<Room>.from(
                json["suggestedRooms"]!.map((x) => Room.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
        "suggestedRooms": suggestedRooms == null
            ? []
            : List<dynamic>.from(suggestedRooms!.map((x) => x.toJson())),
      };
}

class Post {
  int? id;
  int? userId;
  String? desc;
  String? tags;
  int commentsCount;
  int? likesCount;
  String? linkPreviewJson;
  int? isRestricted;
  int? contentType;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? isLike;
  List<Content>? content;
  User? user;

  Post({
    this.id,
    this.userId,
    this.desc,
    this.tags,
    required this.commentsCount,
    this.likesCount,
    this.linkPreviewJson,
    this.isRestricted,
    this.contentType,
    this.createdAt,
    this.updatedAt,
    this.isLike,
    this.content,
    this.user,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json["id"],
        userId: json["user_id"],
        desc: json["desc"],
        tags: json["tags"],
        commentsCount: json["comments_count"] ?? 0,
        likesCount: json["likes_count"],
        linkPreviewJson: json["link_preview_json"],
        isRestricted: json["is_restricted"],
        contentType: json["content_type"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
        isLike: json["is_like"],
        content: json["content"] == null
            ? []
            : List<Content>.from(
                json["content"]!.map((x) => Content.fromJson(x))),
        user: json["user"] == null ? null : User.fromJson(json["user"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "user_id": userId,
        "desc": desc,
        "tags": tags,
        "comments_count": commentsCount,
        "likes_count": likesCount,
        "link_preview_json": linkPreviewJson,
        "is_restricted": isRestricted,
        "content_type": contentType,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "is_like": isLike,
        "content": content == null
            ? []
            : List<dynamic>.from(content!.map((x) => x.toJson())),
        "user": user?.toJson(),
      };

  UrlMetadata? get linkPreview {
    if (linkPreviewJson == null || linkPreviewJson?.isEmpty == true) {
      return null;
    } else {
      Map<String, dynamic>? valueMap = jsonDecode(linkPreviewJson ?? '');
      if (valueMap != null) return UrlMetadata.fromJson(valueMap);
    }
    return null;
  }

  PostType get type {
    if (content?.isEmpty == true) {
      return PostType.text;
    } else {
      return PostType.values.firstWhere(
          (element) => element.value == (content?.first.contentType ?? 0));
    }
  }
}

class Content {
  int? id;
  int? postId;
  int? contentType;
  String? content;
  String? thumbnail;
  String? audioWaves;
  DateTime? createdAt;
  DateTime? updatedAt;

  Content({
    this.id,
    this.postId,
    this.contentType,
    this.content,
    this.thumbnail,
    this.audioWaves,
    this.createdAt,
    this.updatedAt,
  });

  factory Content.fromJson(Map<String, dynamic> json) => Content(
        id: json["id"],
        postId: json["post_id"],
        contentType: json["content_type"],
        content: json["content"],
        thumbnail: json["thumbnail"],
        audioWaves: json["audio_waves"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "post_id": postId,
        "content_type": contentType,
        "content": content,
        "thumbnail": thumbnail,
        "audio_waves": audioWaves,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
      };
}

extension O on Post {
  DateTime get date => createdAt ?? DateTime.now();
}

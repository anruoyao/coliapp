import 'package:untitled/models/registration.dart';

import 'musics_model.dart';

class ReelModel {
  bool? status;
  String? message;
  Reel? data;

  ReelModel({
    this.status,
    this.message,
    this.data,
  });

  factory ReelModel.fromJson(Map<String, dynamic> json) => ReelModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null ? null : Reel.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "data": data?.toJson(),
      };
}

class Reel {
  int? id;
  int? userId;
  String? interestIds;
  int? musicId;
  String? description;
  String? content;
  String? thumbnail;
  String? hashtags;
  int? commentsCount;
  int? likesCount;
  int? viewsCount;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? isLike;
  int? isFollow;
  Music? music;
  User? user;

  Reel({
    this.id,
    this.userId,
    this.interestIds,
    this.musicId,
    this.description,
    this.content,
    this.thumbnail,
    this.hashtags,
    this.commentsCount,
    this.likesCount,
    this.viewsCount,
    this.createdAt,
    this.updatedAt,
    this.isLike,
    this.isFollow,
    this.music,
    this.user,
  });

  factory Reel.fromJson(Map<String, dynamic> json) => Reel(
        id: json["id"],
        userId: json["user_id"],
        interestIds: json["interest_ids"],
        musicId: json["music_id"],
        description: json["description"],
        content: json["content"],
        thumbnail: json["thumbnail"],
        hashtags: json["hashtags"],
        commentsCount: json["comments_count"],
        likesCount: json["likes_count"],
        viewsCount: json["views_count"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
        isLike: json["is_like"],
        isFollow: json["is_follow"],
        music: json["music"] == null ? null : Music.fromJson(json["music"]),
        user: json["user"] == null ? null : User.fromJson(json["user"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "user_id": userId,
        "interest_ids": interestIds,
        "music_id": musicId,
        "description": description,
        "content": content,
        "thumbnail": thumbnail,
        "hashtags": hashtags,
        "comments_count": commentsCount,
        "likes_count": likesCount,
        "views_count": viewsCount,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "is_like": isLike,
        "is_follow": isFollow,
        "music": music?.toJson(),
        "user": user?.toJson(),
      };
}

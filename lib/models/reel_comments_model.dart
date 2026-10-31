import 'package:untitled/models/registration.dart';

class ReelCommentsModel {
  bool? status;
  String? message;
  List<ReelComment>? data;

  ReelCommentsModel({
    this.status,
    this.message,
    this.data,
  });

  factory ReelCommentsModel.fromJson(Map<String, dynamic> json) =>
      ReelCommentsModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<ReelComment>.from(
                json["data"]!.map((x) => ReelComment.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class ReelComment {
  int? id;
  int? userId;
  int? reelId;
  String? description;
  DateTime? createdAt;
  DateTime? updatedAt;
  User? user;

  ReelComment({
    this.id,
    this.userId,
    this.reelId,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  factory ReelComment.fromJson(Map<String, dynamic> json) => ReelComment(
        id: json["id"],
        userId: json["user_id"],
        reelId: json["reel_id"],
        description: json["description"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
        user: json["user"] == null ? null : User.fromJson(json["user"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "user_id": userId,
        "reel_id": reelId,
        "description": description,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "user": user?.toJson(),
      };
}

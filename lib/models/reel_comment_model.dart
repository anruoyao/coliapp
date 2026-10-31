import 'package:untitled/models/reel_comments_model.dart';

class ReelCommentModel {
  bool? status;
  String? message;
  ReelComment? data;

  ReelCommentModel({
    this.status,
    this.message,
    this.data,
  });

  factory ReelCommentModel.fromJson(Map<String, dynamic> json) =>
      ReelCommentModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null ? null : ReelComment.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "data": data == null ? null : data?.toJson(),
      };
}

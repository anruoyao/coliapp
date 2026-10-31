import 'package:untitled/models/reel_model.dart';

class ReelsModel {
  bool? status;
  String? message;
  List<Reel>? data;

  ReelsModel({
    this.status,
    this.message,
    this.data,
  });

  factory ReelsModel.fromJson(Map<String, dynamic> json) => ReelsModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<Reel>.from(json["data"]!.map((x) => Reel.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class MusicCategoriesModel {
  bool? status;
  String? message;
  List<MusicCategory>? data;

  MusicCategoriesModel({
    this.status,
    this.message,
    this.data,
  });

  factory MusicCategoriesModel.fromJson(Map<String, dynamic> json) =>
      MusicCategoriesModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<MusicCategory>.from(
                json["data"]!.map((x) => MusicCategory.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class MusicCategory {
  int? id;
  String? title;
  int? isDeleted;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? musicsCount;

  MusicCategory({
    this.id,
    this.title,
    this.isDeleted,
    this.createdAt,
    this.updatedAt,
    this.musicsCount,
  });

  factory MusicCategory.fromJson(Map<String, dynamic> json) => MusicCategory(
        id: json["id"],
        title: json["title"],
        isDeleted: json["is_deleted"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
        musicsCount: json["musics_count"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "is_deleted": isDeleted,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "musics_count": musicsCount,
      };
}

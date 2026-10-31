import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/models/registration.dart';

class MusicsModel {
  bool? status;
  String? message;
  List<Music>? data;

  MusicsModel({
    this.status,
    this.message,
    this.data,
  });

  factory MusicsModel.fromJson(Map<String, dynamic> json) => MusicsModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<Music>.from(json["data"]!.map((x) => Music.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class Music {
  int? id;
  int? categoryId;
  String? title;
  String? sound;
  String? duration;
  String? artist;
  String? image;
  int? isDeleted;
  DateTime? createdAt;
  DateTime? updatedAt;

  Music({
    this.id,
    this.categoryId,
    this.title,
    this.sound,
    this.duration,
    this.artist,
    this.image,
    this.isDeleted,
    this.createdAt,
    this.updatedAt,
  });

  factory Music.fromJson(Map<String, dynamic> json) => Music(
        id: json["id"],
        categoryId: json["category_id"],
        title: json["title"],
        sound: json["sound"],
        duration: json["duration"],
        artist: json["artist"],
        image: json["image"],
        isDeleted: json["is_deleted"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "category_id": categoryId,
        "title": title,
        "sound": sound,
        "duration": duration,
        "artist": artist,
        "image": image,
        "is_deleted": isDeleted,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
      };
}

extension MusicSaved on Music {
  bool get isSaved {
    return SessionManager.shared
            .getUser()
            ?.getSavedMusicIdsList()
            .contains(id ?? 0) ??
        false;
  }
}

class SelectedMusic {
  String? downloadedURL;
  int? startMilliSec;
  int? endMilliSec;
  Music? music;

  SelectedMusic(this.downloadedURL, this.startMilliSec, this.music,
      {this.endMilliSec = null});
}

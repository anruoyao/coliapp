class SettingModel {
  bool? status;
  String? message;
  Settings? data;

  SettingModel({
    this.status,
    this.message,
    this.data,
  });

  factory SettingModel.fromJson(Map<String, dynamic> json) => SettingModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null ? null : Settings.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "data": data?.toJson(),
      };
}

class Settings {
  int? id;
  String? appName;
  int? setRoomUsersLimit;
  int? minuteLimitInCreatingStory;
  int? minuteLimitInAudioPost;
  int? minuteLimitInChoosingVideoForStory;
  int? minuteLimitInChoosingVideoForPost;
  int? maxImagesCanBeUploadedInOnePost;
  String? adBannerAndroid;
  String? adInterstitialAndroid;
  String? adBannerIOs;
  String? adInterstitialIOs;
  int? isAdmobOn;
  int? audioSpaceHostsLimit;
  int? audioSpaceListenersLimit;
  int? audioSpaceDurationInMinutes;
  int? durationLimitInReel;
  int? storageType;
  int? fetchPostType;
  String? supportEmail;
  int? isInAppPurchaseEnabled;
  DateTime? createdAt;
  DateTime? updatedAt;
  List<Interest>? interests;
  List<SettingCommon>? documentType;
  List<SettingCommon>? reportReasons;
  List<SettingCommon>? restrictedUsernames;
  int? isMaintenanceMode;
  String? maintenanceMessage;
  String? androidAppVersion;
  String? iosAppVersion;
  String? playStoreDownloadLink;
  String? appStoreDownloadLink;
  int? isForceAppUpdate;

  Settings({
    this.id,
    this.appName,
    this.setRoomUsersLimit,
    this.minuteLimitInCreatingStory,
    this.minuteLimitInAudioPost,
    this.minuteLimitInChoosingVideoForStory,
    this.minuteLimitInChoosingVideoForPost,
    this.maxImagesCanBeUploadedInOnePost,
    this.adBannerAndroid,
    this.adInterstitialAndroid,
    this.adBannerIOs,
    this.adInterstitialIOs,
    this.isAdmobOn,
    this.audioSpaceHostsLimit,
    this.audioSpaceListenersLimit,
    this.audioSpaceDurationInMinutes,
    this.durationLimitInReel,
    this.storageType,
    this.fetchPostType,
    this.supportEmail,
    this.isInAppPurchaseEnabled,
    this.createdAt,
    this.updatedAt,
    this.interests,
    this.documentType,
    this.reportReasons,
    this.restrictedUsernames,
    this.isMaintenanceMode,
    this.maintenanceMessage,
    this.androidAppVersion,
    this.iosAppVersion,
    this.playStoreDownloadLink,
    this.appStoreDownloadLink,
    this.isForceAppUpdate,
  });

  factory Settings.fromJson(Map<String, dynamic> json) => Settings(
        id: json["id"],
        appName: json["app_name"],
        setRoomUsersLimit: json["setRoomUsersLimit"],
        minuteLimitInCreatingStory: json["minute_limit_in_creating_story"],
        minuteLimitInAudioPost: json["minute_limit_in_audio_post"],
        minuteLimitInChoosingVideoForStory:
            json["minute_limit_in_choosing_video_for_story"],
        minuteLimitInChoosingVideoForPost:
            json["minute_limit_in_choosing_video_for_post"],
        maxImagesCanBeUploadedInOnePost:
            json["max_images_can_be_uploaded_in_one_post"],
        adBannerAndroid: json["ad_banner_android"],
        adInterstitialAndroid: json["ad_interstitial_android"],
        adBannerIOs: json["ad_banner_iOS"],
        adInterstitialIOs: json["ad_interstitial_iOS"],
        isAdmobOn: json["is_admob_on"],
        audioSpaceHostsLimit: json["audio_space_hosts_limit"],
        audioSpaceListenersLimit: json["audio_space_listeners_limit"],
        audioSpaceDurationInMinutes: json["audio_space_duration_in_minutes"],
        durationLimitInReel: json["duration_limit_in_reel"],
        storageType: json["storage_type"],
        fetchPostType: json["fetch_post_type"],
        supportEmail: json["support_email"],
        isInAppPurchaseEnabled: json["is_in_app_purchase_enabled"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
        interests: json["interests"] == null
            ? []
            : List<Interest>.from(
                json["interests"]!.map((x) => Interest.fromJson(x))),
        documentType: json["documentType"] == null
            ? []
            : List<SettingCommon>.from(
                json["documentType"]!.map((x) => SettingCommon.fromJson(x))),
        reportReasons: json["reportReasons"] == null
            ? []
            : List<SettingCommon>.from(
                json["reportReasons"]!.map((x) => SettingCommon.fromJson(x))),
        restrictedUsernames: json["restrictedUsernames"] == null
            ? []
            : List<SettingCommon>.from(json["restrictedUsernames"]!
                .map((x) => SettingCommon.fromJson(x))),
        isMaintenanceMode: json["is_maintenance_mode"],
        maintenanceMessage: json["maintenance_message"],
        androidAppVersion: json["android_app_version"],
        iosAppVersion: json["ios_app_version"],
        playStoreDownloadLink: json["play_store_download_link"],
        appStoreDownloadLink: json["app_store_download_link"],
        isForceAppUpdate: json["is_force_app_update"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "app_name": appName,
        "setRoomUsersLimit": setRoomUsersLimit,
        "minute_limit_in_creating_story": minuteLimitInCreatingStory,
        "minute_limit_in_audio_post": minuteLimitInAudioPost,
        "minute_limit_in_choosing_video_for_story":
            minuteLimitInChoosingVideoForStory,
        "minute_limit_in_choosing_video_for_post":
            minuteLimitInChoosingVideoForPost,
        "max_images_can_be_uploaded_in_one_post":
            maxImagesCanBeUploadedInOnePost,
        "ad_banner_android": adBannerAndroid,
        "ad_interstitial_android": adInterstitialAndroid,
        "ad_banner_iOS": adBannerIOs,
        "ad_interstitial_iOS": adInterstitialIOs,
        "is_admob_on": isAdmobOn,
        "audio_space_hosts_limit": audioSpaceHostsLimit,
        "audio_space_listeners_limit": audioSpaceListenersLimit,
        "audio_space_duration_in_minutes": audioSpaceDurationInMinutes,
        "duration_limit_in_reel": durationLimitInReel,
        "storage_type": storageType,
        "fetch_post_type": fetchPostType,
        "support_email": supportEmail,
        "is_in_app_purchase_enabled": isInAppPurchaseEnabled,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "interests": interests == null
            ? []
            : List<dynamic>.from(interests!.map((x) => x.toJson())),
        "documentType": documentType == null
            ? []
            : List<dynamic>.from(documentType!.map((x) => x.toJson())),
        "reportReasons": reportReasons == null
            ? []
            : List<dynamic>.from(reportReasons!.map((x) => x.toJson())),
        "restrictedUsernames": restrictedUsernames == null
            ? []
            : List<dynamic>.from(restrictedUsernames!.map((x) => x.toJson())),
        "is_maintenance_mode": isMaintenanceMode,
        "maintenance_message": maintenanceMessage,
        "android_app_version": androidAppVersion,
        "ios_app_version": iosAppVersion,
        "play_store_download_link": playStoreDownloadLink,
        "app_store_download_link": appStoreDownloadLink,
        "is_force_app_update": isForceAppUpdate,
      };
}

class Interest {
  int? id;
  String? title;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? totalRoomOfInterest;

  Interest({
    this.id,
    this.title,
    this.createdAt,
    this.updatedAt,
    this.totalRoomOfInterest,
  });

  factory Interest.fromJson(Map<String, dynamic> json) => Interest(
        id: json["id"],
        title: json["title"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
        totalRoomOfInterest: json["totalRoomOfInterest"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "totalRoomOfInterest": totalRoomOfInterest,
      };
}

class SettingCommon {
  int? id;
  String? title;
  DateTime? createdAt;
  DateTime? updatedAt;

  SettingCommon({
    this.id,
    this.title,
    this.createdAt,
    this.updatedAt,
  });

  factory SettingCommon.fromJson(Map<String, dynamic> json) => SettingCommon(
        id: json["id"],
        title: json["title"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
      };
}

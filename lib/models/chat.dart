// ignore_for_file: unnecessary_getters_setters

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/utilities/firebase_const.dart';

/// 会话（列表项 / 聊天页头部信息）。
///
/// 数据来源为自建后端 /api/chat/* 接口（替代原 Firestore 实时数据库），
/// 字段命名与原 Firestore 结构保持一致，UI 层零改动。
class ChatUserRoom {
  bool? _iBlocked;
  bool? _iAmBlocked;
  String? _conversationId;
  String? _conversationKey; // WS 会话频道密钥：conv.{conversationId}.{key}
  String? _deletedId;
  bool? _isDeleted;
  bool? _isMute;
  String? _lastMsg;
  int? _newMsgCount;
  String? _title;
  String? _profileImage;
  int? _type;
  num? _userIdOrRoomId;
  DateTime? _time;
  List<num>? _usersIds;
  int? _requestStatus; // 0 待处理请求 / 1 正常 / 2 已拒绝
  bool? _isHidden;

  ChatUserRoom(
      {String? conversationId,
      String? conversationKey,
      bool? iAmBlocked,
      bool? iBlocked,
      String? deletedId,
      bool? isDeleted,
      bool? isMute,
      String? lastMsg,
      int? newMsgCount,
      DateTime? time,
      String? title,
      String? profileImage,
      num? userIdOrRoomId,
      List<num>? usersIds,
      int? type,
      int? requestStatus,
      bool? isHidden}) {
    _title = title;
    _conversationId = conversationId;
    _conversationKey = conversationKey;
    _iAmBlocked = iAmBlocked;
    _iBlocked = iBlocked;
    _deletedId = deletedId;
    _isDeleted = isDeleted;
    _isMute = isMute;
    _lastMsg = lastMsg;
    _newMsgCount = newMsgCount;
    _time = time;
    _profileImage = profileImage;
    _type = type;
    _userIdOrRoomId = userIdOrRoomId;
    _usersIds = usersIds;
    _requestStatus = requestStatus;
    _isHidden = isHidden;
  }

  ChatUserRoom.fromJson(Map<String, dynamic> json) {
    _conversationId = json["conversationId"]?.toString();
    _conversationKey = json["conversationKey"];
    _iAmBlocked = json["iAmBlocked"];
    _iBlocked = json["iBlocked"];
    _deletedId = json["deletedId"];
    _isDeleted = json["isDeleted"];
    _isMute = json["isMute"];
    _lastMsg = json["lastMsg"];
    _newMsgCount = json["newMsgCount"];
    _time = json['time'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(json['time'] is int
            ? json['time']
            : int.tryParse('${json['time']}') ?? 0);
    _type = json["type"];
    _title = json["title"];
    _profileImage = json["profileImage"];
    _userIdOrRoomId = json["userIdOrRoomId"];
    _usersIds = json['usersIds'] == null
        ? null
        : (json['usersIds'] as List)
            .map((e) => e is num ? e : num.tryParse('$e') ?? 0)
            .toList();
    _requestStatus = json['requestStatus'];
    _isHidden = json['isHidden'];
  }

  Map<String, Object?> toJson() {
    return {
      "conversationId": _conversationId,
      "conversationKey": _conversationKey,
      "iAmBlocked": _iAmBlocked,
      "iBlocked": _iBlocked,
      "deletedId": _deletedId,
      "isDeleted": _isDeleted,
      "isMute": _isMute,
      "lastMsg": _lastMsg,
      "newMsgCount": _newMsgCount,
      "time": _time?.millisecondsSinceEpoch,
      "title": _title,
      "profileImage": _profileImage,
      "type": _type,
      "userIdOrRoomId": _userIdOrRoomId,
      "usersIds": _usersIds,
      'requestStatus': _requestStatus,
      'isHidden': _isHidden,
    };
  }

  String? get conversationId => _conversationId;

  String? get conversationKey => _conversationKey;

  List<num>? get usersIds => _usersIds;

  set usersIds(List<num>? value) {
    _usersIds = value;
  }

  bool? get iAmBlocked => _iAmBlocked;

  bool? get iBlocked => _iBlocked;

  String? get deletedId => _deletedId;

  bool? get isDeleted => _isDeleted;

  bool? get isMute => _isMute;

  String? get lastMsg => _lastMsg;

  int? get newMsgCount => _newMsgCount;

  String? get title => _title;

  String? get profileImage => _profileImage;

  /// 0 = RequestChat
  /// 1 = UserChat
  /// 2 = RoomChat
  int? get type => _type;

  num? get userIdOrRoomId => _userIdOrRoomId;

  DateTime? get time => _time;

  int? get requestStatus => _requestStatus;

  bool? get isHidden => _isHidden;

  set type(int? value) {
    _type = value;
  }

  set time(DateTime? value) {
    _time = value;
  }

  set lastMsg(String? value) {
    _lastMsg = value;
  }

  set newMsgCount(int? value) {
    _newMsgCount = value;
  }

  set iAmBlocked(bool? value) {
    _iAmBlocked = value;
  }

  set iBlocked(bool? value) {
    _iBlocked = value;
  }

  set isDeleted(bool? value) {
    _isDeleted = value;
  }
}

class ChatUser {
  int? _userid;
  String? _username;
  String? _fullName;
  String? _image;
  bool? _isVerified;

  ChatUser({
    String? username,
    String? fullName,
    String? image,
    bool? isVerified,
    int? userid,
  }) {
    _username = username;
    _fullName = fullName;
    _image = image;
    _isVerified = isVerified;
    _userid = userid;
  }

  Map<String, dynamic> toJson() {
    return {
      "username": _username,
      "fullName": _fullName,
      "image": _image,
      "isVerified": _isVerified,
      "userid": _userid,
    };
  }

  ChatUser.fromJson(Map<String, dynamic> json) {
    _username = json["username"];
    _fullName = json["fullName"];
    _image = json["image"];
    _isVerified = json["isVerified"];
    _userid = json["userid"];
  }

  bool? get isVerified => _isVerified;

  String? get image => _image;

  String? get fullName => _fullName;

  String? get username => _username;

  int? get userid => _userid;
}

/// 聊天消息（自建后端 /api/chat 返回结构）。
class ChatMessage {
  num? _id;
  String? _content;
  String? _thumbnail;
  String? _msg;
  String? _msgType;
  num? _senderId;
  num? _storyId;
  DateTime? _createdAt;

  ChatMessage(
      {dynamic id,
      String? content,
      String? thumbnail,
      String? msg,
      String? msgType,
      num? senderId,
      num? storyId,
      DateTime? createdAt}) {
    _id = id is num ? id : num.tryParse('$id');
    _content = content;
    _thumbnail = thumbnail;
    _msg = msg;
    _msgType = msgType;
    _senderId = senderId;
    _storyId = storyId;
    _createdAt = createdAt;
  }

  ChatMessage.fromJson(Map<String, dynamic>? json) {
    final rawId = json?["id"];
    _id = rawId is num ? rawId : num.tryParse('$rawId');
    _content = json?["content"];
    _thumbnail = json?["thumbnail"];
    _msg = json?["msg"];
    _msgType = json?["msgType"];
    _senderId = json?["senderId"];
    _storyId = json?["storyId"];
    if (json?["createdAt"] != null) {
      final v = json?["createdAt"];
      _createdAt = DateTime.fromMillisecondsSinceEpoch(
          v is int ? v : int.tryParse('$v') ?? 0);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "id": _id,
      "content": _content,
      "thumbnail": _thumbnail,
      "msg": _msg,
      "msgType": _msgType,
      "senderId": _senderId,
      "storyId": _storyId,
      "createdAt": _createdAt?.millisecondsSinceEpoch
    };
  }

  String getChatTime() {
    final date =
        _createdAt ?? DateTime.fromMillisecondsSinceEpoch((_id ?? 0).toInt());
    return DateFormat('dd MMM, yyyy h:mm a').format(date);
  }

  String? get content => _content;

  String? get thumbnail => _thumbnail;

  num? get senderId => _senderId;

  MessageType get msgType =>
      MessageType.values
          .firstWhereOrNull((element) => element.value == _msgType) ??
      MessageType.text;

  String? get msg => _msg;

  num? get id => _id;

  num? get storyId => _storyId;

  set thumbnail(String? value) {
    _thumbnail = value;
  }
}

extension ChatUserExt on User {
  ChatUser toChatUser() {
    return ChatUser(
        fullName: fullName,
        image: profile,
        isVerified: isVerified == 1,
        userid: id?.toInt(),
        username: username);
  }
}

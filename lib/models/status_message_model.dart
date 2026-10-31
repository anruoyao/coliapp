class StatusMessageModel {
  bool? status;
  String? message;

  StatusMessageModel({
    this.status,
    this.message,
  });

  StatusMessageModel.fromJson(dynamic json) {
    status = json['status'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = status;
    map['message'] = message;
    return map;
  }
}

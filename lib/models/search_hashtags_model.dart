class SearchHashtagsModel {
  SearchHashtagsModel({
    this.status,
    this.message,
    this.data,
  });

  SearchHashtagsModel.fromJson(dynamic json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(SearchTag.fromJson(v));
      });
    }
  }

  bool? status;
  String? message;
  List<SearchTag>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = status;
    map['message'] = message;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class SearchTag {
  SearchTag({
    this.tag,
    this.postCount,
  });

  SearchTag.fromJson(dynamic json) {
    tag = json['tag'];
    postCount = json['post_count'];
  }

  String? tag;
  num? postCount;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['tag'] = tag;
    map['post_count'] = postCount;
    return map;
  }
}

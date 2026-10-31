enum ReelPageType {
  home,
  following,
  user,
  hashtag,
  saved,
  preview,
  search,
  single,
  music;

  String withId({num? userId = -1, num? musicId = -1, String? hashTag = ''}) {
    switch (this) {
      case ReelPageType.home:
        return 'home';
      case ReelPageType.user:
        return '$userId';
      case ReelPageType.hashtag:
        return hashTag ?? '';
      case ReelPageType.saved:
        return 'saved';
      case ReelPageType.music:
        return '$musicId';
      case ReelPageType.preview:
        return 'preview';
      case ReelPageType.search:
        return 'search';
      case ReelPageType.following:
        return 'following';
      case ReelPageType.single:
        return 'signal';
    }
  }

  bool get shouldShowBackButton {
    if (this case (ReelPageType.home || ReelPageType.following)) {
      return false;
    }
    return true;
  }

  bool get shouldShowComment {
    if (this case (ReelPageType.home || ReelPageType.following)) {
      return false;
    }
    return true;
  }
}

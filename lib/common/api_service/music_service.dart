import 'package:untitled/common/api_service/api_service.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/models/music_categories_model.dart';
import 'package:untitled/models/musics_model.dart';
import 'package:untitled/utilities/const.dart';
import 'package:untitled/utilities/params.dart';
import 'package:untitled/utilities/web_service.dart';

class MusicService {
  static var shared = MusicService();

  Future<List<Music>> fetchMusicWithSearch(String query, int start) async {
    var param = {
      Param.keyword: query,
      Param.start: start,
      Param.limit: Limits.pagination
    };
    List<Music> musics = [];
    await ApiService.shared.call(
        url: WebService.fetchMusicWithSearch,
        param: param,
        completion: (response) {
          musics = MusicsModel.fromJson(response).data ?? [];
        });
    return musics;
  }

  Future<List<Music>> fetchSavedMusic() async {
    var param = {Param.userId: SessionManager.shared.getUserID()};
    List<Music> musics = [];
    await ApiService.shared.call(
        url: WebService.fetchSavedMusic,
        param: param,
        completion: (response) {
          musics = MusicsModel.fromJson(response).data ?? [];
        });
    return musics;
  }

  Future<List<MusicCategory>> fetchMusicCategories() async {
    List<MusicCategory> categories = [];
    await ApiService.shared.call(
        url: WebService.fetchMusicCategories,
        completion: (response) {
          categories = MusicCategoriesModel.fromJson(response).data ?? [];
        });
    return categories;
  }

  Future<List<Music>> fetchMusicByCategory({
    required int start,
    required int categoryId,
  }) async {
    var param = {
      Param.start: start,
      Param.limit: Limits.pagination,
      Param.categoryId: categoryId
    };
    List<Music> musics = [];
    await ApiService.shared.call(
        url: WebService.fetchMusicByCategory,
        param: param,
        completion: (response) {
          musics = MusicsModel.fromJson(response).data ?? [];
        });
    return musics;
  }
}

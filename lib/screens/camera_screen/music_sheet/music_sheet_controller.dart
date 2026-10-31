import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/music_service.dart';
import 'package:untitled/common/api_service/user_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/my_debouncer.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/models/music_categories_model.dart';
import 'package:untitled/models/musics_model.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/utilities/const.dart';

class MusicSheetController extends BaseController {
  Rx<MusicSheetScreenType> selectedPage = MusicSheetScreenType.explore.obs;
  RxList<Music> allMusics = <Music>[].obs;
  RxList<Music> savedMusic = <Music>[].obs;
  RxList<MusicCategory> allCategories = <MusicCategory>[].obs;
  PageController pageController = PageController();
  RxString searchQuery = ''.obs;
  PlayerController playerController = PlayerController();

  @override
  void onReady() {
    fetchAllMusic();
    fetchAllMusicCategory();
    fetchSavedMusic();
    super.onReady();
  }

  void onChangeSegment(MusicSheetScreenType? page) {
    selectedPage.value = page!;
    pageController.jumpToPage(page.value);
  }

  void onPageChange(int page) {
    selectedPage.value = MusicSheetScreenType.values.firstWhere(
      (element) => element.value == page,
    );
  }

  void fetchAllMusic({bool shouldRefresh = false}) async {
    var musics = await MusicService.shared.fetchMusicWithSearch(
        searchQuery.value, shouldRefresh ? 0 : allMusics.length);
    shouldRefresh ? allMusics.value = musics : allMusics.addAll(musics);
  }

  void fetchAllMusicCategory() async {
    var categories = await MusicService.shared.fetchMusicCategories();
    allCategories.value = categories;
  }

  void fetchSavedMusic() async {
    var musics = await MusicService.shared.fetchSavedMusic();
    savedMusic.value = musics;
  }

  void bookmarkTheMusic(Music music) {
    List<int> musicId =
        SessionManager.shared.getUser()?.getSavedMusicIdsList() ?? [];
    if (music.isSaved) {
      musicId.remove(music.id ?? 0);
      savedMusic.removeWhere((element) => element.id == music.id);
    } else {
      musicId.add(music.id ?? 0);
      if (selectedPage.value != MusicSheetScreenType.saved) {
        savedMusic.add(music);
      }
    }

    UserService.shared.editProfile(savedMusicIds: musicId, completion: (p0) {});
  }

  void selectMusic({required Music music, bool isFromCategorySheet = false}) {
    pause();
    if (isFromCategorySheet) {
      Get.back();
    }
    Get.back(result: music);
  }

  void search(String query) async {
    MyDebouncer.shared.run(() {
      searchQuery.value = query;
      fetchAllMusic(shouldRefresh: true);
    });
  }

  /// Player

  Rx<Music?> selectedMusicToPlay = Rx(null);
  Rx<PlayerStatus> playerStatus = PlayerStatus.loading.obs;

  void startMusic(Music music) {
    if (selectedMusicToPlay.value == music) {
      selectedMusicToPlay.value = null;
      pause();
      return;
    }
    selectedMusicToPlay.value = music;
    playerStatus.value = PlayerStatus.loading;
    DefaultCacheManager()
        .getSingleFile(music.sound?.addBaseURL() ?? '')
        .then((value) async {
      await playerController.preparePlayer(path: value.path);
      play();
      playerController.setFinishMode(finishMode: FinishMode.pause);
      playerController.onPlayerStateChanged.listen((event) {
        playerStatus.value =
            event.isPlaying ? PlayerStatus.playing : PlayerStatus.paused;
      });
    });
  }

  void playPause() {
    if (playerStatus.value == PlayerStatus.playing) {
      pause();
    } else {
      play();
    }
  }

  void play() {
    playerController.startPlayer(forceRefresh: false);
  }

  void pause() {
    playerController.pausePlayer();
  }
}

enum MusicSheetScreenType {
  explore(0),
  category(1),
  saved(2);

  final int value;

  const MusicSheetScreenType(this.value);
}

enum PlayerStatus { loading, playing, paused }

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/reel_service.dart';
import 'package:untitled/common/api_service/user_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/models/musics_model.dart';
import 'package:untitled/models/reel_model.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/utilities/const.dart';

class MusicReelsScreenController extends BaseController {
  final Music? music;
  RxBool isSaved = false.obs;

  RxList<Reel> reels = RxList();

  PlayerController playerController = PlayerController();
  Rx<Duration> duration = Duration().obs;
  RxBool isPlaying = false.obs;
  RxDouble progress = 0.0.obs;

  MusicReelsScreenController(this.music);

  @override
  void onReady() {
    isSaved.value = music?.isSaved ?? false;
    fetchReels();
    setPlayer();
    super.onReady();
  }

  void setPlayer() async {
    await Future.delayed(Duration(milliseconds: 500));
    DefaultCacheManager()
        .getSingleFile(music?.sound?.addBaseURL() ?? '')
        .then((value) async {
      await playerController.preparePlayer(path: value.path);
      playerController.setFinishMode(finishMode: FinishMode.pause);
      duration.value =
          Duration(milliseconds: await playerController.getDuration());
      playerController.onPlayerStateChanged.listen((event) {
        isPlaying.value = event.isPlaying;
      });
      playerController.onCurrentDurationChanged.listen((event) {
        progress.value = event / duration.value.inMilliseconds;
      });
    });
  }

  void onProgressChange(double value) {
    playerController.seekTo((value * duration.value.inMilliseconds).toInt());
  }

  void playPause() {
    if (isPlaying.value) {
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

  Future<void> fetchReels() async {
    isLoading.value = true;
    reels.addAll(await ReelService.shared
        .fetchReelsByMusic(musicId: music?.id ?? 0, start: reels.length));
    isLoading.value = false;
  }

  void bookmarkTheMusic() {
    isSaved.value = !isSaved.value;
    List<int> musicId =
        SessionManager.shared.getUser()?.getSavedMusicIdsList() ?? [];
    if (music?.isSaved ?? false) {
      musicId.remove(music?.id ?? 0);
    } else {
      musicId.add(music?.id ?? 0);
    }
    UserService.shared.editProfile(savedMusicIds: musicId, completion: (p0) {});
  }

  @override
  void onClose() {
    playerController.dispose();
    super.onClose();
  }
}

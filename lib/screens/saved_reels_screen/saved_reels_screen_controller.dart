import 'package:get/get.dart';
import 'package:untitled/common/api_service/reel_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/models/reel_model.dart';

class SavedReelsScreenController extends BaseController {
  RxList<Reel> reels = RxList();

  @override
  void onReady() {
    fetchReels();
    super.onReady();
  }

  Future<void> fetchReels({bool shouldRefresh = false}) async {
    isLoading.value = true;
    var newReels = await ReelService.shared
        .fetchSavedReels(start: shouldRefresh ? 0 : reels.length);
    if (shouldRefresh) {
      reels.clear();
    }
    reels.addAll(newReels);
    isLoading.value = false;
  }
}

import 'package:get/get.dart';
import 'package:untitled/common/api_service/reel_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/models/reel_model.dart';

class SingleReelScreenController extends BaseController {
  RxList<Reel> reels = RxList();
  num reelId;

  SingleReelScreenController(this.reelId);

  @override
  void onReady() {
    fetchReel();
    super.onReady();
  }

  void fetchReel() async {
    isLoading.value = true;
    var reel = await ReelService.shared.fetchReelById(reelId: reelId);
    if (reel != null) {
      reels.value = [reel];
    }
    isLoading.value = false;
  }
}

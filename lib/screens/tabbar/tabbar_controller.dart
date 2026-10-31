import 'package:get/get.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/firebase_notification_manager.dart';
import 'package:untitled/common/managers/share_manager.dart';
import 'package:untitled/common/managers/ws_manager.dart';
import 'package:untitled/screens/profile_screen/profile_screen.dart';
import 'package:untitled/screens/rooms_screen/single_room/single_room_screen.dart';
import 'package:untitled/screens/single_post_screen/single_post_screen.dart';
import 'package:untitled/screens/single_reel_screen/single_reel_screen.dart';

class TabBarController extends BaseController {
  int selectedTab = 0;

  @override
  void onInit() {
    super.onInit();
    handleShare();
    FirebaseNotificationManager.shared.setupListener();
    // App 启动已登录（冷启动恢复会话）时也连接自建 WS
    WsManager.shared.connect();
  }

  void selectIndex(int index) {
    selectedTab = index;
    update();
  }

  void handleShare() async {
    ShareManager.shared.listen((key, id) {
      switch (key) {
        case ShareKeys.user:
          Get.to(() => ProfileScreen(userId: id),
              preventDuplicates: false, opaque: false);
        case ShareKeys.post:
          Get.to(() => SinglePostScreen(postId: id),
              preventDuplicates: false, opaque: false);
        case ShareKeys.reel:
          Get.to(() => SingleReelScreen(reelId: id),
              preventDuplicates: false, opaque: false);
        case ShareKeys.room:
          Get.to(() => SingleRoomScreen(roomId: id),
              preventDuplicates: false, opaque: false);
      }
    });
  }
}

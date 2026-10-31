import 'package:untitled/common/api_service/user_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/models/registration.dart';

class RandomScreenController extends BaseController {
  User? user;

  @override
  void onInit() {
    super.onInit();
    getProfile();
  }

  void next() async {
    user = null;
    update();
    getProfile();
  }

  void getProfile() {
    isLoading.value = true;
    Future.delayed(const Duration(seconds: 2), () {
      UserService.shared.fetchRandomProfile((user) {
        this.user = user;
        isLoading.value = false;
        update();
      });
    });
  }
}

import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/models/registration.dart';

import 'reel_model.dart';

extension ReelModelExtension on Reel {
  bool get isSaved =>
      SessionManager.shared
          .getUser()
          ?.getSavedReelIdsList()
          .contains(this.id ?? 0) ??
      false;

  void saveToggle() {
    var user = SessionManager.shared.getUser();
    var newIds = (user?.getSavedReelIdsList() ?? []);
    if (isSaved) {
      newIds.removeWhere((element) => element == id);
    } else {
      newIds.add(id ?? 0);
    }
    user?.savedReelIds = newIds.join(',');
    SessionManager.shared.setUser(user);
  }

  bool get isMyReel => userId == SessionManager.shared.getUserID();
}

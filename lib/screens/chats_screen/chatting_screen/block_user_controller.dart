import 'package:get/get.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'package:untitled/common/api_service/user_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/screens/sheets/confirmation_sheet.dart';

/// 屏蔽/取消屏蔽用户。
///
/// 屏蔽状态存 users.block_user_ids（服务端），
/// 聊天会话里的 iBlocked / iAmBlocked 由后端
/// ChatService::conversationPayloadFor 动态计算，无需客户端同步。
class BlockUserController extends BaseController {
  void blockUser(User? user, Function() completion) {
    Future.delayed(const Duration(milliseconds: 1), () {
      showColibriBottomSheet(ConfirmationSheet(
        desc: LKeys.blockDesc,
        buttonTitle: LKeys.block,
        onTap: () {
          var myUser = SessionManager.shared.getUser();
          myUser?.blockUserIds = '${myUser.blockUserIds ?? ''}${user?.id},';
          SessionManager.shared.setUser(myUser);
          UserService.shared.blockUser(user?.id ?? 0, () {
            completion();
          });
        },
      ));
    });
  }

  void unblockUser(User? user, Function() completion) {
    Future.delayed(const Duration(milliseconds: 1), () {
      showColibriBottomSheet(ConfirmationSheet(
        desc: LKeys.unblockDesc,
        buttonTitle: LKeys.unBlock,
        onTap: () {
          UserService.shared.unblockUser(user?.id ?? 0, () {
            var myUser = SessionManager.shared.getUser();
            myUser?.blockUserIds = (myUser?.blockUserIds ?? '')
                .split(',')
                .where((id) => id != '${user?.id}')
                .join(',');
            SessionManager.shared.setUser(myUser);
            completion();
          });
        },
      ));
    });
  }
}

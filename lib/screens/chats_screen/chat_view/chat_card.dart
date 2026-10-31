import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/date_time_extension.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/int_extension.dart';
import 'package:untitled/common/managers/context_menu_widget.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/chat.dart';
import 'package:untitled/screens/chats_screen/chats_screen_controller.dart';
import 'package:untitled/screens/chats_screen/chatting_screen/chatting_view.dart';
import 'package:untitled/screens/extra_views/back_button.dart';
import 'package:untitled/utilities/const.dart';

class ChatCard extends StatelessWidget {
  final ChatUserRoom chatUserRoom;
  final ChatsScreensController controller;

  const ChatCard(
      {Key? key, required this.chatUserRoom, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: ContextMenuWidget(
        child: GestureDetector(
          onTap: () {
            Get.to(() => ChattingView(chatUserRoom: chatUserRoom),
                opaque: false);
          },
          child: Container(
            decoration: const ShapeDecoration(
                shape: SmoothRectangleBorder(
                    borderRadius: SmoothBorderRadius.all(SmoothRadius(
                        cornerRadius: 8, cornerSmoothing: cornerSmoothing))),
                color: cLightBg),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Row(
              children: [
                MyCachedProfileImage(
                  imageUrl: chatUserRoom.profileImage,
                  fullName: chatUserRoom.title,
                  width: 50,
                  height: 50,
                  cornerRadius: 15,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chatUserRoom.title ?? '',
                              style: MyTextStyle.gilroyBold(size: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const VerifyIcon()
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        chatUserRoom.lastMsg ?? '',
                        style: MyTextStyle.gilroyLight(
                            size: 14, color: cLightText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      chatUserRoom.time?.timeAgo() ?? '',
                      style:
                          MyTextStyle.gilroyLight(size: 14, color: cLightText),
                    ),
                    Opacity(
                      opacity: chatUserRoom.newMsgCount != 0 ? 1 : 0,
                      child: Container(
                        padding: const EdgeInsets.only(
                            top: 7.5, bottom: 6, left: 6, right: 6),
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: cPrimary),
                        child: Text(
                          (chatUserRoom.newMsgCount == -1
                              ? ""
                              : chatUserRoom.newMsgCount?.makeToString() ?? ''),
                          style: MyTextStyle.gilroySemiBold(
                              size: 12, color: cBlack),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
        menuProvider: (request) {
          return Menu(children: [
            MenuAction(
              title: chatUserRoom.newMsgCount == 0
                  ? LKeys.markAsUnread.tr
                  : LKeys.markAsRead.tr,
              callback: () => controller.markToggle(chatUserRoom),
            ),
            MenuAction(
              title: LKeys.clearChat.tr,
              callback: () => controller.clearChat(chatUserRoom),
            ),
            MenuAction(
              title: LKeys.deleteChat.tr,
              callback: () => controller.deleteChat(chatUserRoom),
            ),
          ]);
        },
      ),
    );
  }
}

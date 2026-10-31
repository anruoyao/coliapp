import 'package:flutter/material.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/string_extension.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/managers/share_manager.dart';
import 'package:untitled/common/widgets/menu.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/room_model.dart';
import 'package:untitled/screens/chats_screen/chat_room_view/screens/invite_someone_screen/invite_someone_screen.dart';
import 'package:untitled/screens/chats_screen/chat_room_view/screens/join_requests_screen.dart';
import 'package:untitled/screens/chats_screen/chat_room_view/screens/room_member_screen/room_members_screen.dart';
import 'package:untitled/screens/chats_screen/chat_room_view/screens/room_settings_screen.dart';
import 'package:untitled/screens/chats_screen/chatting_screen/chatting_controller.dart';
import 'package:untitled/screens/report_screen/report_sheet.dart';
import 'package:untitled/screens/rooms_screen/room_controller.dart';
import 'package:untitled/screens/rooms_screen/room_sheet.dart';
import 'package:untitled/screens/sheets/confirmation_sheet.dart';
import 'package:untitled/utilities/const.dart';

class RoomMenu extends StatelessWidget {
  final ChattingController controller;

  const RoomMenu({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Room? room = controller.room;
    var isAdmin = room?.getUserAccessType() == GroupUserAccessType.admin ||
        room?.getUserAccessType() == GroupUserAccessType.coAdmin;
    String notificationTitle = (room?.isMute ?? 0) == 1
        ? LKeys.unMuteNotification
        : LKeys.muteNotification;
    var textStyle = MyTextStyle.gilroyMedium();
    return isAdmin
        ? adminMenu(textStyle, room)
        : Menu(
            onSelect: (value) {
              switch (value) {
                case LKeys.roomInfo:
                  if (room != null) {
                    showColibriBottomSheet(
                        RoomSheet(
                          room: room,
                          isFromInfo: true,
                          controller: RoomController(controller.room ?? Room()),
                        ),
                        isScrollControlled: true);
                  }
                  break;
                case LKeys.unMuteNotification:
                  controller.muteUnMuteNotification();
                  break;
                case LKeys.muteNotification:
                  controller.muteUnMuteNotification();
                  break;
                case LKeys.shareThisRoom:
                  shareRoom(room);
                  break;
                case LKeys.leaveThisRoom:
                  showColibriBottomSheet(
                    ConfirmationSheet(
                      desc: LKeys.leaveRoomDesc,
                      buttonTitle: LKeys.leaveRoom,
                      onTap: controller.leaveRoom,
                    ),
                  );
                  break;

                case LKeys.deleteThisRoom:
                  controller.deleteRoomByModerator();
                  break;
                case LKeys.reportRoom:
                  showColibriBottomSheet(ReportSheet(room: room),
                      isScrollControlled: true);
                  break;
              }
            },
            items: [
              popupMenuItem(LKeys.roomInfo, textStyle),
              popupMenuItem(notificationTitle, textStyle),
              popupMenuItem(LKeys.shareThisRoom, textStyle),
              popupMenuItem(LKeys.reportRoom, textStyle),
              popupMenuItem(
                  LKeys.leaveThisRoom, MyTextStyle.gilroyMedium(color: cRed)),
              if (SessionManager.shared.getUser()?.isModerator == 1)
                popupMenuItem(
                  LKeys.deleteThisRoom,
                  MyTextStyle.gilroyMedium(color: cRed),
                ),
            ],
          );
  }

  Widget adminMenu(TextStyle textStyle, Room? room) {
    String notificationTitle = (room?.isMute ?? 0) == 1
        ? LKeys.unMuteNotification
        : LKeys.muteNotification;
    return Menu(
      onSelect: (value) {
        if (value == LKeys.roomInfo) {}
        switch (value) {
          case LKeys.roomSettings:
            Get.to(() => RoomSettingScreen(room: room), opaque: false)
                ?.then((room) {
              if (room is Room) {
                print(room);
                controller.fetchDetailWithAPI();
              }
            });
            break;
          case LKeys.joinRequests:
            Get.to(() => JoinRequestsScreen(controller: controller),
                opaque: false);
            break;
          case LKeys.unMuteNotification:
            controller.muteUnMuteNotification();
            break;
          case LKeys.muteNotification:
            controller.muteUnMuteNotification();
            break;
          case LKeys.roomMembers:
            Get.to(() => RoomMembersScreen(chattingController: controller),
                opaque: false);
            break;
          case LKeys.inviteSomeone:
            Get.to(() => InviteSomeoneScreen(room: room), opaque: false);
            break;
          case LKeys.shareThisRoom:
            shareRoom(room);
            break;
          case LKeys.deleteThisRoom:
            showColibriBottomSheet(
              ConfirmationSheet(
                desc: LKeys.deleteRoomDesc,
                buttonTitle: LKeys.delete,
                onTap: () {
                  controller.deleteRoom();
                },
              ),
            );
            break;
          case LKeys.leaveThisRoom:
            showColibriBottomSheet(
              ConfirmationSheet(
                desc: LKeys.leaveRoomDesc,
                buttonTitle: LKeys.leaveRoom,
                onTap: controller.leaveRoom,
              ),
            );
            break;
        }
      },
      items: [
        popupMenuItem(LKeys.roomSettings, textStyle),
        popupMenuItem(LKeys.joinRequests, textStyle),
        popupMenuItem(notificationTitle, textStyle),
        popupMenuItem(LKeys.roomMembers, textStyle),
        popupMenuItem(LKeys.inviteSomeone, textStyle),
        popupMenuItem(LKeys.shareThisRoom, textStyle),
        popupMenuItem(
            (room?.getUserAccessType() == GroupUserAccessType.admin
                ? LKeys.deleteThisRoom
                : LKeys.leaveThisRoom),
            MyTextStyle.gilroyMedium(color: cRed))
      ],
      color: cPrimary,
    );
  }

  PopupMenuItem popupMenuItem(String text, TextStyle style) {
    return PopupMenuItem(
      value: text,
      child: text.toTextTR(style),
    );
  }

  void shareRoom(Room? room) {
    ShareManager.shared
        .shareTheContent(key: ShareKeys.room, value: room?.id?.toInt() ?? 0);
  }
}

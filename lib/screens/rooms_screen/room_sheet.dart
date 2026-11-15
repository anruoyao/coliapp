import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/date_time_extension.dart';
import 'package:untitled/common/extensions/int_extension.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/room_model.dart';
import 'package:untitled/screens/profile_screen/profile_screen.dart';
import 'package:untitled/screens/rooms_screen/room_card.dart';
import 'package:untitled/screens/rooms_screen/room_controller.dart';

class RoomSheet extends StatelessWidget {
  const RoomSheet({
    super.key,
    this.isFromInfo = false,
    required this.room,
    required this.controller,
  });

  final bool isFromInfo;
  final Room room;
  final RoomController controller;

  @override
  Widget build(BuildContext context) {
    return ColibriSheetSurface(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      child: GetBuilder<RoomController>(
        init: controller,
        builder: (controller) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColibriSheetHeader(
                title: room.title ?? '',
                trailing: const ColibriSheetCloseButton(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ClipOval(
                    child: MyCachedImage(
                      imageUrl: room.photo,
                      width: 56,
                      height: 56,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.title ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1C1C1E),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${(room.totalMember ?? 0).makeToString()} ${LKeys.members.tr}',
                          style: const TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (room.getInterests().isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  children: room
                      .getInterests()
                      .map((interest) => RoomCardInterestTagToShow(
                            tag: interest.title ?? '',
                          ))
                      .toList(),
                ),
              ],
              if ((room.desc ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  room.desc ?? '',
                  style: const TextStyle(
                    color: Color(0xFF3A3A3C),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
              if (isFromInfo) ...[
                const SizedBox(height: 20),
                _infoView(context),
              ] else if (room.isPrivate == 0 &&
                  room.isJoinRequestEnable == 1) ...[
                const SizedBox(height: 16),
                Text(
                  LKeys.requestToJoinThisRoom.tr,
                  style: const TextStyle(
                    color: Color(0xFF1C1C1E),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  LKeys.requestToJoinDesc.tr,
                  style: const TextStyle(
                    color: Color(0xFF636366),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
              if (!isFromInfo) ...[
                const SizedBox(height: 18),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: controller.joinOrRequestOrAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1C1C1E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(_actionTitle(controller)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _actionTitle(RoomController controller) {
    if (room.getUserAccessType() == GroupUserAccessType.invited) {
      return LKeys.acceptInvitation.tr;
    }
    if (room.isJoinRequestEnable == 1) {
      return controller.room.getUserAccessType() ==
              GroupUserAccessType.requested
          ? LKeys.requested.tr
          : LKeys.requestToJoin.tr;
    }
    return LKeys.joinThisRoom.tr;
  }

  Widget _infoView(BuildContext context) {
    final members = room.roomUsers ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (members.isNotEmpty)
          SizedBox(
            height: 56,
            child: Stack(
              children: List.generate(members.length, (index) {
                return Positioned(
                  left: index * 36,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      shape: BoxShape.circle,
                    ),
                    child: MyCachedImage(
                      imageUrl: members[index].profile,
                      width: 48,
                      height: 48,
                      cornerRadius: 48,
                    ),
                  ),
                );
              }),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          '${LKeys.createdOn.tr} ${DateTime.parse(room.createdAt ?? '').formatFullDate()}',
          style: const TextStyle(color: Color(0xFF636366), fontSize: 14),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            Get.back();
            Get.to(() => ProfileScreen(userId: room.admin?.id ?? 0),
                opaque: false);
          },
          child: Text(
            '${LKeys.createdBy.tr} @${room.admin?.username ?? 'unknown'}',
            style: const TextStyle(
              color: Color(0xFF007AFF),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

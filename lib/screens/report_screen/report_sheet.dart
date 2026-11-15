import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/int_extension.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/posts_model.dart';
import 'package:untitled/models/reel_model.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/models/room_model.dart';
import 'package:untitled/models/setting_model.dart';
import 'package:untitled/screens/report_screen/report_controller.dart';
import 'package:untitled/screens/rooms_you_own/create_room_screen/create_room_screen.dart';

class ReportSheet extends StatelessWidget {
  final User? user;
  final Room? room;
  final Post? post;
  final Reel? reel;

  const ReportSheet({super.key, this.user, this.room, this.post, this.reel});

  @override
  Widget build(BuildContext context) {
    final controller = ReportController();
    return ColibriSheetSurface(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: SafeArea(
        top: false,
        child: GetBuilder<ReportController>(
          init: controller,
          builder: (controller) => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                ColibriSheetHeader(
                  title: sheetHeading().tr,
                  trailing: const ColibriSheetCloseButton(),
                ),
                if (room != null || user != null || post != null) ...[
                  const SizedBox(height: 12),
                  _ReportedItem(
                    imageUrl: image(),
                    title: title(),
                    subtitle: subTitle(),
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  LKeys.selectReason.tr,
                  style: const TextStyle(
                    color: Color(0xFF636366),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                _reasonSelector(controller),
                const SizedBox(height: 16),
                Text(
                  LKeys.tellUsMore.tr,
                  style: const TextStyle(
                    color: Color(0xFF636366),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                MyTextField(
                  controller: controller.reasonTextController,
                  placeHolder: LKeys.writeSomething,
                  isEditor: true,
                  color: const Color(0xFFF2F2F7),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: () =>
                        controller.submitReport(room, post, user, reel),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1C1C1E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(LKeys.submitReport.tr),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String sheetHeading() {
    if (room != null) return LKeys.reportRoom;
    if (post != null) return LKeys.reportPost;
    if (user != null) return LKeys.reportUser;
    if (reel != null) return LKeys.reportReel;
    return LKeys.report;
  }

  String? image() {
    if (room != null) return room?.photo;
    final content = post?.content;
    if (content != null && content.isNotEmpty) {
      return content.first.thumbnail ?? content.first.content;
    }
    if (user != null) return user?.profile;
    return null;
  }

  String title() {
    if (room != null) return room?.title ?? '';
    if (post != null) return post?.desc ?? '';
    if (user != null) return user?.fullName ?? '';
    return reel?.description ?? '';
  }

  String subTitle() {
    var count = 0;
    var label = '';
    if (room != null) {
      count = room?.totalMember?.toInt() ?? 0;
      label = LKeys.members.tr;
    } else if (post != null) {
      count = post?.likesCount?.toInt() ?? 0;
      label = LKeys.likes.tr;
    } else if (user != null) {
      count = (user?.followers ?? 0).toInt();
      label = LKeys.followers.tr;
    }
    return '${count.makeToString()} $label';
  }

  Widget _reasonSelector(ReportController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<SettingCommon>(
        borderRadius: BorderRadius.circular(12),
        dropdownColor: Colors.white,
        value: controller.selectedReason,
        elevation: 8,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        style: const TextStyle(color: Color(0xFF1C1C1E), fontSize: 15),
        onChanged: controller.onReasonChange,
        items: controller.reasons
            .map(
              (reason) => DropdownMenuItem<SettingCommon>(
                value: reason,
                child: Text(reason.title ?? ''),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ReportedItem extends StatelessWidget {
  const _ReportedItem({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
  });

  final String? imageUrl;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MyCachedImage(
          imageUrl: imageUrl,
          width: 48,
          height: 48,
          cornerRadius: 12,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1C1C1E),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle.trim().isNotEmpty)
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

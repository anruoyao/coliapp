import 'package:flutter/material.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/managers/haptic_manager.dart';
import 'package:untitled/common/widgets/guest_auth_sheet.dart';
import 'package:untitled/utilities/const.dart';

/// 受限 Tab 的访客锁定态（通知 / 聊天）。
///
/// 不创建任何业务控制器、不发起任何请求；仅展示「登录后可用」提示与登录入口。
class GuestLockedView extends StatelessWidget {
  /// 页面类型（决定图标与文案）。
  final GuestLockedKind kind;

  const GuestLockedView({super.key, required this.kind});

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle) = switch (kind) {
      GuestLockedKind.notifications => (
          Icons.notifications_none_rounded,
          '通知登录后可用',
          '登录后可查看点赞、评论、关注与系统通知',
        ),
      GuestLockedKind.chats => (
          Icons.chat_bubble_outline_rounded,
          '聊天登录后可用',
          '登录后可与好友、群聊收发消息',
        ),
    };

    return Scaffold(
      backgroundColor: cWhite,
      appBar: AppBar(
        backgroundColor: cWhite,
        surfaceTintColor: cWhite,
        elevation: 0,
        title: Text(kind == GuestLockedKind.notifications ? '通知' : '聊天',
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 17, color: cMainText)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 软绿双圆 + 居中图标
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cPrimarySoft,
                  border: Border.all(
                      color: cPrimary.withValues(alpha: 0.30), width: 1.2),
                ),
                child: Icon(icon, size: 48, color: cGreen),
              ),
              const SizedBox(height: 22),
              Text(title,
                  textAlign: TextAlign.center,
                  style: MyTextStyle.gilroyBold(size: 18, color: cMainText)),
              const SizedBox(height: 9),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style:
                      MyTextStyle.gilroyLight(color: cLightText, size: 13.5)),
              const SizedBox(height: 26),
              GestureDetector(
                onTap: () {
                  HapticManager.shared.selection();
                  openAuthSheet();
                },
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 38),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cPrimary,
                    borderRadius: BorderRadius.circular(23),
                    boxShadow: [
                      BoxShadow(
                          color: cPrimary.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.login_rounded, color: cWhite, size: 18),
                      const SizedBox(width: 8),
                      Text('登 录',
                          style:
                              MyTextStyle.gilroyBold(size: 15, color: cWhite)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum GuestLockedKind { notifications, chats }

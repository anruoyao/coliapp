import 'package:flutter/material.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/managers/guest_session.dart';
import 'package:untitled/common/managers/haptic_manager.dart';
import 'package:untitled/common/widgets/guest_auth_sheet.dart';
import 'package:untitled/screens/extra_views/logo_tag.dart';
import 'package:untitled/utilities/const.dart';

/// 访客态「我的」页：品牌视觉 + 登录/注册双主按钮 + 功能引导。
///
/// 设计：顶部品牌绿弧形头图（半透明装饰圆 + Logo + 欢迎语），
/// 下方白色浮层卡片承载身份说明、能力亮点与双按钮，避免空表单式单调。
/// [onBrowse] 点击「先随便看看」时回到首页继续浏览。
class GuestMePage extends StatelessWidget {
  final VoidCallback? onBrowse;

  const GuestMePage({super.key, this.onBrowse});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final platformName = GuestSession.i.platformName.isNotEmpty
        ? GuestSession.i.platformName
        : 'Chatter';

    return Scaffold(
      backgroundColor: cBG,
      body: Stack(
        children: [
          // ===== 顶部品牌绿弧形头图 =====
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(36)),
              child: Container(
                height: topPad + 268,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF46EF7D), Color(0xFF149E4B)],
                  ),
                ),
                child: Stack(
                  children: [
                    // 装饰：大小不一的半透明圆（右上角 + 左下角）
                    Positioned(
                      top: topPad - 18,
                      right: -46,
                      child: _Blob(size: 150, opacity: 0.12),
                    ),
                    Positioned(
                      top: topPad + 64,
                      right: 34,
                      child: _Blob(size: 64, opacity: 0.10),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -24,
                      child: _Blob(size: 120, opacity: 0.10),
                    ),
                    // 文案（上移留出与浮层卡片的间距，避免被白卡遮挡）
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: 88,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LogoTag(isWhite: true, width: 132),
                          const SizedBox(height: 12),
                          Text('欢迎来到 $platformName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: MyTextStyle.gilroyBold(
                                  size: 22, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('先逛逛公开内容，登录后解锁完整体验',
                              style: MyTextStyle.gilroyLight(
                                  size: 13.5, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ===== 下方内容（浮层卡片） =====
          ListView(
            padding: EdgeInsets.only(
                top: topPad + 196, left: 16, right: 16, bottom: 24),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: cWhite,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 28,
                        offset: const Offset(0, 12)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                  child: Column(
                    children: [
                      // 访客身份图标
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cPrimarySoft,
                          border: Border.all(
                              color: cPrimary.withValues(alpha: 0.35),
                              width: 1.2),
                        ),
                        child: const Icon(Icons.person_outline_rounded,
                            size: 32, color: cGreen),
                      ),
                      const SizedBox(height: 14),
                      Text('你正在以访客身份浏览',
                          style: MyTextStyle.gilroyBold(
                              size: 18, color: cMainText)),
                      const SizedBox(height: 8),
                      Text(
                        '注册或登录账号，即可与社区互动、接收消息通知并发布自己的动态',
                        textAlign: TextAlign.center,
                        style: MyTextStyle.gilroyLight(
                            size: 13.5, color: cLightText),
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1, color: cLightBg),
                      const SizedBox(height: 16),
                      // 能力亮点
                      const _FeatureRow(
                        icon: Icons.favorite_border_rounded,
                        title: '互动社区',
                        subtitle: '点赞、评论、表情反应与关注作者',
                      ),
                      const SizedBox(height: 14),
                      const _FeatureRow(
                        icon: Icons.forum_outlined,
                        title: '私信与通知',
                        subtitle: '和好友群聊收发消息，实时收到提醒',
                      ),
                      const SizedBox(height: 14),
                      const _FeatureRow(
                        icon: Icons.edit_note_rounded,
                        title: '创作与发布',
                        subtitle: '发布图文、投票帖子与限时故事',
                      ),
                      const SizedBox(height: 22),
                      // 主按钮：登录
                      GestureDetector(
                        onTap: () {
                          HapticManager.shared.selection();
                          openAuthSheet();
                        },
                        child: Container(
                          height: 52,
                          width: double.infinity,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: cPrimary,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: cPrimary.withValues(alpha: 0.38),
                                  blurRadius: 16,
                                  offset: const Offset(0, 7)),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.login_rounded,
                                  color: cWhite, size: 20),
                              const SizedBox(width: 8),
                              Text('登 录',
                                  style: MyTextStyle.gilroyBold(
                                      size: 16, color: cWhite)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 11),
                      // 次按钮：创建账号
                      GestureDetector(
                        onTap: () {
                          HapticManager.shared.selection();
                          openAuthSheet(initialSignUp: true);
                        },
                        child: Container(
                          height: 52,
                          width: double.infinity,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: cWhite,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: cPrimary.withValues(alpha: 0.6),
                                width: 1.5),
                          ),
                          child: Text('创建新账号',
                              style: MyTextStyle.gilroySemiBold(
                                  size: 15.5, color: cGreen)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // 继续浏览
              TextButton(
                onPressed: () {
                  HapticManager.shared.selection();
                  onBrowse?.call();
                },
                style: TextButton.styleFrom(foregroundColor: cLightText),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('先随便看看',
                        style: MyTextStyle.gilroyMedium(
                            size: 13.5, color: cLightText)),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 15, color: cLightText),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 能力亮点行（软绿图标圆角块 + 标题/说明）。
class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: cPrimarySoft,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, size: 21, color: cGreen),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style:
                      MyTextStyle.gilroySemiBold(size: 14.5, color: cMainText)),
              const SizedBox(height: 2),
              Text(subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MyTextStyle.gilroyLight(size: 12, color: cLightText)),
            ],
          ),
        ),
      ],
    );
  }
}

/// 头图装饰圆。
class _Blob extends StatelessWidget {
  final double size;
  final double opacity;

  const _Blob({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: Colors.white.withValues(alpha: opacity * 1.6), width: 1.4),
      ),
      child: Center(
        child: Container(
          width: size * 0.62,
          height: size * 0.62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: opacity),
          ),
        ),
      ),
    );
  }
}

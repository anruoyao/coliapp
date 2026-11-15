import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/managers/guest_session.dart';
import 'package:untitled/common/managers/haptic_manager.dart';
import 'package:untitled/common/widgets/guest_auth_sheet.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/utilities/const.dart';

/// Guest account entry point with sign-in actions and a concise feature list.
class GuestMePage extends StatelessWidget {
  final VoidCallback? onBrowse;

  const GuestMePage({super.key, this.onBrowse});

  @override
  Widget build(BuildContext context) {
    final platformName = GuestSession.i.platformName.isNotEmpty
        ? GuestSession.i.platformName
        : 'Chatter';
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cBG,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            Text(
              LKeys.commonMe.tr,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: cLightBg),
                  ),
                  child: Icon(Icons.person_outline_rounded,
                      size: 29, color: colors.onSurfaceVariant),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LKeys.guestMode.tr,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        LKeys.guestSignInPrompt
                            .trParams({'p1': '${platformName}'}),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: () {
                  HapticManager.shared.selection();
                  openAuthSheet();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(LKeys.commonSignIn.tr),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  HapticManager.shared.selection();
                  openAuthSheet(initialSignUp: true);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primary,
                  side: BorderSide(color: colors.outlineVariant),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(LKeys.commonCreateAccount.tr),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              LKeys.guestAvailableAfterSignIn.tr,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cLightBg),
              ),
              child: Column(
                children: [
                  _GuestFeatureRow(
                    icon: Icons.favorite_border_rounded,
                    title: LKeys.guestCommunity.tr,
                    subtitle: LKeys.guestCommunityDesc.tr,
                  ),
                  const Divider(height: 1, indent: 58),
                  _GuestFeatureRow(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: LKeys.guestMessagesAndNotifications.tr,
                    subtitle: LKeys.guestMessagesAndNotificationsDesc.tr,
                  ),
                  const Divider(height: 1, indent: 58),
                  _GuestFeatureRow(
                    icon: Icons.edit_note_rounded,
                    title: LKeys.guestPublishContent.tr,
                    subtitle: LKeys.guestPublishContentDesc.tr,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                HapticManager.shared.selection();
                onBrowse?.call();
              },
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(LKeys.guestContinueBrowsing.tr),
              style: TextButton.styleFrom(
                foregroundColor: colors.primary,
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestFeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _GuestFeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 68),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 21, color: colors.onSurfaceVariant),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

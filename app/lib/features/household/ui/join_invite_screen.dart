import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../state/join_invite_controller.dart';

/// Where a tapped invite link lands once the person is signed in (household
/// ADR-0005): the household, the profile they would claim and who asked, then
/// join or not now.
class JoinInviteScreen extends StatelessWidget {
  const JoinInviteScreen({super.key});

  static const path = '/join';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<JoinInviteController>();
    final failure = controller.actionFailure;
    final preview = controller.preview;
    final nest = NestTheme.of(context);
    return NestScaffold(
      leading: const NestBrandLockup(semanticsLabel: AppCopy.appName),
      trailing: const [AccountMenuButton()],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NestRiseIn(
              child: NestIntro(
                eyebrow: AccessCopy.inviteLinkEyebrow,
                title: switch ((preview, failure)) {
                  (final preview?, _) => AccessCopy.inviteLinkTitle(
                    preview.householdName,
                  ),
                  (null, null) => AccessCopy.inviteLinkChecking,
                  (null, _) => AccessCopy.inviteLinkRefused,
                },
                body: preview == null
                    ? null
                    : AccessCopy.inviteLinkBody(
                        memberName: preview.memberName,
                        role: preview.role,
                        invitedBy: preview.invitedBy,
                      ),
              ),
            ),
            const SizedBox(height: NestSpace.xxl),
            if (failure != null) ...[
              NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.danger,
              ),
              const SizedBox(height: NestSpace.lg),
            ],
            if (preview != null) ...[
              NestRiseIn(
                index: 2,
                child: NestCard(
                  variant: NestCardVariant.tinted,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const NestIconTile(
                        icon: LucideIcons.house,
                        tint: NestTileTint.basil,
                      ),
                      const SizedBox(height: NestSpace.md),
                      Text(
                        AccessCopy.roleName(preview.role),
                        style: nest.text.title,
                      ),
                      const SizedBox(height: NestSpace.sm),
                      Text(
                        AccessCopy.roleBlurb(preview.role),
                        style: nest.text.bodySecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: NestSpace.xl),
              NestButton(
                label: AccessCopy.inviteLinkTitle(preview.householdName),
                isLoading: controller.isBusy,
                onPressed: controller.isBusy ? null : controller.join,
              ),
            ] else if (failure == null)
              const NestLoadingView(rows: 2),
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: preview == null && failure != null
                  ? AccessCopy.inviteLinkClose
                  : AccessCopy.inviteLinkNotNow,
              variant: NestButtonVariant.ghost,
              onPressed: controller.isBusy ? null : controller.notNow,
            ),
          ],
        ),
      ),
    );
  }
}

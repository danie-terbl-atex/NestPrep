import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/household_place_redirect.dart';
import '../../../app/referral_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../../referrals/ui/referral_mention.dart';
import '../../referrals/ui/referrals_offered.dart';
import '../model/household_view.dart';
import '../model/member_role.dart';
import '../state/invite_step_controller.dart';
import 'household_room.dart';
import 'invite_option_list.dart';
import 'invite_person_sheet.dart';
import 'sent_invite_row.dart';

/// "Who else keeps this house running?" — how an admin invites anybody from
/// the people screen (household ADR-0003). While a new household's setup step
/// is open, the same route shows the setup flow instead, whose family step
/// invites through [invite] (onboarding ADR-0001).
///
/// Every control is usable the moment it starts to arrive (design-system
/// ADR-0002), and *Skip for now* is always there: the step is an invitation,
/// not a gate.
class InviteStepScreen extends StatelessWidget {
  const InviteStepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InviteStepController>();
    final view = context.watch<HouseholdView>();
    final failure = controller.actionFailure;
    final hasInvited = controller.sent.isNotEmpty;
    final making = controller.making;

    return NestScaffold(
      leading: backLeading(context),
      floatingAction: NestButton(
        label: hasInvited ? AccessCopy.setupDone : AccessCopy.setupSkip,
        variant: hasInvited
            ? NestButtonVariant.primary
            : NestButtonVariant.outline,
        icon: hasInvited ? LucideIcons.check : null,
        isExpanded: false,
        isLoading: controller.isBusy && !hasInvited && making == null,
        onPressed: controller.isBusy ? null : () => _leave(context, view),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: NestSpace.huge),
        children: [
          const NestRiseIn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: NestSpace.lg),
                NestIntro(
                  title: AccessCopy.setupTitle,
                  body: AccessCopy.setupBody,
                ),
              ],
            ),
          ),
          const SizedBox(height: NestSpace.xl),
          if (failure != null) ...[
            NestBanner(
              message: AppCopy.failure(failure),
              tone: NestBannerTone.danger,
              actionLabel: AppCopy.back,
              onAction: controller.dismissActionFailure,
            ),
            const SizedBox(height: NestSpace.md),
          ],
          if (controller.shareUnavailable) ...[
            const NestBanner(
              message: AccessCopy.inviteShareUnavailable,
              tone: NestBannerTone.warning,
            ),
            const SizedBox(height: NestSpace.md),
          ],
          if (hasInvited || making != null) ...[
            const NestSectionHeader(title: AccessCopy.setupInvited),
            const SizedBox(height: NestSpace.sm),
            for (final invite in controller.sent)
              Padding(
                padding: const EdgeInsets.only(bottom: NestSpace.sm),
                child: SentInviteRow(
                  key: ValueKey(invite.memberId),
                  invite: invite,
                  onShare: () => unawaited(controller.shareAgain(invite)),
                ),
              ),
            if (making != null)
              Padding(
                padding: const EdgeInsets.only(bottom: NestSpace.sm),
                child: SentInviteRow.making(
                  displayName: making.displayName,
                  role: making.role,
                ),
              ),
            const SizedBox(height: NestSpace.lg),
          ],
          InviteOptionList(
            isLocked: isFullOnFreePlan(context, view),
            onChoose: (role) =>
                unawaited(invite(context, controller, view, role)),
          ),
          // Give a month, get a month: another family is the next person to
          // tell (subscriptions ADR-0002).
          if (referralsOffered(context)) ...[
            const SizedBox(height: NestSpace.xl),
            ReferralMention(
              onTap: () =>
                  context.push(ReferralRoute.pathFor(view.household.id)),
            ),
          ],
        ],
      ),
    );
  }

  /// The room check, the sheet, the profile and code, and the paywall if the
  /// free plan refused it. Answers whether somebody was invited.
  static Future<bool> invite(
    BuildContext context,
    InviteStepController controller,
    HouseholdView view,
    MemberRole suggested,
  ) async {
    if (!await ensureRoomForAnother(context, view)) return false;
    if (!context.mounted) return false;
    final draft = await showInvitePersonSheet(
      context: context,
      suggestedRole: suggested,
    );
    if (draft == null) return false;
    final invited = await controller.invite(
      displayName: draft.displayName,
      role: draft.role,
      guardianConsent: draft.guardianConsent,
    );
    if (!context.mounted) return invited;
    await offerRoomIfRefused(
      context,
      controller,
      context.read<HouseholdView>(),
    );
    return invited;
  }

  /// Done and skip are the same act: the step is closed, and the household
  /// opens. From the people screen there is no step to close — just go back.
  static Future<void> _leave(BuildContext context, HouseholdView view) async {
    final controller = context.read<InviteStepController>();
    if (view.household.isWaitingOnInviteStep) {
      final closed = await controller.finish();
      if (!closed || !context.mounted) return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(firstPlaceFor(view));
    }
  }
}

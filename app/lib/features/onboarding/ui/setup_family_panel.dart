import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../../avatars/ui/member_avatar.dart';
import '../../household/model/household_view.dart';
import '../../household/model/member.dart';
import '../../household/model/member_role.dart';
import '../../household/state/household_controller.dart';
import '../../household/state/invite_step_controller.dart';
import '../../household/ui/household_room.dart';
import '../../household/ui/invite_option_list.dart';
import '../../household/ui/invite_step_screen.dart';
import '../../household/ui/member_sheet.dart';
import '../../household/ui/sent_invite_row.dart';
import '../state/setup_flow_controller.dart';
import 'onboarding_header.dart';

/// Step four of five: who shares the nest (onboarding ADR-0001). Children
/// first, who need no phone and are children from the moment they are added
/// (household ADR-0009), then the grown-ups and children with a phone, by
/// invite (household ADR-0003). Everything is skippable; Twig hops for each
/// person added.
class SetupFamilyPanel extends StatelessWidget {
  const SetupFamilyPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<SetupFlowController>();
    final invites = context.watch<InviteStepController>();
    final household = context.watch<HouseholdController>();
    final view = context.watch<HouseholdView>();
    final invitedIds = {for (final sent in invites.sent) sent.memberId};
    final children = [
      for (final member in view.members)
        if (member.role == MemberRole.kid && !invitedIds.contains(member.id))
          member,
    ];
    final failure = invites.actionFailure ?? household.actionFailure;
    final making = invites.making;
    final lastAdded = flow.lastAdded;
    final hasAdded = flow.added > 0 || view.members.length > 1;

    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        OnboardingHeader(
          title: OnboardingCopy.familyTitle,
          body: OnboardingCopy.familyBody,
          twigPose: NestTwigPose.welcome,
          twigLine: lastAdded == null
              ? OnboardingCopy.twigFamily
              : OnboardingCopy.twigFamilyAdded(lastAdded),
          twigAction: flow.added == 0
              ? NestTwigAction.wave
              : NestTwigAction.hop,
          twigActionKey: flow.added,
        ),
        const SizedBox(height: NestSpace.xl),
        if (failure != null) ...[
          NestBanner(
            message: AppCopy.failure(failure),
            tone: NestBannerTone.danger,
            actionLabel: AppCopy.back,
            onAction: () {
              invites.dismissActionFailure();
              household.dismissActionFailure();
            },
          ),
          const SizedBox(height: NestSpace.md),
        ],
        if (invites.shareUnavailable) ...[
          const NestBanner(
            message: AccessCopy.inviteShareUnavailable,
            tone: NestBannerTone.warning,
          ),
          const SizedBox(height: NestSpace.md),
        ],
        const NestSectionHeader(title: OnboardingCopy.familyChildren),
        const SizedBox(height: NestSpace.sm),
        for (final child in children)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: _PersonRow(member: child),
          ),
        NestCard(
          variant: NestCardVariant.flat,
          padding: EdgeInsets.zero,
          child: NestListRow(
            leading: const NestIconTile(
              icon: LucideIcons.smile,
              tint: NestTileTint.butter,
            ),
            title: OnboardingCopy.familyAddChild,
            subtitle: OnboardingCopy.familyAddChildBlurb,
            trailing: Icon(
              isFullOnFreePlan(context, view)
                  ? LucideIcons.lock
                  : LucideIcons.circlePlus,
              size: NestSize.iconMedium,
              color: NestTheme.of(context).colors.accentInk,
            ),
            onTap: household.isBusy
                ? null
                : () => unawaited(_addChild(context, household, view, flow)),
          ),
        ),
        const SizedBox(height: NestSpace.xxl),
        const NestSectionHeader(title: OnboardingCopy.familyInvite),
        const SizedBox(height: NestSpace.sm),
        for (final sent in invites.sent)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: SentInviteRow(
              key: ValueKey(sent.memberId),
              invite: sent,
              onShare: () => unawaited(invites.shareAgain(sent)),
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
        InviteOptionList(
          isLocked: isFullOnFreePlan(context, view),
          onChoose: (role) =>
              unawaited(_invite(context, invites, view, flow, role)),
        ),
        const SizedBox(height: NestSpace.xl),
        NestStepActions(
          nextLabel: hasAdded ? OnboardingCopy.next : OnboardingCopy.skip,
          nextIcon: LucideIcons.arrowRight,
          onNext: invites.isBusy || household.isBusy ? null : flow.next,
        ),
      ],
    );
  }

  static Future<void> _addChild(
    BuildContext context,
    HouseholdController household,
    HouseholdView view,
    SetupFlowController flow,
  ) async {
    final today = context.read<HouseholdClock>().today;
    if (!await ensureRoomForAnother(context, view)) return;
    if (!context.mounted) return;
    final draft = await showMemberSheet(
      context: context,
      today: today,
      initialRole: MemberRole.kid,
      initialColor: MemberColor.firstUnused(
        view.members.map((member) => member.color),
      ),
    );
    if (draft == null) return;
    final added = await household.addMember(
      displayName: draft.displayName,
      color: draft.color,
      role: draft.role,
      birthday: draft.birthday,
      guardianConsent: draft.guardianConsent,
    );
    if (added) flow.noteAdded(draft.displayName);
    if (!context.mounted) return;
    await offerRoomIfRefused(context, household, view);
  }

  static Future<void> _invite(
    BuildContext context,
    InviteStepController invites,
    HouseholdView view,
    SetupFlowController flow,
    MemberRole role,
  ) async {
    final invited = await InviteStepScreen.invite(context, invites, view, role);
    final sent = invites.sent;
    if (invited && sent.isNotEmpty) flow.noteAdded(sent.last.displayName);
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) => NestCard(
    variant: NestCardVariant.flat,
    padding: EdgeInsets.zero,
    child: NestListRow(
      leading: MemberAvatar(member: member),
      title: member.displayName,
      subtitle: AccessCopy.roleName(member.role),
      trailing: Icon(
        LucideIcons.check,
        size: NestSize.iconMedium,
        color: NestTheme.of(context).colors.success,
      ),
    ),
  );
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/household_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../../kid_accounts/ui/kid_sign_in_link.dart';
import '../data/invite_sharer.dart';
import '../model/household_area.dart';
import '../model/household_view.dart';
import '../model/member.dart';
import '../model/member_role.dart';
import '../state/household_controller.dart';
import 'household_places.dart';
import 'household_screen.dart';
import 'household_settings_sheet.dart';
import 'invite_sheet.dart';
import 'member_row.dart';
import 'member_sheet.dart';
import 'your_access_card.dart';

/// Everything the household screen shows once the household has loaded: the
/// people, grouped by what they are (household ADR-0003), and the places
/// that hang off them.
class HouseholdBody extends StatelessWidget {
  const HouseholdBody({
    required this.view,
    required this.controller,
    super.key,
  });

  final HouseholdView view;
  final HouseholdController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Row(
          children: [
            Expanded(
              child: NestSectionHeader(
                title: view.household.name,
                actionIcon: view.viewerIsAdmin ? Icons.person_add_alt : null,
                actionLabel: view.viewerIsAdmin
                    ? AppCopy.householdAddMember
                    : null,
                onAction: view.viewerIsAdmin
                    ? () => HouseholdScreen.addMember(context, controller)
                    : null,
              ),
            ),
            if (view.viewerIsAdmin)
              NestIconButton(
                icon: Icons.tune,
                label: AppCopy.householdEditHousehold,
                variant: NestIconButtonVariant.plain,
                onPressed: () => _editHousehold(context, view),
              ),
          ],
        ),
        const SizedBox(height: NestSpace.md),
        if (!view.permissions.isFamily) ...[
          YourAccessCard(permissions: view.permissions),
          const SizedBox(height: NestSpace.lg),
        ],
        for (final (title, roles) in _groups)
          if (view.members.where((m) => roles.contains(m.role)).toList()
              case final members when members.isNotEmpty) ...[
            NestSectionHeader(title: title),
            const SizedBox(height: NestSpace.sm),
            for (final member in members)
              Padding(
                padding: const EdgeInsets.only(bottom: NestSpace.sm),
                child: MemberRow(
                  key: ValueKey(member.id),
                  member: member,
                  isViewer: member.isClaimedBy(view.viewerUid),
                  canManage: view.viewerIsAdmin,
                  accessSummary: _accessSummaryOf(member),
                  onAccess: view.viewerIsAdmin && member.role.isRestricted
                      ? () => context.push(
                          HouseholdRoute.accessPathFor(
                            view.household.id,
                            member.id,
                          ),
                        )
                      : null,
                  onEdit: () => _editMember(context, member),
                  onInvite: member.isClaimed
                      ? null
                      : () => _invite(context, member),
                  onRemove: member.isClaimedBy(view.viewerUid)
                      ? null
                      : () => _remove(context, member),
                ),
              ),
            const SizedBox(height: NestSpace.md),
          ],
        const SizedBox(height: NestSpace.sm),
        if (view.viewerIsAdmin) ...[
          // Inviting is a card, not an icon in a corner: it is how a
          // household grows, and invite rate is a number the beta measures
          // (household ADR-0003).
          NestCard(
            variant: NestCardVariant.tinted,
            padding: EdgeInsets.zero,
            child: NestListRow(
              leading: const NestIconTile(icon: Icons.group_add_outlined),
              title: AccessCopy.peopleInvite,
              subtitle: AccessCopy.peopleInviteBody,
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  context.push(HouseholdRoute.setupPathFor(view.household.id)),
            ),
          ),
          const SizedBox(height: NestSpace.lg),
          // Kid sign-in: a child on their own tablet (accounts ADR-0003). Only
          // an admin can make a code or read the devices, so only an admin
          // sees the way in.
          KidSignInLink(householdId: view.household.id),
          const SizedBox(height: NestSpace.lg),
        ],
        HouseholdPlaces(view: view),
        const SizedBox(height: NestSpace.xxl),
        NestButton(
          label: AppCopy.householdLeave,
          variant: NestButtonVariant.outline,
          icon: Icons.logout,
          onPressed: view.isTheOnlyAdmin ? null : () => _leave(context),
        ),
        if (view.isTheOnlyAdmin)
          Padding(
            padding: const EdgeInsets.only(top: NestSpace.sm),
            child: Text(
              AppCopy.householdProblemLastAdmin,
              style: NestTheme.of(context).text.caption
                  .copyWith(color: NestTheme.of(context).colors.inkTertiary),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: NestSpace.huge),
      ],
    );
  }

  /// People in the order a household thinks of them: the family, the
  /// children, then the people who help (household ADR-0003).
  static const _groups = [
    (AccessCopy.peopleFamily, [MemberRole.admin, MemberRole.parent]),
    (AccessCopy.peopleChildren, [MemberRole.kid]),
    (AccessCopy.peopleHelpers, [MemberRole.helper, MemberRole.carer]),
  ];

  /// What a kid, helper or carer can see, for the line under their name.
  String? _accessSummaryOf(Member member) {
    if (member.role.isFamily) return null;
    if (view.isAwaitingAccessChoice(member)) return AccessCopy.accessNotChosen;
    final permissions = view.permissionsOf(member);
    return AccessCopy.accessSummary([
      for (final area in HouseholdArea.values)
        if (permissions.canUse(area)) area,
    ]);
  }

  /// The household's name and the zone its days are counted in. The zone is
  /// what every due date and every all-day event means (`ENG-21`), so a
  /// household that moves changes it here once.
  Future<void> _editHousehold(BuildContext context, HouseholdView view) async {
    final settings = await showHouseholdSettingsSheet(
      context: context,
      household: view.household,
    );
    if (settings == null) return;
    await controller.renameHousehold(
      name: settings.name,
      timeZone: settings.timeZone,
    );
  }

  Future<void> _editMember(BuildContext context, Member member) async {
    final result = await showMemberSheet(
      context: context,
      today: context.read<HouseholdClock>().today,
      existing: member,
    );
    if (result == null) return;
    await controller.updateMember(
      memberId: member.id,
      displayName: result.displayName,
      color: result.color,
      role: result.role,
      birthday: result.birthday,
      guardianConsent: result.guardianConsent,
    );
  }

  Future<void> _invite(BuildContext context, Member member) async {
    await controller.createInvite(member.id);
    final invite = controller.lastInvite;
    if (invite == null || !context.mounted) return;
    await showInviteSheet(
      context: context,
      member: member,
      invite: invite,
      onShare: () => unawaited(
        context.read<InviteSharer>().shareCode(
          householdName: view.household.name,
          code: invite.code,
        ),
      ),
    );
    controller.dismissInvite();
  }

  Future<void> _remove(BuildContext context, Member member) async {
    final confirmed = await showNestConfirm(
      context: context,
      title: AppCopy.householdRemoveConfirm,
      message: member.displayName,
      confirmLabel: AppCopy.householdRemove,
      cancelLabel: AppCopy.householdCancel,
      isDangerous: true,
    );
    if (confirmed != true) return;
    await controller.removeMember(member.id);
  }

  Future<void> _leave(BuildContext context) async {
    final confirmed = await showNestConfirm(
      context: context,
      title: AppCopy.householdLeaveConfirm,
      message: view.household.name,
      confirmLabel: AppCopy.householdLeave,
      cancelLabel: AppCopy.householdCancel,
      isDangerous: true,
    );
    if (confirmed != true) return;
    await controller.leaveHousehold();
  }
}

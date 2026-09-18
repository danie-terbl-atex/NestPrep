import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../model/household_view.dart';
import '../model/member.dart';
import '../state/household_controller.dart';
import 'household_settings_sheet.dart';
import 'invite_sheet.dart';
import 'member_row.dart';
import 'member_sheet.dart';

/// The household: who is in it, who has joined, and the admin actions. All four
/// async states come from the kit (`FE-08`).
class HouseholdScreen extends StatelessWidget {
  const HouseholdScreen({super.key});

  static const routeName = 'household';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HouseholdController>();
    final failure = controller.actionFailure;
    return NestScaffold(
      title: AppCopy.householdTitle,
      // This screen is pushed from a tab, so it carries the way back itself
      // rather than relying on the system gesture alone (`FE-17`). A deep link
      // straight here has nothing to pop, and then there is no button.
      leading: context.canPop()
          ? NestIconButton(
              icon: Icons.arrow_back,
              label: AppCopy.back,
              variant: NestIconButtonVariant.plain,
              onPressed: context.pop,
            )
          : null,
      trailing: const [AccountMenuButton()],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.lg),
              child: NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.danger,
                actionLabel: AppCopy.back,
                onAction: controller.dismissActionFailure,
              ),
            ),
          Expanded(
            child: NestAsyncView<HouseholdView>(
              state: controller.view,
              isEmpty: (view) => view.members.isEmpty,
              onRetry: controller.retry,
              emptyBuilder: (_) => NestEmptyView(
                title: AppCopy.householdEmptyTitle,
                message: AppCopy.householdEmptyBody,
                icon: Icons.group_outlined,
                actionLabel: AppCopy.householdAddMember,
                onAction: () => _addMember(context, controller),
              ),
              dataBuilder: (_, view) =>
                  _HouseholdBody(view: view, controller: controller),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _addMember(
    BuildContext context,
    HouseholdController controller,
  ) async {
    final result = await showMemberSheet(context: context);
    if (result == null) return;
    await controller.addMember(
      displayName: result.displayName,
      color: result.color,
      role: result.role,
    );
  }
}

class _HouseholdBody extends StatelessWidget {
  const _HouseholdBody({required this.view, required this.controller});

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
                    ? () => HouseholdScreen._addMember(context, controller)
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
        for (final member in view.members)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: MemberRow(
              key: ValueKey(member.id),
              member: member,
              isViewer: member.isClaimedBy(view.viewerUid),
              canManage: view.viewerIsAdmin,
              onEdit: () => _editMember(context, member),
              onInvite: member.isClaimed
                  ? null
                  : () => _invite(context, member),
              onRemove: member.isClaimedBy(view.viewerUid)
                  ? null
                  : () => _remove(context, member),
            ),
          ),
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
    final result = await showMemberSheet(context: context, existing: member);
    if (result == null) return;
    await controller.updateMember(
      memberId: member.id,
      displayName: result.displayName,
      color: result.color,
      role: result.role,
    );
  }

  Future<void> _invite(BuildContext context, Member member) async {
    await controller.createInvite(member.id);
    final invite = controller.lastInvite;
    if (invite == null || !context.mounted) return;
    await showInviteSheet(context: context, member: member, invite: invite);
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

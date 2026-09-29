import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/ui/back_leading.dart';
import '../model/access_grant.dart';
import '../model/access_level.dart';
import '../model/household_view.dart';
import '../model/member.dart';
import '../state/member_access_controller.dart';
import 'member_access_editor.dart';

/// What one kid, helper or carer can see and do, chosen area by area by an
/// admin (household ADR-0003). Reached from their row on the people screen.
///
/// The person is read live from the household, so a rename or a removal
/// shows here at once; the choices being made are the controller's draft
/// until saved.
class MemberAccessScreen extends StatelessWidget {
  const MemberAccessScreen({required this.memberId, super.key});

  final String memberId;

  @override
  Widget build(BuildContext context) {
    final view = context.watch<HouseholdView>();
    final member = view.memberById(memberId);
    final controller = context.watch<MemberAccessController>();
    final canSave =
        member != null &&
        member.role.isRestricted &&
        view.viewerIsAdmin &&
        controller.hasChangesFrom(_saved(view, member));

    return NestScaffold(
      title: AccessCopy.accessTitle,
      leading: backLeading(context),
      floatingAction:
          member == null || member.role.isFamily || !view.viewerIsAdmin
          ? null
          : NestButton(
              label: controller.justSaved
                  ? AccessCopy.accessSaved
                  : AccessCopy.accessSave,
              icon: controller.justSaved ? Icons.check : null,
              isExpanded: false,
              isLoading: controller.isSaving,
              onPressed: canSave ? () => unawaited(controller.save()) : null,
            ),
      body: switch (member) {
        null => const NestEmptyView(
          title: AccessCopy.accessNotFoundTitle,
          message: AccessCopy.accessNotFoundBody,
          icon: Icons.person_off_outlined,
        ),
        Member(role: final role) when role.isFamily => const NestEmptyView(
          title: AccessCopy.accessFamilyTitle,
          message: AccessCopy.accessFamilyBody,
          icon: Icons.family_restroom_outlined,
        ),
        _ when !view.viewerIsAdmin => NestEmptyView(
          title: AccessCopy.accessTitle,
          message: AppCopy.householdProblem(HouseholdProblem.notAnAdmin),
          icon: Icons.lock_outline,
        ),
        final member => MemberAccessEditor(
          member: member,
          controller: controller,
          failureMessage: switch (controller.actionFailure) {
            null => null,
            final failure => AppCopy.failure(failure),
          },
        ),
      },
    );
  }

  /// What the household holds now, the draft's baseline.
  static AccessGrant _saved(HouseholdView view, Member member) =>
      view.permissionsOf(member).grant ?? AccessGrant.uniform(AccessLevel.none);
}

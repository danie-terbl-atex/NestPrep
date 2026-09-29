import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/nanny_hub_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../household/ui/member_choice_sheet.dart';
import '../model/nanny_hub_view.dart';
import '../state/nanny_hub_controller.dart';
import 'children_list.dart';
import 'hub_places.dart';
import 'latest_handover_card.dart';
import 'past_shifts.dart';
import 'shift_hero_card.dart';

/// Everything the hub's home shows once it has loaded. Each section arrives a
/// step after the one above it and then rests (design-system ADR-0002); under
/// reduce-motion they are simply there.
class HubHome extends StatelessWidget {
  const HubHome({required this.view, required this.controller, super.key});

  final NannyHubView view;
  final NannyHubController controller;

  String get _householdId => controller.householdId;

  Future<void> _start(BuildContext context, {String? carerMemberId}) async {
    final shiftId = await controller.startShift(carerMemberId: carerMemberId);
    if (shiftId == null || !context.mounted) return;
    await context.push(NannyHubRoute.shiftPathFor(_householdId, shiftId));
  }

  /// Family starts a shift for somebody who is not — a carer without their
  /// phone, a grandparent babysitting.
  Future<void> _startFor(BuildContext context) async {
    final choice = await showMemberChoiceSheet(
      context: context,
      title: NannyCopy.startShiftForTitle,
      members: controller.carersToStartFor,
    );
    if (choice == null || !context.mounted) return;
    await _start(context, carerMemberId: choice.id);
  }

  @override
  Widget build(BuildContext context) {
    final access = controller.access;
    final hub = view.hub;
    final latest = hub.latestSummary;
    final sections = <Widget>[
      ShiftHeroCard(
        hub: hub,
        access: access,
        memberById: controller.memberById,
        onStartMine: () => _start(context),
        onStartForSomebody: access.isFamily && access.canEdit
            ? () => _startFor(context)
            : null,
        onOpenShift: (shiftId) =>
            context.push(NannyHubRoute.shiftPathFor(_householdId, shiftId)),
      ),
      if (latest != null)
        LatestHandoverCard(
          summary: latest,
          carer: controller.memberById(latest.carerMemberId),
          onOpen: () => context.push(
            NannyHubRoute.summaryPathFor(_householdId, latest.shiftId),
          ),
        ),
      ChildrenList(
        children: view.children,
        healthOf: controller.healthOf,
        onOpen: (childId) =>
            context.push(NannyHubRoute.childPathFor(_householdId, childId)),
      ),
      HubPlaces(hub: hub, householdId: _householdId),
      PastShifts(
        summaries: hub.summaries,
        memberById: controller.memberById,
        onOpen: (shiftId) =>
            context.push(NannyHubRoute.summaryPathFor(_householdId, shiftId)),
      ),
      if (!access.canEdit) const NestBanner(message: NannyCopy.viewOnlyNote),
    ];
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        for (final (index, section) in sections.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.xl),
            child: NestRiseIn(index: index, child: section),
          ),
      ],
    );
  }
}

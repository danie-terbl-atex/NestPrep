import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/nanny_hub_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../../shared/time/household_clock.dart';
import '../../household/model/household_view.dart';
import '../../household/ui/member_choice_sheet.dart';
import '../model/nanny_hub_view.dart';
import '../model/shift_window.dart';
import '../state/nanny_hub_controller.dart';
import '../state/shift_pass_controller.dart';
import 'children_list.dart';
import 'hub_clock.dart';
import 'hub_places.dart';
import 'latest_handover_card.dart';
import 'live_photos_card.dart';
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
    final flags = context.watch<FeatureFlagsController>();
    // Somebody else's shift, live: the parents' way into its photos
    // (nanny-hub ADR-0004). A carer sends from shift mode instead.
    final liveShifts = [
      if (flags.isOn(FeatureFlag.nannyPhotoUpdates))
        for (final shift in hub.openShifts)
          if (shift.carerMemberId != access.viewerMemberId)
            (
              shiftId: shift.id,
              carer:
                  controller.memberById(shift.carerMemberId)?.displayName ??
                  NannyPhotoCopy.somebody,
            ),
    ];
    // A carer kept to their booked shifts is told when the household closes
    // for them again (nanny-hub ADR-0006).
    final openUntil = context.watch<HouseholdView>().viewerIsShiftOnly
        ? switch (context.watch<ShiftPassController>().window) {
            AsyncData(value: OnBookedShift(:final booking)) => booking.closesAt,
            _ => null,
          }
        : null;
    final sections = <Widget>[
      if (openUntil != null)
        NestBanner(
          message: NannyBookingCopy.openUntil(
            context.read<HouseholdClock>().timeOf(openUntil),
          ),
          tone: NestBannerTone.success,
        ),
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
      if (liveShifts.isNotEmpty)
        LivePhotosCard(
          shifts: liveShifts,
          onOpen: (shiftId) =>
              context.push(NannyHubRoute.photosPathFor(_householdId, shiftId)),
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

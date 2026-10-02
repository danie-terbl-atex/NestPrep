import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/nanny_hub_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../model/nanny_hub.dart';

/// The four places a carer needs during a shift, each a row that says how much
/// is in it. Pushed, so back returns to the hub (`FE-17`).
class HubPlaces extends StatelessWidget {
  const HubPlaces({required this.hub, required this.householdId, super.key});

  final NannyHub hub;
  final String householdId;

  @override
  Widget build(BuildContext context) {
    final places = [
      (
        LucideIcons.siren,
        NestTileTint.guava,
        NannyCopy.emergency,
        NannyCopy.emergencyBody(hub.contacts.length),
        NannyHubRoute.emergencyPathFor(householdId),
      ),
      (
        LucideIcons.images,
        NestTileTint.lilac,
        NannyCopy.houseGuide,
        NannyCopy.houseGuideBody(hub.guide.length),
        NannyHubRoute.guidePathFor(householdId),
      ),
      (
        LucideIcons.gavel,
        NestTileTint.basil,
        NannyCopy.houseRules,
        NannyCopy.houseRulesBody(hub.rules.length),
        NannyHubRoute.rulesPathFor(householdId),
      ),
      (
        LucideIcons.listChecks,
        NestTileTint.butter,
        NannyCopy.checklists,
        NannyCopy.checklistsBody(hub.checklistItemCount),
        NannyHubRoute.checklistsPathFor(householdId),
      ),
      // ---- pickups (nanny-hub ADR-0005), switchable by its flag ----
      if (context.watch<FeatureFlagsController>().isOn(
        FeatureFlag.nannyPickups,
      ))
        (
          LucideIcons.footprints,
          NestTileTint.accent,
          NannyPickupCopy.place,
          NannyPickupCopy.placeBody,
          NannyHubRoute.pickupsPathFor(householdId),
        ),
      // ---- shift-only access (nanny-hub ADR-0006), switchable by its flag ----
      if (context.watch<FeatureFlagsController>().isOn(
        FeatureFlag.nannyShiftOnly,
      )) ...[
        (
          LucideIcons.calendarCheck,
          NestTileTint.basil,
          NannyBookingCopy.bookings,
          NannyBookingCopy.bookingsBody,
          NannyHubRoute.bookingsPathFor(householdId),
        ),
        (
          LucideIcons.keyRound,
          NestTileTint.butter,
          NannyBookingCopy.codes,
          NannyBookingCopy.codesBody,
          NannyHubRoute.codesPathFor(householdId),
        ),
      ],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NestSectionHeader(title: NannyCopy.forTheShift),
        const SizedBox(height: NestSpace.sm),
        for (final (icon, tint, title, subtitle, path) in places)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: NestCard(
              variant: NestCardVariant.flat,
              padding: EdgeInsets.zero,
              child: NestListRow(
                leading: NestIconTile(icon: icon, tint: tint),
                title: title,
                subtitle: subtitle,
                trailing: const Icon(LucideIcons.chevronRight),
                onTap: () => context.push(path),
              ),
            ),
          ),
      ],
    );
  }
}

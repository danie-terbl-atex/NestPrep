import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/nanny_hub_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
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
        Icons.emergency_outlined,
        NestTileTint.pink,
        NannyCopy.emergency,
        NannyCopy.emergencyBody(hub.contacts.length),
        NannyHubRoute.emergencyPathFor(householdId),
      ),
      (
        Icons.photo_library_outlined,
        NestTileTint.sky,
        NannyCopy.houseGuide,
        NannyCopy.houseGuideBody(hub.guide.length),
        NannyHubRoute.guidePathFor(householdId),
      ),
      (
        Icons.gavel_outlined,
        NestTileTint.mint,
        NannyCopy.houseRules,
        NannyCopy.houseRulesBody(hub.rules.length),
        NannyHubRoute.rulesPathFor(householdId),
      ),
      (
        Icons.checklist_rtl_outlined,
        NestTileTint.peach,
        NannyCopy.checklists,
        NannyCopy.checklistsBody(hub.checklistItemCount),
        NannyHubRoute.checklistsPathFor(householdId),
      ),
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
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(path),
              ),
            ),
          ),
      ],
    );
  }
}

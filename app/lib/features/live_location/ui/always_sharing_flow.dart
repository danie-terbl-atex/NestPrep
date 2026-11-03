import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../../household/model/household_view.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/ui/premium_gate.dart';
import '../model/family_place.dart';
import '../state/always_sharing.dart';

/// Premium, then the stores' prominent disclosure, then the OS prompts, then
/// the engine (live-location ADR-0003). Returns without starting when the
/// person says no at any step.
Future<void> startAlwaysSharing(
  BuildContext context, {
  required String memberId,
  required List<FamilyPlace> places,
}) async {
  if (!await ensurePremium(context, feature: PremiumFeature.familyLocation)) {
    return;
  }
  if (!context.mounted) return;
  final household = context.read<HouseholdView>().household;
  await startAlwaysSharingFor(
    context,
    householdId: household.id,
    householdName: household.name,
    timeZone: context.read<HouseholdClock>().timeZoneName,
    memberId: memberId,
    places: places,
  );
}

/// The disclosure and the engine, for a phone that knows its household
/// without the household shell — a kid's.
Future<void> startAlwaysSharingFor(
  BuildContext context, {
  required String householdId,
  required String householdName,
  required String timeZone,
  required String memberId,
  List<FamilyPlace> places = const [],
}) async {
  final agreed = await showNestSheet<bool>(
    context: context,
    title: LocationCopy.disclosureTitle,
    builder: (_) => const AlwaysSharingDisclosure(),
  );
  if (agreed != true || !context.mounted) return;
  await context.read<AlwaysSharing>().start(
    AlwaysSharingSubject(
      householdId: householdId,
      memberId: memberId,
      timeZone: timeZone,
      notificationTitle: LocationCopy.notificationTitle,
      notificationBody: LocationCopy.notificationBody(householdName),
      notificationChannelName: LocationCopy.notificationChannel,
      notificationPauseLabel: LocationCopy.notificationPause,
    ),
    places: places,
  );
}

class AlwaysSharingDisclosure extends StatelessWidget {
  const AlwaysSharingDisclosure({super.key});

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Padding(
      padding: const EdgeInsets.all(NestSpace.gutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final point in LocationCopy.disclosurePoints)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.check, color: nest.colors.accent, size: 20),
                  const SizedBox(width: NestSpace.sm),
                  Expanded(child: Text(point, style: nest.text.body)),
                ],
              ),
            ),
          Text(LocationCopy.disclosureNext, style: nest.text.bodySecondary),
          const SizedBox(height: NestSpace.lg),
          NestButton(
            label: LocationCopy.disclosureContinue,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: LocationCopy.disclosureNotNow,
            variant: NestButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}

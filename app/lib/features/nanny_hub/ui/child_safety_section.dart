import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../family_profiles/model/food_rules.dart';
import '../../family_profiles/model/member_health.dart';
import '../../family_profiles/ui/allergy_names.dart';
import '../../family_profiles/ui/family_section_card.dart';
import '../../family_profiles/ui/family_section_empty.dart';
import '../../family_profiles/ui/medication_row.dart';
import '../../family_profiles/ui/severity_look.dart';

/// Allergies and medication, at the top of every card — read from family
/// profiles, never copied (nanny-hub ADR-0003). Each renders its own four
/// states in place, so a slow medication read never holds up the routine
/// below it (`FE-08`). A viewer the grant keeps out is told so plainly: "not
/// shared with you" is not the same as "none", and a carer must never read
/// one as the other.
class ChildSafetySection extends StatelessWidget {
  const ChildSafetySection({
    required this.food,
    required this.health,
    required this.onRetry,
    super.key,
  });

  /// Null when the viewer may not read the child's profile.
  final AsyncState<FoodRules>? food;

  /// Null when the viewer may not read the child's medication.
  final AsyncState<MemberHealth>? health;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FamilySectionCard(
          icon: food == null
              ? Icons.lock_outline
              : Icons.health_and_safety_outlined,
          tint: NestTileTint.pink,
          title: NannyCopy.allergies,
          child: switch (food) {
            null => const _NotShared(
              title: NannyCopy.allergiesHiddenTitle,
              body: NannyCopy.allergiesHiddenBody,
              tone: NestTagTone.warning,
            ),
            AsyncLoading() => const NestSkeleton(height: NestSize.controlLarge),
            AsyncFailure(:final failure) => _Failed(
              message: AppCopy.failure(failure),
              onRetry: onRetry,
            ),
            AsyncData(:final value) => _Allergies(rules: value),
          },
        ),
        const SizedBox(height: NestSpace.lg),
        FamilySectionCard(
          icon: health == null ? Icons.lock_outline : Icons.medication_outlined,
          tint: NestTileTint.peach,
          title: NannyCopy.medication,
          child: switch (health) {
            null => const _NotShared(
              title: NannyCopy.medicationHiddenTitle,
              body: NannyCopy.medicationHiddenBody,
              tone: NestTagTone.neutral,
            ),
            AsyncLoading() => const NestSkeleton(height: NestSize.controlLarge),
            AsyncFailure(:final failure) => _Failed(
              message: AppCopy.failure(failure),
              onRetry: onRetry,
            ),
            AsyncData(:final value) when value.medications.isEmpty =>
              const FamilySectionEmpty(message: NannyCopy.noMedication),
            AsyncData(:final value) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (:id, :medication) in value.inOrderOfTheDay)
                  MedicationRow(key: ValueKey(id), medication: medication),
              ],
            ),
          },
        ),
      ],
    );
  }
}

class _Allergies extends StatelessWidget {
  const _Allergies({required this.rules});

  final FoodRules rules;

  @override
  Widget build(BuildContext context) {
    if (rules.allergies.isEmpty) {
      return const FamilySectionEmpty(message: NannyCopy.noAllergies);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final allergy in rules.allergies)
          Padding(
            key: ValueKey(allergy.key),
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            // The severity is said in words under the name rather than in a
            // tag beside it: at a large text setting a tag and the name
            // cannot share a phone's width, and this row must never clip.
            child: NestToneRow(
              icon: allergy.severity.icon,
              tone: allergy.severity.tone,
              title: allergyName(allergy),
              subtitle: [
                FamilyCopy.severityName(allergy.severity),
                ?allergy.note,
              ].join(' · '),
            ),
          ),
      ],
    );
  }
}

class _NotShared extends StatelessWidget {
  const _NotShared({
    required this.title,
    required this.body,
    required this.tone,
  });

  final String title;
  final String body;
  final NestTagTone tone;

  @override
  Widget build(BuildContext context) => NestToneRow(
    icon: Icons.lock_outline,
    tone: tone,
    title: title,
    subtitle: body,
  );
}

class _Failed extends StatelessWidget {
  const _Failed({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => NestBanner(
    message: message,
    tone: NestBannerTone.danger,
    actionLabel: AppCopy.retry,
    onAction: onRetry,
  );
}

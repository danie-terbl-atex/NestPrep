import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/medication.dart';
import '../model/member_health.dart';
import 'family_section_card.dart';
import 'family_section_empty.dart';
import 'medication_row.dart';

/// A person's medicines in the order of the day, or — for a viewer the rules
/// keep out — a plain statement of whose they are to see. That is not an
/// error, so it is not drawn as one (family-profiles ADR-0001).
///
/// It renders its own four states inside the card, because the rest of the
/// profile has already loaded and must not wait on, or be replaced by, this
/// one read (`FE-08`).
class MedicationSection extends StatelessWidget {
  const MedicationSection({
    required this.isVisible,
    required this.health,
    required this.onRetry,
    required this.onAdd,
    required this.onEdit,
    super.key,
  });

  final bool isVisible;
  final AsyncState<MemberHealth> health;
  final VoidCallback onRetry;

  /// Null when the viewer may not change this person's medication.
  final VoidCallback? onAdd;
  final void Function(String id, Medication medication)? onEdit;

  @override
  Widget build(BuildContext context) {
    return FamilySectionCard(
      icon: isVisible ? Icons.medication_outlined : Icons.lock_outline,
      tint: NestTileTint.butter,
      title: FamilyCopy.sectionMedication,
      actionIcon: Icons.add,
      actionLabel: FamilyCopy.addMedication,
      onAction: isVisible ? onAdd : null,
      child: isVisible
          ? _Medicines(health: health, onRetry: onRetry, onEdit: onEdit)
          : const _Hidden(),
    );
  }
}

class _Medicines extends StatelessWidget {
  const _Medicines({
    required this.health,
    required this.onRetry,
    required this.onEdit,
  });

  final AsyncState<MemberHealth> health;
  final VoidCallback onRetry;
  final void Function(String id, Medication medication)? onEdit;

  @override
  Widget build(BuildContext context) {
    final edit = onEdit;
    return switch (health) {
      AsyncLoading() => const NestSkeleton(height: NestSize.controlLarge),
      AsyncFailure(:final failure) => NestBanner(
        message: AppCopy.failure(failure),
        tone: NestBannerTone.danger,
        actionLabel: AppCopy.retry,
        onAction: onRetry,
      ),
      AsyncData(:final value) when value.medications.isEmpty =>
        const FamilySectionEmpty(message: FamilyCopy.noMedication),
      AsyncData(:final value) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (:id, :medication) in value.inOrderOfTheDay)
            MedicationRow(
              key: ValueKey(id),
              medication: medication,
              onTap: edit == null ? null : () => edit(id, medication),
            ),
        ],
      ),
    };
  }
}

class _Hidden extends StatelessWidget {
  const _Hidden();

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(FamilyCopy.medicationHiddenTitle, style: nest.text.bodyStrong),
        const SizedBox(height: NestSpace.xxs),
        Text(FamilyCopy.medicationHiddenBody, style: nest.text.bodySecondary),
      ],
    );
  }
}

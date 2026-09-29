import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../model/medication.dart';

/// One medicine: its name and dose, and a tag for each time of day it is
/// given — or "When needed" when it has none.
class MedicationRow extends StatelessWidget {
  const MedicationRow({required this.medication, this.onTap, super.key});

  final Medication medication;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final dose = medication.dose;
    final note = medication.note;
    return Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.sm),
      // Its own node, so tapping the medicine is not tapping the section it
      // sits in (`FE-13`).
      child: Semantics(
        container: true,
        button: onTap != null,
        child: NestCard(
          variant: NestCardVariant.tinted,
          padding: const EdgeInsets.all(NestSpace.md),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(medication.name, style: nest.text.bodyStrong),
              if (dose != null) Text(dose, style: nest.text.bodySecondary),
              const SizedBox(height: NestSpace.sm),
              Wrap(
                spacing: NestSpace.sm,
                runSpacing: NestSpace.sm,
                children: [
                  if (medication.isWhenNeeded)
                    const NestTag(
                      label: FamilyCopy.medicationWhenNeeded,
                      icon: Icons.schedule,
                    )
                  else
                    for (final minutes in medication.timesInOrder)
                      NestTag(
                        label: NestDates.timeOfDay(minutes),
                        tone: NestTagTone.accent,
                        icon: Icons.schedule,
                      ),
                ],
              ),
              if (note != null) ...[
                const SizedBox(height: NestSpace.sm),
                Text(note, style: nest.text.caption),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

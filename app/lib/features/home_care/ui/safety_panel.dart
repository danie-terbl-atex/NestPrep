import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/safety/job_safety.dart';
import '../model/safety/precaution.dart';
import 'safety_sources_sheet.dart';

/// A job's safety, first and loudest: the products that must never meet,
/// then what to wear and open, then the two rules that always hold — and
/// where every word of it comes from (home-care ADR-0002).
class SafetyPanel extends StatelessWidget {
  const SafetyPanel({required this.safety, super.key});

  final JobSafety safety;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final danger in safety.dangers) ...[
          NestToneRow(
            icon: Icons.dangerous_outlined,
            tone: NestTagTone.danger,
            title: HomeCareSafetyCopy.neverTogether(
              danger.first.name,
              danger.second.name,
            ),
            subtitle: HomeCareSafetyCopy.hazard(danger.hazard),
          ),
          const SizedBox(height: NestSpace.sm),
        ],
        for (final precaution in safety.precautions) ...[
          NestToneRow(
            icon: _iconFor(precaution),
            tone: _isSerious(precaution)
                ? NestTagTone.warning
                : NestTagTone.neutral,
            title: HomeCareSafetyCopy.precaution(precaution),
            subtitle: HomeCareSafetyCopy.precautionWhy(precaution),
          ),
          const SizedBox(height: NestSpace.sm),
        ],
        const NestToneRow(
          icon: Icons.inventory_2_outlined,
          title: HomeCareSafetyCopy.originalBottles,
          subtitle: HomeCareSafetyCopy.originalBottlesWhy,
        ),
        const SizedBox(height: NestSpace.sm),
        const NestToneRow(
          icon: Icons.local_hospital_outlined,
          title: HomeCareSafetyCopy.accidentTitle,
          subtitle: HomeCareSafetyCopy.accidentBody,
        ),
        const SizedBox(height: NestSpace.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: NestButton(
            label: HomeCareSafetyCopy.sourcesLink,
            icon: Icons.menu_book_outlined,
            variant: NestButtonVariant.ghost,
            size: NestButtonSize.small,
            isExpanded: false,
            onPressed: () => showSafetySources(context),
          ),
        ),
      ],
    );
  }

  static bool _isSerious(Precaution precaution) => switch (precaution) {
    Precaution.corrosive ||
    Precaution.flammable ||
    Precaution.onlyWithWater => true,
    _ => false,
  };

  static IconData _iconFor(Precaution precaution) => switch (precaution) {
    Precaution.corrosive => Icons.science_outlined,
    Precaution.flammable => Icons.local_fire_department_outlined,
    Precaution.onlyWithWater => Icons.water_drop_outlined,
    Precaution.gloves => Icons.back_hand_outlined,
    Precaution.eyeProtection => Icons.visibility_outlined,
    Precaution.freshAir => Icons.air,
    Precaution.patchTest => Icons.crop_square,
    Precaution.keepFromChildren => Icons.child_care_outlined,
    Precaution.keepFromPets => Icons.pets_outlined,
  };
}

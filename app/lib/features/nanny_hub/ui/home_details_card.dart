import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../family_profiles/ui/family_section_card.dart';
import '../../family_profiles/ui/family_section_empty.dart';
import '../model/home_sheet.dart';

/// The address to read to an ambulance, large, and the medical aid a hospital
/// asks for first. Says in place what is missing, beside the way to add it.
class HomeDetailsCard extends StatelessWidget {
  const HomeDetailsCard({required this.sheet, required this.onEdit, super.key});

  final HomeSheet sheet;

  /// Null when the viewer may not change the sheet.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final label = nest.text.label.copyWith(color: nest.colors.inkSecondary);
    final address = sheet.address;
    return FamilySectionCard(
      icon: Icons.home_outlined,
      tint: NestTileTint.sky,
      title: NannyCopy.ourAddress,
      actionLabel: NannyCopy.editHomeDetails,
      onAction: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          switch (address) {
            final String text => SelectableText(text, style: nest.text.title),
            null => const FamilySectionEmpty(message: NannyCopy.noAddress),
          },
          const SizedBox(height: NestSpace.lg),
          Text(NannyCopy.medicalAid, style: label),
          const SizedBox(height: NestSpace.xs),
          if (!sheet.hasMedicalAid)
            const FamilySectionEmpty(message: NannyCopy.noMedicalAid)
          else
            for (final (name, value) in [
              (NannyCopy.medicalAidScheme, sheet.medicalAidScheme),
              (NannyCopy.medicalAidPlan, sheet.medicalAidPlan),
              (NannyCopy.medicalAidNumber, sheet.medicalAidNumber),
            ])
              if (value != null)
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '$name  ', style: nest.text.bodySecondary),
                      TextSpan(text: value, style: nest.text.bodyStrong),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}

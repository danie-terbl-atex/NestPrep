import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/safety/job_safety.dart';
import '../model/safety/precaution.dart';
import 'safety_sources_sheet.dart';

/// Draws one safety line. The default is the plain row; the helper's
/// screens pass one that shows the line in her language with the English
/// beneath and a read-aloud button (home-care ADR-0006).
typedef SafetyRowBuilder = Widget Function({
  required IconData icon,
  required NestTagTone tone,
  required String title,
  String? why,
});

/// One line of a job's safety, in English, as the copy says it.
typedef SafetyLine = ({
  IconData icon,
  NestTagTone tone,
  String title,
  String why,
});

/// A job's safety, first and loudest: the products that must never meet,
/// then what to wear and open, then the two rules that always hold — and
/// where every word of it comes from (home-care ADR-0002).
class SafetyPanel extends StatelessWidget {
  const SafetyPanel({required this.safety, this.rowBuilder, super.key});

  final JobSafety safety;
  final SafetyRowBuilder? rowBuilder;

  /// Every line the panel shows, in order.
  static List<SafetyLine> linesOf(JobSafety safety) => [
    for (final danger in safety.dangers)
      (
        icon: LucideIcons.octagonX,
        tone: NestTagTone.danger,
        title: HomeCareSafetyCopy.neverTogether(
          danger.first.name,
          danger.second.name,
        ),
        why: HomeCareSafetyCopy.hazard(danger.hazard),
      ),
    for (final precaution in safety.precautions)
      (
        icon: _iconFor(precaution),
        tone: _isSerious(precaution)
            ? NestTagTone.warning
            : NestTagTone.neutral,
        title: HomeCareSafetyCopy.precaution(precaution),
        why: HomeCareSafetyCopy.precautionWhy(precaution),
      ),
    (
      icon: LucideIcons.archive,
      tone: NestTagTone.neutral,
      title: HomeCareSafetyCopy.originalBottles,
      why: HomeCareSafetyCopy.originalBottlesWhy,
    ),
    (
      icon: LucideIcons.hospital,
      tone: NestTagTone.neutral,
      title: HomeCareSafetyCopy.accidentTitle,
      why: HomeCareSafetyCopy.accidentBody,
    ),
  ];

  /// The English the panel shows, for asking for a translation.
  static List<String> textsOf(JobSafety safety) => [
    for (final line in linesOf(safety)) ...[line.title, line.why],
  ];

  static Widget _plainRow({
    required IconData icon,
    required NestTagTone tone,
    required String title,
    String? why,
  }) => NestToneRow(icon: icon, tone: tone, title: title, subtitle: why);

  @override
  Widget build(BuildContext context) {
    final row = rowBuilder ?? _plainRow;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in linesOf(safety)) ...[
          row(
            icon: line.icon,
            tone: line.tone,
            title: line.title,
            why: line.why,
          ),
          const SizedBox(height: NestSpace.sm),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: NestButton(
            label: HomeCareSafetyCopy.sourcesLink,
            icon: LucideIcons.bookOpen,
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
    Precaution.corrosive => LucideIcons.flaskConical,
    Precaution.flammable => LucideIcons.flame,
    Precaution.onlyWithWater => LucideIcons.droplet,
    Precaution.gloves => LucideIcons.hand,
    Precaution.eyeProtection => LucideIcons.eye,
    Precaution.freshAir => LucideIcons.wind,
    Precaution.patchTest => LucideIcons.square,
    Precaution.keepFromChildren => LucideIcons.baby,
    Precaution.keepFromPets => LucideIcons.pawPrint,
  };
}

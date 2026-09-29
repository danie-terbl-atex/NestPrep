import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/handover_kind.dart';
import '../model/shift_summary.dart';
import 'handover_look.dart';

/// What a shift held, as a row of tags — "Meal · 2", "Nap · 1" — with an
/// incident in the danger tone so it is seen first. The icon and the words
/// say it as well as the colour (`FE-13`).
class SummaryTags extends StatelessWidget {
  const SummaryTags({required this.summary, super.key});

  final ShiftSummary summary;

  @override
  Widget build(BuildContext context) {
    final kinds = summary.kindsLogged;
    if (kinds.isEmpty) {
      return Text(
        NannyShiftCopy.summaryNothingLogged,
        style: NestTheme.of(context).text.bodySecondary,
      );
    }
    return Wrap(
      spacing: NestSpace.sm,
      runSpacing: NestSpace.sm,
      children: [
        for (final kind in kinds)
          NestTag(
            label: NannyShiftCopy.summaryCount(kind, summary.countOf(kind)),
            icon: kind.icon,
            tone: kind == HandoverKind.incident
                ? NestTagTone.danger
                : NestTagTone.accent,
          ),
        if (summary.photoCount > 0)
          NestTag(
            label: NannyShiftCopy.summaryPhotos(summary.photoCount),
            icon: Icons.photo_outlined,
          ),
      ],
    );
  }
}

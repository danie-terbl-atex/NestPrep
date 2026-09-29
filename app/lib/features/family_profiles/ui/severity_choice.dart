import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/allergy_severity.dart';
import 'severity_look.dart';

/// The three severities as rows that say what each means, in the tone each is
/// shown in everywhere else — so a parent choosing "severe" sees the warning
/// it will carry. Most serious first, the order a parent reads for.
class SeverityChoice extends StatelessWidget {
  const SeverityChoice({
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final AllergySeverity selected;
  final ValueChanged<AllergySeverity> onSelect;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final severity in AllergySeverity.values.reversed)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: Semantics(
              selected: severity == selected,
              inMutuallyExclusiveGroup: true,
              child: NestToneRow(
                icon: severity.icon,
                tone: severity == selected
                    ? severity.tone
                    : NestTagTone.neutral,
                title: FamilyCopy.severityName(severity),
                subtitle: FamilyCopy.severityHelp(severity),
                trailing: Icon(
                  severity == selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: nest.colors.ink,
                  size: NestSize.iconMedium,
                ),
                onTap: () => onSelect(severity),
              ),
            ),
          ),
      ],
    );
  }
}

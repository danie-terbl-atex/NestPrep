import 'package:flutter/material.dart';

import '../../design/nest_kit.dart';
import '../copy/app_copy.dart';

/// A row of weekday chips, one per ISO weekday in [weekdays], named by
/// `AppCopy.weekdayName`. It only shows and reports: what a tap means —
/// whether the last day may be switched off — is the caller's rule.
///
/// Shared by the recurrence editor and *Plan my week*'s treat days, which is
/// why it lives here (`ENG-02`).
class WeekdayChips extends StatelessWidget {
  const WeekdayChips({
    required this.weekdays,
    required this.selected,
    required this.onToggle,
    this.keyPrefix,
    super.key,
  });

  final List<int> weekdays;
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  /// When given, each chip is keyed `<keyPrefix>-<weekday>` for tests.
  final String? keyPrefix;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: NestSpace.xs,
      runSpacing: NestSpace.sm,
      children: [
        for (final weekday in weekdays)
          NestChip(
            key: switch (keyPrefix) {
              final prefix? => ValueKey('$prefix-$weekday'),
              null => null,
            },
            label: AppCopy.weekdayName(weekday),
            isSelected: selected.contains(weekday),
            onTap: () => onToggle(weekday),
          ),
      ],
    );
  }
}

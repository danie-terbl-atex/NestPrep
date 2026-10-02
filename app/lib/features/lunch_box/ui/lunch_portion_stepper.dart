import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/lunch_pantry_entry.dart';

/// One less, the count, one more — how many boxes' worth of something is in
/// the house (lunch-box ADR-0006). Each button says what it does to which
/// thing, for a screen reader; the count is read with the row.
class LunchPortionStepper extends StatelessWidget {
  const LunchPortionStepper({
    required this.name,
    required this.portions,
    required this.onChanged,
    super.key,
  });

  final String name;
  final int portions;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NestIconButton(
          icon: LucideIcons.minus,
          label: LunchPantryCopy.oneLess(name),
          variant: NestIconButtonVariant.plain,
          onPressed: portions > 0 ? () => onChanged(portions - 1) : null,
        ),
        ExcludeSemantics(
          child: SizedBox(
            width: NestSize.iconLarge,
            child: Text(
              '$portions',
              textAlign: TextAlign.center,
              style: nest.text.bodyStrong,
            ),
          ),
        ),
        NestIconButton(
          icon: LucideIcons.plus,
          label: LunchPantryCopy.oneMore(name),
          variant: NestIconButtonVariant.plain,
          onPressed: portions < LunchPantryEntry.portionLimit
              ? () => onChanged(portions + 1)
              : null,
        ),
      ],
    );
  }
}

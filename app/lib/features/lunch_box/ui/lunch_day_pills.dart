import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../model/lunch_day.dart';

/// The school week as five pills (design-system ADR-0008): the one on show
/// is Guava and bold, and a packed day carries a dot, so neither rests on
/// colour alone.
class LunchDayPills extends StatelessWidget {
  const LunchDayPills({
    required this.days,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final List<LunchDay> days;
  final LunchDay selected;
  final ValueChanged<LunchDay> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (index, day) in days.indexed) ...[
          if (index > 0) const SizedBox(width: NestSpace.xs),
          Expanded(
            child: _Pill(
              day: day,
              isSelected: day.date == selected.date,
              onTap: () => onSelect(day),
            ),
          ),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.day,
    required this.isSelected,
    required this.onTap,
  });

  final LunchDay day;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final name = NestDates.weekday(day.date);
    final isPacked = !day.box.isEmpty;
    final ink = isSelected ? c.onSecondary : c.ink;
    return Semantics(
      button: true,
      selected: isSelected,
      label: LunchCopy.dayPill(
        NestDates.weekdayName(day.date),
        isPacked: isPacked,
      ),
      excludeSemantics: true,
      onTap: onTap,
      child: NestPressable(
        child: AnimatedContainer(
          duration: NestMotion.of(context).quick,
          constraints: const BoxConstraints(minHeight: NestSize.controlSmall),
          decoration: BoxDecoration(
            color: isSelected ? c.secondary : c.surface,
            borderRadius: BorderRadius.circular(NestRadius.md),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(NestRadius.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: NestSpace.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        name,
                        maxLines: 1,
                        style: nest.text.label.copyWith(
                          color: ink,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: NestSpace.xxs),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: isPacked ? ink : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox.square(dimension: NestSpace.xs + 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

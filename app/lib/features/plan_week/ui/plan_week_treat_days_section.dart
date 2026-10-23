import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/weekday_chips.dart';
import '../model/treat_days.dart';
import '../model/treat_days_shortcut.dart';
import '../state/plan_week_controller.dart';

/// The brief's treat days (lunch-box ADR-0025): a shortcut — no treats,
/// Fridays only, every day — lit when the chosen days are exactly its days,
/// and Monday to Friday underneath to fine-tune, none allowed. Shown only
/// while the treat compartment is filled, as the week's treat line is: the
/// days mean nothing without it.
class PlanWeekTreatDaysSection extends StatelessWidget {
  const PlanWeekTreatDaysSection({super.key});

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final packing = context.watch<PlanWeekController>().packing;
    if (!packing.hasTreats) return const SizedBox.shrink();
    final treatDays = packing.treatDays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: NestSpace.xl),
        const NestSectionHeader(title: PlanWeekCopy.treatDaysHeader),
        const SizedBox(height: NestSpace.xs),
        Text(PlanWeekCopy.treatDaysBody, style: nest.text.bodySecondary),
        const SizedBox(height: NestSpace.sm),
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            for (final shortcut in TreatDaysShortcut.values)
              NestChip(
                key: ValueKey('plan-treat-shortcut-${shortcut.name}'),
                label: PlanWeekCopy.treatDaysShortcut(shortcut),
                isSelected: shortcut.isChosenFor(treatDays),
                icon: shortcut.isChosenFor(treatDays)
                    ? LucideIcons.check
                    : null,
                onTap: () => packing.chooseTreatDays(shortcut.days),
              ),
          ],
        ),
        const SizedBox(height: NestSpace.md),
        WeekdayChips(
          keyPrefix: 'plan-treat-day',
          weekdays: TreatDays.schoolDays,
          selected: treatDays,
          onToggle: packing.toggleTreatDay,
        ),
      ],
    );
  }
}

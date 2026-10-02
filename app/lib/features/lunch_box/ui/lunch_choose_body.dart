import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../model/lunch_choice_day.dart';
import '../state/lunch_choose_controller.dart';
import 'lunch_choose_slot.dart';

/// The chooser's days (lunch-box ADR-0008): one day at a time, a chip for
/// each, the stars for how far along it is, and every compartment's cards.
/// Which day is open is this screen's own business (`FE-07`); it opens on the
/// first one not finished.
class LunchChooseBody extends StatefulWidget {
  const LunchChooseBody({required this.days, this.onDone, super.key});

  final List<LunchChoiceDay> days;
  final VoidCallback? onDone;

  @override
  State<LunchChooseBody> createState() => _LunchChooseBodyState();
}

class _LunchChooseBodyState extends State<LunchChooseBody> {
  late int _open = _firstUnfinished();

  int _firstUnfinished() {
    final index = widget.days.indexWhere((day) => !day.isComplete);
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<LunchChooseController>();
    final days = widget.days;
    final openIndex = _open.clamp(0, days.length - 1);
    final day = days[openIndex];
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        if (days.length > 1) ...[
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              for (final (index, entry) in days.indexed)
                NestChip(
                  key: ValueKey(entry.date.iso),
                  label: NestDates.weekdayName(entry.date),
                  icon: entry.isComplete ? LucideIcons.star : null,
                  isSelected: index == openIndex,
                  onTap: () => setState(() => _open = index),
                ),
            ],
          ),
          const SizedBox(height: NestSpace.lg),
        ],
        NestRiseIn(
          child: Center(
            child: NestStarBurst(
              burst: controller.celebrations,
              child: Column(
                children: [
                  Text(
                    NestDates.weekdayName(day.date),
                    style: nest.text.caption,
                  ),
                  Text(
                    day.isComplete
                        ? LunchKidPicksCopy.dayDone
                        : LunchKidPicksCopy.progress(
                            day.chosenCount,
                            day.slots.length,
                          ),
                    textAlign: TextAlign.center,
                    style: nest.text.title,
                  ),
                  const SizedBox(height: NestSpace.xs),
                  ExcludeSemantics(
                    child: Wrap(
                      children: [
                        for (final slot in day.slots)
                          Icon(
                            slot.isChosen ? LucideIcons.star : LucideIcons.star,
                            color: slot.isChosen
                                ? nest.colors.warning
                                : nest.colors.outlineStrong,
                            size: NestSize.iconLarge,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        for (final (index, entry) in day.slots.indexed) ...[
          const SizedBox(height: NestSpace.xl),
          NestRiseIn(
            index: index + 1,
            child: LunchChooseSlot(
              key: ValueKey('${day.date.iso}-${entry.slot.name}'),
              entry: entry,
              onChoose: (pick) => controller.choose(
                isoWeekday: day.date.weekday,
                slot: entry.slot,
                pick: pick,
              ),
            ),
          ),
        ],
        if (widget.onDone case final onDone? when day.isComplete) ...[
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: LunchKidPicksCopy.handBack,
            icon: LucideIcons.check,
            onPressed: onDone,
          ),
        ],
      ],
    );
  }
}

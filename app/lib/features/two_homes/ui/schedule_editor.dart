import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../../../shared/ui/nest_date_field.dart';
import '../../../shared/ui/pick_minute_of_day.dart';
import '../model/co_parent_home.dart';
import '../model/custody_schedule.dart';
import '../model/custody_side.dart';
import '../state/schedule_draft.dart';
import 'fortnight_strip.dart';
import 'home_swatch.dart';

/// Choosing a parenting schedule (household ADR-0004): a preset or a
/// fortnight tapped day by day, the week it starts, who has the child first,
/// and when the handover happens — with the fortnight drawn underneath as it
/// is chosen, so the choice is seen, not imagined.
///
/// Reads the `ScheduleDraft` above it; making a code and suggesting a change
/// both use this one editor.
class ScheduleEditor extends StatelessWidget {
  const ScheduleEditor({required this.homeOf, required this.today, super.key});

  final CoParentHome Function(CustodySide side) homeOf;
  final CalendarDate today;

  /// The usual handover time offered first: after school.
  static const defaultHandoverMinute = 17 * 60;

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<ScheduleDraft>();
    final nest = NestTheme.of(context);
    final label = nest.text.label.copyWith(color: nest.colors.inkSecondary);
    final pattern = draft.pattern;
    final schedule = draft.schedule;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            for (final each in CustodyPattern.values)
              NestChip(
                label: TwoHomesCopy.patternName(each),
                isSelected: each == pattern,
                onTap: () => draft.choosePattern(each),
              ),
          ],
        ),
        const SizedBox(height: NestSpace.sm),
        Text(
          TwoHomesCopy.patternBody(pattern),
          style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
        ),
        const SizedBox(height: NestSpace.lg),
        NestDateField(
          label: TwoHomesCopy.startsOn,
          value: draft.startsOn,
          today: today,
          yearsAhead: 1,
          onChanged: draft.chooseStart,
        ),
        if (pattern != CustodyPattern.custom) ...[
          const SizedBox(height: NestSpace.lg),
          Text(
            pattern == CustodyPattern.everyOtherWeekend
                ? TwoHomesCopy.weekdaysWith
                : TwoHomesCopy.firstWith,
            style: label,
          ),
          const SizedBox(height: NestSpace.sm),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              for (final side in CustodySide.values)
                NestChip(
                  label: homeOf(side).name,
                  isSelected: draft.first == side,
                  onTap: () => draft.chooseFirst(side),
                ),
            ],
          ),
        ],
        if (pattern == CustodyPattern.alternatingWeeks) ...[
          const SizedBox(height: NestSpace.lg),
          Text(TwoHomesCopy.changesOn, style: label),
          const SizedBox(height: NestSpace.sm),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              for (var weekday = 1; weekday <= 7; weekday++)
                NestChip(
                  label: TwoHomesCopy.weekdayNames[weekday - 1],
                  isSelected: draft.switchWeekday == weekday,
                  onTap: () => draft.chooseSwitchWeekday(weekday),
                ),
            ],
          ),
        ],
        const SizedBox(height: NestSpace.lg),
        Text(TwoHomesCopy.handoverTime, style: label),
        const SizedBox(height: NestSpace.sm),
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            NestChip(
              label: TwoHomesCopy.anyTime,
              isSelected: draft.handoverMinute == null,
              onTap: () => draft.chooseHandoverMinute(null),
            ),
            NestChip(
              label: NestDates.timeOfDay(
                draft.handoverMinute ?? defaultHandoverMinute,
              ),
              icon: Icons.schedule,
              isSelected: draft.handoverMinute != null,
              onTap: () => _pickTime(context, draft),
            ),
          ],
        ),
        const SizedBox(height: NestSpace.xl),
        FortnightStrip(
          start: schedule.startsOn,
          sides: _fortnight(schedule),
          homeOf: homeOf,
          onTapDay: pattern == CustodyPattern.custom ? draft.flipDay : null,
        ),
        const SizedBox(height: NestSpace.sm),
        Wrap(
          spacing: NestSpace.lg,
          runSpacing: NestSpace.xs,
          children: [
            for (final side in CustodySide.values)
              HomeSwatch(home: homeOf(side)),
          ],
        ),
        if (pattern == CustodyPattern.custom) ...[
          const SizedBox(height: NestSpace.sm),
          Text(
            TwoHomesCopy.customHint,
            style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
          ),
        ],
      ],
    );
  }

  /// The first two weeks of the cycle, for the strip.
  static List<CustodySide?> _fortnight(CustodySchedule schedule) {
    final cycle = schedule.cycle;
    return [for (var day = 0; day < 14; day++) cycle[day % cycle.length]];
  }

  Future<void> _pickTime(BuildContext context, ScheduleDraft draft) async {
    final minute = await pickMinuteOfDay(
      context,
      initialMinutes: draft.handoverMinute ?? defaultHandoverMinute,
    );
    if (minute != null) draft.chooseHandoverMinute(minute);
  }
}

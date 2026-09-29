import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/household_clock.dart';
import '../../../shared/ui/pick_minute_of_day.dart';
import 'hub_clock.dart';

/// When it happened: now by default, a few quick steps back — a nap is often
/// logged when it ends — or a time from the platform's picker, today on the
/// household's clock. Never later than now: the rules refuse a future entry,
/// so the picker's choice is held to it here first (`FE-10`).
class WhenChoice extends StatelessWidget {
  const WhenChoice({
    required this.clock,
    required this.at,
    required this.onChanged,
    super.key,
  });

  final HouseholdClock clock;
  final DateTime at;
  final ValueChanged<DateTime> onChanged;

  static const _stepsBack = [15, 30, 60];

  Future<void> _pick(BuildContext context) async {
    final minute = await pickMinuteOfDay(
      context,
      initialMinutes: clock.minutesOfDay(at),
    );
    if (minute == null) return;
    final picked = clock.instantAt(
      clock.today,
      hour: minute ~/ Duration.minutesPerHour,
      minute: minute % Duration.minutesPerHour,
    );
    final now = clock.now;
    onChanged(picked.isAfter(now) ? now : picked);
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final now = clock.now;
    final minutesBack = now.difference(at).inMinutes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          NannyCopy.whenLabel,
          style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
        ),
        const SizedBox(height: NestSpace.sm),
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            NestChip(
              label: NannyCopy.now,
              isSelected: minutesBack < 1,
              onTap: () => onChanged(clock.now),
            ),
            for (final minutes in _stepsBack)
              NestChip(
                label: NestDates.ago(Duration(minutes: minutes)),
                isSelected: minutesBack == minutes,
                onTap: () =>
                    onChanged(clock.now.subtract(Duration(minutes: minutes))),
              ),
            NestChip(
              label: clock.timeOf(at),
              icon: Icons.schedule,
              semanticLabel: NannyCopy.pickTime,
              onTap: () => _pick(context),
            ),
          ],
        ),
      ],
    );
  }
}

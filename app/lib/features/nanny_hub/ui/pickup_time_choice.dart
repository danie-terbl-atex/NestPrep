import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/ui/pick_minute_of_day.dart';

/// When a child is collected: any time, or a wall-clock time from the
/// platform's picker, stored as minutes since midnight in the household's
/// zone (`ENG-21`).
class PickupTimeChoice extends StatelessWidget {
  const PickupTimeChoice({
    required this.atMinute,
    required this.onChanged,
    super.key,
  });

  final int? atMinute;
  final ValueChanged<int?> onChanged;

  /// Half past two — when most South African primary schools let out.
  static const _suggested = 14 * 60 + 30;

  Future<void> _pick(BuildContext context) async {
    final minute = await pickMinuteOfDay(
      context,
      initialMinutes: atMinute ?? _suggested,
    );
    if (minute != null) onChanged(minute);
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final minute = atMinute;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          NannyPickupCopy.time,
          style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
        ),
        const SizedBox(height: NestSpace.sm),
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            NestChip(
              label: NannyPickupCopy.noTime,
              isSelected: minute == null,
              onTap: () => onChanged(null),
            ),
            NestChip(
              label: minute == null
                  ? NannyPickupCopy.pickTime
                  : NestDates.timeOfDay(minute),
              icon: Icons.schedule,
              isSelected: minute != null,
              semanticLabel: NannyPickupCopy.pickTime,
              onTap: () => _pick(context),
            ),
          ],
        ),
      ],
    );
  }
}

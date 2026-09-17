import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';

/// Picks a day. It hands the platform picker a UTC midnight and reads a
/// `CalendarDate` back, so no instant and no zone ever escapes into a due date
/// (`ENG-21`, foundation ADR-0007).
class NestDateField extends StatelessWidget {
  const NestDateField({
    required this.label,
    required this.value,
    required this.today,
    required this.onChanged,
    super.key,
  });

  final String label;
  final CalendarDate value;
  final CalendarDate today;
  final ValueChanged<CalendarDate> onChanged;

  /// How far either side of today a date may be chosen. A family calendar that
  /// reaches five years out is a calendar nobody is using.
  static const yearsEitherSide = 5;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
        ),
        const SizedBox(height: NestSpace.sm),
        NestListRow(
          title: NestDates.relative(value, today),
          subtitle: NestDates.full(value, today),
          leading: const NestIconTile(
            icon: Icons.event_outlined,
            tint: NestTileTint.sky,
            size: NestSize.avatarMedium,
          ),
          onTap: () => _pick(context),
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.utc(value.year, value.month, value.day),
      firstDate: DateTime.utc(today.year - yearsEitherSide),
      lastDate: DateTime.utc(today.year + yearsEitherSide, 12, 31),
    );
    if (picked == null) return;
    onChanged(CalendarDate(picked.year, picked.month, picked.day));
  }
}

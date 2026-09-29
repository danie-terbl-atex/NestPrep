import 'package:flutter/material.dart';

import '../../design/nest_kit.dart';
import '../format/nest_dates.dart';
import '../time/calendar_date.dart';

/// Picks a day. It hands the platform picker a UTC midnight and reads a
/// `CalendarDate` back, so no instant and no zone ever escapes into a due date
/// (`ENG-21`, foundation ADR-0007).
class NestDateField extends StatelessWidget {
  const NestDateField({
    required this.label,
    required this.value,
    required this.today,
    required this.onChanged,
    this.yearsAhead = yearsEitherSide,
    super.key,
  });

  final String label;
  final CalendarDate value;
  final CalendarDate today;
  final ValueChanged<CalendarDate> onChanged;

  /// How far forward the picker reaches. A passport is valid for ten years,
  /// which is further than a calendar event ever needs.
  final int yearsAhead;

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
    final picked = await pickDate(
      context,
      initial: value,
      today: today,
      yearsAhead: yearsAhead,
    );
    if (picked != null) onChanged(picked);
  }

  /// The platform's date picker, over the same range as the field. Shared with
  /// fields that start with no date at all, like a document's expiry.
  static Future<CalendarDate?> pickDate(
    BuildContext context, {
    required CalendarDate initial,
    required CalendarDate today,
    int yearsAhead = yearsEitherSide,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.utc(initial.year, initial.month, initial.day),
      firstDate: DateTime.utc(today.year - yearsEitherSide),
      lastDate: DateTime.utc(today.year + yearsAhead, 12, 31),
    );
    if (picked == null) return null;
    return CalendarDate(picked.year, picked.month, picked.day);
  }
}

import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/birthday.dart';

/// Collects a member's birthday: none, a full date, or a day and a month with
/// no year for a household that does not know one (birthdays ADR-0001).
///
/// It is not `NestDateField`, which is the picker for a required day within a
/// few years of today. Each of that widget's three parameters means something
/// else here — the value is optional, the range is a lifetime back rather than
/// five years either side, and its title is `NestDates.relative`, which would
/// read "Today" on somebody's birthday.
class MemberBirthdayField extends StatelessWidget {
  const MemberBirthdayField({
    required this.value,
    required this.today,
    required this.onChanged,
    super.key,
  });

  final Birthday? value;

  /// Today where the household lives, which bounds the picker: nobody is born
  /// tomorrow.
  final CalendarDate today;

  final ValueChanged<Birthday?> onChanged;

  /// Long enough that no living member is outside it.
  static const yearsBack = 120;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final current = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppCopy.householdMemberBirthday,
          style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
        ),
        const SizedBox(height: NestSpace.sm),
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            NestChip(
              label: AppCopy.householdBirthdayNone,
              isSelected: current == null,
              onTap: () => onChanged(null),
            ),
            NestChip(
              label: AppCopy.householdBirthdayKnown,
              isSelected: current != null && current.hasYear,
              onTap: () => onChanged(_withYear(current)),
            ),
            NestChip(
              label: AppCopy.householdBirthdayNoYear,
              isSelected: current != null && !current.hasYear,
              onTap: () => onChanged(_withoutYear(current)),
            ),
          ],
        ),
        if (current != null) ...[
          const SizedBox(height: NestSpace.sm),
          NestListRow(
            title: NestDates.dayOfYear(
              month: current.month,
              day: current.day,
              year: current.year,
            ),
            subtitle: current.hasYear
                ? AppCopy.householdBirthdayPick
                : AppCopy.householdBirthdayYearUnknown,
            leading: const NestIconTile(
              icon: Icons.cake_outlined,
              tint: NestTileTint.guava,
              size: NestSize.avatarMedium,
            ),
            onTap: () => _pick(context, current),
          ),
        ],
      ],
    );
  }

  /// The most recent occurrence that is not in the future: where the picker
  /// opens, and the year a birthday gets when one is asked for. A day later in
  /// the year than today belongs to last year, not next — and nobody is born
  /// tomorrow, which is also what bounds the picker.
  CalendarDate _mostRecent(Birthday birthday, int fromYear) {
    final inThatYear = birthday.occurrenceIn(fromYear);
    return inThatYear.isAfter(today)
        ? birthday.occurrenceIn(fromYear - 1)
        : inThatYear;
  }

  /// Seeds from today when there is nothing yet: the picker opens there and
  /// whoever is typing moves it, rather than being shown an empty field with no
  /// clue what it wants. Giving a year to a 29 February birthday goes through
  /// `occurrenceIn`, so a year with no 29th cannot be constructed.
  Birthday _withYear(Birthday? current) => current == null
      ? Birthday.on(today)
      : Birthday.on(_mostRecent(current, today.year));

  Birthday _withoutYear(Birthday? current) => current == null
      ? Birthday(month: today.month, day: today.day)
      : Birthday(month: current.month, day: current.day);

  Future<void> _pick(BuildContext context, Birthday current) async {
    final born = current.year;
    final openOn = born == null
        ? _mostRecent(current, today.year)
        : current.occurrenceIn(born);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.utc(openOn.year, openOn.month, openOn.day),
      firstDate: DateTime.utc(today.year - yearsBack),
      lastDate: DateTime.utc(today.year, today.month, today.day),
    );
    if (picked == null) return;
    onChanged(
      Birthday(
        month: picked.month,
        day: picked.day,
        year: born == null ? null : picked.year,
      ),
    );
  }
}

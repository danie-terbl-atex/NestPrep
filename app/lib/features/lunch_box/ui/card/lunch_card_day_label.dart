import 'package:flutter/material.dart';

import '../../../../design/nest_kit.dart';
import '../../../../shared/format/nest_dates.dart';
import '../../../../shared/time/calendar_date.dart';

/// A day's name at the head of its row on a card — "Mon" — with the date
/// under it when the row is tall enough for both. Both yield to a row that
/// is short by a rounding, rather than overflowing it.
class LunchCardDayLabel extends StatelessWidget {
  const LunchCardDayLabel({required this.date, super.key});

  final CalendarDate date;

  /// Wide enough for the widest short name, "Wed", in the title face.
  static const width = NestSize.controlSmall;

  @override
  Widget build(BuildContext context) {
    final text = NestTheme.of(context).text;
    return SizedBox(
      width: width,
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                NestDates.weekday(date),
                maxLines: 1,
                style: text.title,
              ),
            ),
            if (constraints.maxHeight >=
                lineHeightOf(text.title) + lineHeightOf(text.caption))
              Flexible(
                child: Text(
                  NestDates.dayOfMonth(date),
                  maxLines: 1,
                  style: text.caption,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The height one line of [style] takes.
double lineHeightOf(TextStyle style) =>
    (style.fontSize ?? 0) * (style.height ?? 1);

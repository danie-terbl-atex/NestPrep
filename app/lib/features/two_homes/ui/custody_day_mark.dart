import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/time/calendar_date.dart';
import '../state/custody_calendar.dart';

/// The small bar under a day in the week strip: one segment per linked child,
/// in the colour of the home they are with. The bands on the day say the same
/// in words, so the colour is never the only signal (`FE-13`).
class CustodyDayMark extends StatelessWidget {
  const CustodyDayMark({required this.day, super.key});

  final CalendarDate day;

  @override
  Widget build(BuildContext context) {
    final colours = context.watch<CustodyCalendar?>()?.coloursOn(day);
    if (colours == null || colours.isEmpty) return const SizedBox.shrink();
    final nest = NestTheme.of(context);
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(top: NestSpace.xxs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final colour in colours)
              Container(
                width: NestSpace.lg,
                height: NestSpace.xs,
                margin: const EdgeInsets.symmetric(horizontal: NestSpace.xxs),
                decoration: BoxDecoration(
                  color: nest.members.of(colour).fill,
                  borderRadius: BorderRadius.circular(NestRadius.pill),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

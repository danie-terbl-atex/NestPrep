import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/two_homes_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../../household/model/household_view.dart';
import '../model/custody_band.dart';
import '../state/custody_calendar.dart';

/// The all-day bands on a day of the household's week (household ADR-0004):
/// *Sam · with Mum's home* in that home's colour, or *Sam goes to Dad's home*
/// on the day they change. Derived, never stored; tapping one opens the link.
///
/// Draws nothing where there is no `CustodyCalendar` — two homes switched off,
/// or a screen pumped alone — so the week never depends on it.
class CustodyDayBands extends StatelessWidget {
  const CustodyDayBands({required this.day, super.key});

  final CalendarDate day;

  /// Whether there is anything to draw on [day] — a band, or the line that
  /// says the bands could not be read — so the week can leave its empty day
  /// exactly as it was when there is not.
  static bool showsOn(BuildContext context, CalendarDate day) {
    final calendar = context.watch<CustodyCalendar?>();
    return calendar != null &&
        (calendar.failure != null || calendar.on(day).isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final calendar = context.watch<CustodyCalendar?>();
    if (calendar == null) return const SizedBox.shrink();
    final failure = calendar.failure;
    if (failure != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: NestSpace.sm),
        child: NestBanner(
          message: AppCopy.failure(failure),
          actionLabel: AppCopy.retry,
          onAction: calendar.retry,
        ),
      );
    }
    final bands = calendar.on(day);
    if (bands.isEmpty) return const SizedBox.shrink();
    final view = context.watch<HouseholdView>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final band in bands)
          Padding(
            key: ValueKey(band.key),
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: _Band(
              band: band,
              childName:
                  view.memberById(band.link.childMemberId)?.displayName ??
                  band.link.childName,
              onTap: () => context.push(
                TwoHomesRoute.linkPathFor(calendar.householdId, band.link.id),
              ),
            ),
          ),
      ],
    );
  }
}

class _Band extends StatelessWidget {
  const _Band({
    required this.band,
    required this.childName,
    required this.onTap,
  });

  final CustodyBand band;
  final String childName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final swatch = nest.members.of(band.home.color);
    final minute = band.link.schedule.handoverMinute;
    final title = band.day.isHandover
        ? TwoHomesCopy.bandHandover(childName, band.home.name)
        : TwoHomesCopy.bandWith(childName, band.home.name);
    final detail = [
      AppCopy.calendarAllDay,
      if (band.day.isHandover && minute != null)
        TwoHomesCopy.handoverAt(NestDates.timeOfDay(minute)),
      TwoHomesCopy.bandFromTwoHomes,
    ].join(' · ');
    return Semantics(
      button: true,
      label: '$title. $detail',
      excludeSemantics: true,
      child: Material(
        color: swatch.fill,
        borderRadius: BorderRadius.circular(NestRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(NestRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: NestSpace.lg,
              vertical: NestSpace.md,
            ),
            child: Row(
              children: [
                Icon(
                  band.day.isHandover
                      ? LucideIcons.arrowLeftRight
                      : LucideIcons.house,
                  color: swatch.onFill,
                  size: NestSize.iconMedium,
                ),
                const SizedBox(width: NestSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: nest.text.bodyStrong.copyWith(
                          color: swatch.onFill,
                        ),
                      ),
                      Text(
                        detail,
                        style: nest.text.caption.copyWith(color: swatch.onFill),
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, color: swatch.onFill),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

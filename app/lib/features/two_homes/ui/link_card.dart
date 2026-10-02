import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/co_parent_link.dart';
import 'fortnight_strip.dart';
import 'home_swatch.dart';

/// An active link at a glance (household ADR-0004): where the child is today,
/// the next time they change homes, and the coming week in the homes'
/// colours. Tapping it opens the link.
class LinkCard extends StatelessWidget {
  const LinkCard({
    required this.link,
    required this.childName,
    required this.today,
    required this.onTap,
    super.key,
  });

  final CoParentLink link;

  /// This household's own name for the child.
  final String childName;
  final CalendarDate today;
  final VoidCallback onTap;

  static const daysShown = 7;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final week = link.daysBetween(today, today.addDays(daysShown - 1));
    final todayDay = week.where((day) => day.date == today).firstOrNull;
    final next = link.upcoming(today.addDays(1), count: 1).firstOrNull;
    final todayLine = todayDay == null
        ? null
        : todayDay.isHandover
        ? TwoHomesCopy.goesToday(childName, link.homeOf(todayDay.side).name)
        : TwoHomesCopy.withToday(childName, link.homeOf(todayDay.side).name);
    final nextLine = next == null
        ? TwoHomesCopy.noHandoverSoon
        : TwoHomesCopy.nextHandover(
            NestDates.relative(next.date, today),
            link.homeOf(next.side).name,
          );

    return NestCard(
      onTap: onTap,
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NestAvatar(name: childName, color: link.ownHome.color),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      childName,
                      style: nest.text.title.copyWith(color: nest.colors.ink),
                    ),
                    if (todayLine != null)
                      Text(
                        todayLine,
                        style: nest.text.body.copyWith(
                          color: nest.colors.inkSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, color: nest.colors.inkTertiary),
            ],
          ),
          const SizedBox(height: NestSpace.md),
          FortnightStrip(
            start: today,
            sides: [
              for (var offset = 0; offset < daysShown; offset++)
                week
                    .where((day) => day.date == today.addDays(offset))
                    .firstOrNull
                    ?.side,
            ],
            homeOf: link.homeOf,
          ),
          const SizedBox(height: NestSpace.md),
          Text(
            nextLine,
            style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
          ),
          const SizedBox(height: NestSpace.sm),
          Wrap(
            spacing: NestSpace.lg,
            runSpacing: NestSpace.xs,
            children: [
              HomeSwatch(
                home: link.ownHome,
                caption: TwoHomesCopy.legendThisHome.toLowerCase(),
              ),
              HomeSwatch(home: link.otherHome),
            ],
          ),
        ],
      ),
    );
  }
}

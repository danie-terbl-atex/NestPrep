import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/calendar_sync_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/calendar_sync_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../calendar_sync/model/synced_event.dart';
import '../../calendar_sync/ui/calendar_source_badge.dart';
import '../../household/model/household_view.dart';
import 'member_stripe.dart';

/// An event from somebody's own calendar, on the family week (calendar
/// ADR-0003). It looks like an event row — the owner's colour down the edge,
/// the time and whose it is — with a badge that says where it came from,
/// because it behaves like nothing else here: it cannot be edited, skipped or
/// deleted. Tapping it says so, and where to go instead.
class SyncedEventRow extends StatelessWidget {
  const SyncedEventRow({required this.event, super.key});

  final SyncedEvent event;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final view = context.read<HouseholdView>();
    final owner = view.memberById(event.memberId);
    final title = event.title.isEmpty
        ? CalendarSyncCopy.syncedBusy
        : event.title;
    final when = event.isAllDay
        ? AppCopy.calendarAllDay
        : _timeRange(event.startMinute!, event.endMinute);
    final source = CalendarSyncCopy.connectionTitle(
      owner?.displayName ?? CalendarSyncCopy.formerMember,
      event.provider,
      label: event.sourceLabel,
    );

    return NestCard(
      variant: NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: Semantics(
        button: true,
        label: '$title. $when. ${CalendarSyncCopy.syncedFrom(source)}',
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(NestRadius.lg),
          onTap: () => _explain(context, title: title, source: source),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MemberStripe(colors: [?owner?.color]),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(NestSpace.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: nest.text.bodyStrong.copyWith(
                            color: nest.colors.ink,
                          ),
                        ),
                        const SizedBox(height: NestSpace.xxs),
                        Text(
                          '$when · ${owner?.displayName ?? CalendarSyncCopy.formerMember}',
                          style: nest.text.caption.copyWith(
                            color: nest.colors.inkTertiary,
                          ),
                        ),
                        const SizedBox(height: NestSpace.xs),
                        CalendarSourceBadge(
                          provider: event.provider,
                          label: event.sourceLabel,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _timeRange(int startMinute, int? endMinute) {
    final start = NestDates.timeOfDay(startMinute);
    if (endMinute == null) return start;
    return '$start – ${NestDates.timeOfDay(endMinute)}';
  }

  Future<void> _explain(
    BuildContext context, {
    required String title,
    required String source,
  }) async {
    final householdId = context.read<HouseholdView>().household.id;
    final openConnected = await showNestSheet<bool>(
      context: context,
      title: title,
      builder: (sheetContext) {
        final nest = NestTheme.of(sheetContext);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              CalendarSyncCopy.syncedFrom(source),
              style: nest.text.bodyStrong.copyWith(color: nest.colors.ink),
            ),
            const SizedBox(height: NestSpace.sm),
            Text(
              CalendarSyncCopy.syncedReadOnlyBody,
              style: nest.text.body.copyWith(color: nest.colors.inkSecondary),
            ),
            const SizedBox(height: NestSpace.xl),
            NestButton(
              label: CalendarSyncCopy.openFromWeek,
              icon: LucideIcons.arrowRightLeft,
              variant: NestButtonVariant.tonal,
              onPressed: () => Navigator.of(sheetContext).pop(true),
            ),
          ],
        );
      },
    );
    if (openConnected != true || !context.mounted) return;
    await context.push(CalendarSyncRoute.pathFor(householdId));
  }
}

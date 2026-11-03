import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../../../shared/time/household_clock.dart';
import '../../household/model/member.dart';
import '../data/street_names.dart';
import '../model/coordinates.dart';
import '../model/family_place.dart';
import '../model/timeline.dart';
import '../model/trail.dart';
import '../state/history_controller.dart';
import 'family_map.dart';
import 'maps_enabled.dart';

/// One member's day, as stops and journeys (live-location ADR-0004).
class MemberHistoryScreen extends StatelessWidget {
  const MemberHistoryScreen({
    required this.member,
    this.isOwn = false,
    this.showMap = mapsEnabled,
    super.key,
  });

  static const routeName = 'location-history';

  final Member member;

  /// The person looking is the person whose day this is.
  final bool isOwn;
  final bool showMap;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HistoryController>();
    final clock = context.read<HouseholdClock>();
    return NestScaffold(
      title: LocationCopy.historyOf(member.displayName),
      leading: context.canPop()
          ? NestIconButton(
              icon: LucideIcons.arrowLeft,
              label: AppCopy.back,
              variant: NestIconButtonVariant.plain,
              onPressed: context.pop,
            )
          : null,
      trailing: [
        if (isOwn)
          NestIconButton(
            icon: LucideIcons.trash2,
            label: LocationCopy.clearHistory,
            variant: NestIconButtonVariant.plain,
            onPressed: () => _confirmClear(context, controller),
          ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DayPicker(controller: controller, today: clock.today),
          const SizedBox(height: NestSpace.md),
          Expanded(
            child: NestAsyncView<MemberDay>(
              state: controller.view,
              isEmpty: (day) => day.isEmpty,
              onRetry: controller.retry,
              emptyBuilder: (_) => const NestEmptyView(
                title: LocationCopy.emptyDayTitle,
                message: LocationCopy.emptyDayBody,
                icon: LucideIcons.route,
              ),
              dataBuilder: (context, day) => ListView(
                padding: const EdgeInsets.only(bottom: NestSpace.huge),
                children: [
                  if (showMap)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(NestRadius.lg),
                      child: SizedBox(
                        height: 240,
                        child: FamilyMap(
                          members: const [],
                          places: day.places,
                          path: [
                            for (final point in day.trail.points) point.point,
                          ],
                        ),
                      ),
                    ),
                  if (showMap) const SizedBox(height: NestSpace.lg),
                  for (final entry in _entries(day))
                    Padding(
                      padding: const EdgeInsets.only(bottom: NestSpace.sm),
                      child: _EntryRow(
                        entry: entry,
                        clock: clock,
                        places: day.places,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    HistoryController controller,
  ) async {
    final sure = await showNestConfirm(
      context: context,
      title: LocationCopy.clearHistory,
      message: LocationCopy.clearHistoryConfirm,
      confirmLabel: LocationCopy.clear,
      cancelLabel: LocationCopy.cancel,
    );
    if (sure == true) await controller.clearHistory();
  }

  static List<Object> _entries(MemberDay day) {
    final entries = <Object>[...day.timeline, ...day.trail.events]
      ..sort((a, b) => _startOf(a).compareTo(_startOf(b)));
    return entries.reversed.toList();
  }

  static DateTime _startOf(Object entry) => switch (entry) {
    TimelineEntry(:final from) => from,
    PlaceEvent(:final at) => at,
    _ => DateTime.fromMillisecondsSinceEpoch(0),
  };
}

class _DayPicker extends StatelessWidget {
  const _DayPicker({required this.controller, required this.today});

  final HistoryController controller;
  final CalendarDate today;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final day = controller.day;
    final label = day == today
        ? LocationCopy.today
        : day == today.addDays(-1)
        ? LocationCopy.yesterday
        : NestDates.relative(day, today);
    return Row(
      children: [
        NestIconButton(
          icon: LucideIcons.chevronLeft,
          label: LocationCopy.previousDay,
          onPressed: controller.canGoBack ? controller.previousDay : null,
        ),
        Expanded(
          child: Text(
            label,
            style: nest.text.title,
            textAlign: TextAlign.center,
          ),
        ),
        NestIconButton(
          icon: LucideIcons.chevronRight,
          label: LocationCopy.nextDay,
          onPressed: controller.canGoForward ? controller.nextDay : null,
        ),
      ],
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.entry,
    required this.clock,
    required this.places,
  });

  final Object entry;
  final HouseholdClock clock;
  final List<FamilyPlace> places;

  @override
  Widget build(BuildContext context) {
    return switch (entry) {
      TimelineStop(:final from, :final to, :final place, :final centre) =>
        NestListRow(
          leading: const NestIconTile(icon: LucideIcons.mapPin),
          title: place?.name ?? _coordinates(centre),
          footer: place == null ? _StreetName(at: centre) : null,
          subtitle:
              '${_span(from, to)} · '
              '${LocationCopy.stayed(LocationCopy.duration(to.difference(from)))}',
        ),
      TimelineJourney(:final from, :final to, :final metres) => NestListRow(
        leading: const NestIconTile(
          icon: LucideIcons.route,
          tint: NestTileTint.basil,
        ),
        title: LocationCopy.distance(metres),
        subtitle: _span(from, to),
      ),
      PlaceEvent(:final kind, :final at, :final placeId) => NestListRow(
        leading: NestIconTile(
          icon: kind == PlaceEventKind.arrive
              ? LucideIcons.logIn
              : LucideIcons.logOut,
          tint: NestTileTint.lilac,
        ),
        title: _eventTitle(placeId, kind),
        subtitle: NestDates.timeOfDay(clock.minutesOfDay(at)),
      ),
      _ => const SizedBox.shrink(),
    };
  }

  String _eventTitle(String placeId, PlaceEventKind kind) {
    final name =
        places.where((place) => place.id == placeId).firstOrNull?.name ??
        LocationCopy.somewhere;
    return kind == PlaceEventKind.arrive
        ? LocationCopy.arrived(name)
        : LocationCopy.left(name);
  }

  String _span(DateTime from, DateTime to) =>
      '${NestDates.timeOfDay(clock.minutesOfDay(from))} – '
      '${NestDates.timeOfDay(clock.minutesOfDay(to))}';

  static String _coordinates(Coordinates at) =>
      '${at.latitude.toStringAsFixed(4)}, ${at.longitude.toStringAsFixed(4)}';
}

class _StreetName extends StatelessWidget {
  const _StreetName({required this.at});

  final Coordinates at;

  @override
  Widget build(BuildContext context) {
    final names = context.read<StreetNames?>();
    if (names == null) return const SizedBox.shrink();
    return FutureBuilder<String?>(
      future: names.near(at),
      builder: (context, street) => street.data == null
          ? const SizedBox.shrink()
          : Text(
              '${LocationCopy.near} ${street.data}',
              style: NestTheme.of(context).text.caption,
            ),
    );
  }
}

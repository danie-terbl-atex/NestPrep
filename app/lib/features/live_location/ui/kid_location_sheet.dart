import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/log/app_log.dart';
import '../../../shared/time/household_clock.dart';
import '../../accounts/model/kid_identity.dart';
import '../../household/data/household_repository.dart';
import '../../household/model/household.dart';
import '../../subscriptions/data/entitlement_repository.dart';
import '../../subscriptions/model/entitlement.dart';
import '../data/live_location_repository.dart';
import '../data/location_reporter.dart';
import '../data/places_repository.dart';
import '../model/family_place.dart';
import '../model/member_location.dart';
import '../model/share_duration.dart';
import '../state/always_sharing.dart';
import 'always_sharing_flow.dart';

Future<void> showKidLocationSheet(BuildContext context, KidIdentity kid) =>
    showNestSheet<void>(
      context: context,
      title: LocationCopy.yours,
      builder: (_) => KidLocationSheet(kid: kid),
    );

/// A kid phone shares as its own profile (live-location ADR-0008): the child's
/// phone holds the switch, and nobody else can start it.
class KidLocationSheet extends StatefulWidget {
  const KidLocationSheet({required this.kid, super.key});

  final KidIdentity kid;

  @override
  State<KidLocationSheet> createState() => _KidLocationSheetState();
}

class _KidLocationSheetState extends State<KidLocationSheet> {
  final _subscriptions = <StreamSubscription<Object?>>[];
  Household? _home;
  MemberLocation? _own;
  List<FamilyPlace> _places = const [];
  bool _premium = false;
  bool _loaded = false;
  bool _working = false;
  AppFailure? _failure;

  @override
  void initState() {
    super.initState();
    final kid = widget.kid;
    _listen(
      context.read<HouseholdRepository>().watchHousehold(kid.householdId),
      (home) => _home = home,
      'kid location household',
    );
    _listen(
      context.read<EntitlementRepository>().watchEntitlement(kid.householdId),
      (Entitlement entitlement) =>
          _premium = entitlement.isPremiumAt(DateTime.now()),
      'kid location entitlement',
    );
    _listen(
      context.read<LiveLocationRepository>().watchLocations(kid.householdId),
      (List<MemberLocation> locations) {
        _own = locations
            .where((location) => location.id == kid.memberId)
            .firstOrNull;
        _loaded = true;
      },
      'kid location own position',
      onFailure: (failure) => _failure = failure,
    );
    _listen(
      context.read<PlacesRepository>().watchPlaces(kid.householdId),
      (List<FamilyPlace> places) => _places = places,
      'kid location places',
    );
  }

  void _listen<T>(
    Stream<T> stream,
    void Function(T value) onValue,
    String operation, {
    void Function(AppFailure failure)? onFailure,
  }) {
    _subscriptions.add(
      stream.listen(
        (value) => setState(() => onValue(value)),
        onError: (Object error) {
          AppLog.failure(operation, code: 'kid-location-read', error: error);
          if (onFailure != null) {
            setState(() {
              _loaded = true;
              onFailure(error is AppFailure ? error : UnknownFailure(error));
            });
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _failure = null;
      _working = true;
    });
    try {
      await action();
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final always = context.watch<AlwaysSharing>();
    final kid = widget.kid;
    final home = _home;
    final sharingAlways = always.isSharingFor(kid.householdId, kid.memberId);
    final own = _own;
    final windowUntil =
        own != null &&
            own.mode == ShareMode.window &&
            own.isSharingAt(DateTime.now())
        ? own.sharingUntil
        : null;
    final failure = _failure;
    if (!_loaded) {
      return const Padding(
        padding: EdgeInsets.all(NestSpace.gutter),
        child: NestLoadingView(),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(NestSpace.gutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null) ...[
            NestBanner(
              message: AppCopy.failure(failure),
              tone: NestBannerTone.danger,
              actionLabel: AppCopy.back,
              onAction: () => setState(() => _failure = null),
            ),
            const SizedBox(height: NestSpace.md),
          ],
          Text(
            sharingAlways
                ? LocationCopy.alwaysOnBody
                : windowUntil != null && home != null
                ? '${LocationCopy.sharingUntil} '
                      '${NestDates.timeOfDay(HouseholdClock(home.timeZone).minutesOfDay(windowUntil))}'
                : LocationCopy.yoursBody,
            style: nest.text.bodySecondary,
          ),
          const SizedBox(height: NestSpace.lg),
          if (sharingAlways)
            NestButton(
              label: LocationCopy.pause,
              variant: NestButtonVariant.outline,
              icon: LucideIcons.pause,
              isLoading: always.busy,
              onPressed: () => _run(
                () => always.stop(
                  householdId: kid.householdId,
                  memberId: kid.memberId,
                ),
              ),
            )
          else if (windowUntil != null)
            NestButton(
              label: LocationCopy.stop,
              variant: NestButtonVariant.outline,
              icon: LucideIcons.mapPinOff,
              isLoading: _working,
              onPressed: () => _run(
                () => context.read<LocationReporter>().stop(
                  householdId: kid.householdId,
                  memberId: kid.memberId,
                ),
              ),
            )
          else ...[
            Wrap(
              spacing: NestSpace.sm,
              runSpacing: NestSpace.sm,
              children: [
                for (final duration in ShareDuration.values)
                  NestChip(
                    label: switch (duration) {
                      ShareDuration.fifteenMinutes =>
                        LocationCopy.fifteenMinutes,
                      ShareDuration.oneHour => LocationCopy.oneHour,
                      ShareDuration.fourHours => LocationCopy.fourHours,
                    },
                    icon: LucideIcons.clock,
                    onTap: _working
                        ? null
                        : () => _run(
                            () => context.read<LocationReporter>().start(
                              householdId: kid.householdId,
                              memberId: kid.memberId,
                              until: duration.endingFrom(DateTime.now()),
                            ),
                          ),
                  ),
              ],
            ),
            if (_premium && home != null) ...[
              const SizedBox(height: NestSpace.lg),
              NestButton(
                label: LocationCopy.always,
                variant: NestButtonVariant.tonal,
                icon: LucideIcons.radio,
                isLoading: always.busy,
                onPressed: () => _run(
                  () => startAlwaysSharingFor(
                    context,
                    householdId: kid.householdId,
                    householdName: home.name,
                    timeZone: home.timeZone,
                    memberId: kid.memberId,
                    places: _places,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

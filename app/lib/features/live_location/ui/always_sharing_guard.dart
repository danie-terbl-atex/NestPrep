import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../shared/log/app_log.dart';
import '../../household/model/household_view.dart';
import '../../subscriptions/state/household_entitlement.dart';
import '../data/places_repository.dart';
import '../model/family_place.dart';
import '../state/always_sharing.dart';

/// While a household is open: stop always-sharing once premium is known to
/// have ended, and keep the phone's geofences in step with the household's
/// places (live-location ADR-0005). The engine also re-reads places itself, so
/// a kid phone or a closed app is covered without this.
class AlwaysSharingGuard extends StatefulWidget {
  const AlwaysSharingGuard({required this.child, super.key});

  final Widget child;

  @override
  State<AlwaysSharingGuard> createState() => _AlwaysSharingGuardState();
}

class _AlwaysSharingGuardState extends State<AlwaysSharingGuard> {
  StreamSubscription<List<FamilyPlace>>? _places;
  String? _watching;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final always = context.watch<AlwaysSharing?>();
    final view = context.read<HouseholdView>();
    final memberId = view.viewerMember?.id;
    if (always == null || memberId == null) return;
    final householdId = view.household.id;
    final sharing = always.isSharingFor(householdId, memberId);
    final entitlement = context.watch<HouseholdEntitlement?>();
    if (sharing &&
        entitlement != null &&
        entitlement.isKnown &&
        !entitlement.isPremium) {
      // Off the build: stopping notifies the listeners this build is one of.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(
          always.stopForLapse(householdId: householdId, memberId: memberId),
        ),
      );
    }
    _watchPlaces(sharing ? householdId : null, always);
  }

  void _watchPlaces(String? householdId, AlwaysSharing always) {
    if (_watching == householdId) return;
    _watching = householdId;
    unawaited(_places?.cancel());
    _places = householdId == null
        ? null
        : context
              .read<PlacesRepository>()
              .watchPlaces(householdId)
              .listen(
                always.placesChanged,
                onError: (Object error) => AppLog.failure(
                  'always sharing places',
                  code: 'engine-places-stream-failed',
                  error: error,
                ),
              );
  }

  @override
  void dispose() {
    unawaited(_places?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

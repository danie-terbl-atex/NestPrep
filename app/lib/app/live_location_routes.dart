import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../design/nest_kit.dart';
import '../features/household/model/household_view.dart';
import '../features/live_location/data/live_location_repository.dart';
import '../features/live_location/data/location_reporter.dart';
import '../features/live_location/data/location_source.dart';
import '../features/live_location/data/places_repository.dart';
import '../features/live_location/data/trail_repository.dart';
import '../features/live_location/model/family_place.dart';
import '../features/live_location/state/history_controller.dart';
import '../features/live_location/state/live_location_controller.dart';
import '../features/live_location/state/place_editor_controller.dart';
import '../features/live_location/state/places_controller.dart';
import '../features/live_location/ui/live_location_screen.dart';
import '../features/live_location/ui/member_history_screen.dart';
import '../features/live_location/ui/place_editor_screen.dart';
import '../features/live_location/ui/places_screen.dart';
import '../shared/copy/app_copy.dart';
import '../shared/failure/app_failure.dart';
import '../shared/time/household_clock.dart';
import 'household_route.dart';
import 'viewer_member.dart';

/// The family map, a member's day, and the household's places, under the
/// household shell (live-location ADR-0003 to ADR-0007).
List<GoRoute> liveLocationRoutes() => [
  GoRoute(
    path: '${HouseholdRoute.path}/${HouseholdRoute.whereSegment}',
    builder: (context, state) => ChangeNotifierProvider(
      create: (context) => LiveLocationController(
        liveLocationRepository: context.read<LiveLocationRepository>(),
        locationReporter: context.read<LocationReporter>(),
        placesRepository: context.read<PlacesRepository>(),
        householdId: HouseholdRoute.idFrom(state),
        viewerMemberId: viewerMemberIdOf(context),
        members: context.read<HouseholdView>().members,
      ),
      child: const LiveLocationScreen(),
    ),
    routes: [
      GoRoute(
        path: '${HouseholdRoute.historySegment}/:memberId',
        builder: (context, state) {
          final memberId = state.pathParameters['memberId'] ?? '';
          final member = context
              .read<HouseholdView>()
              .members
              .where((member) => member.id == memberId)
              .firstOrNull;
          if (member == null) return const NestLoadingView();
          return ChangeNotifierProvider(
            create: (context) => HistoryController(
              trailRepository: context.read<TrailRepository>(),
              placesRepository: context.read<PlacesRepository>(),
              householdId: HouseholdRoute.idFrom(state),
              memberId: memberId,
              clock: context.read<HouseholdClock>(),
            ),
            child: MemberHistoryScreen(
              member: member,
              isOwn: memberId == viewerMemberIdOf(context),
            ),
          );
        },
      ),
      GoRoute(
        path: HouseholdRoute.placesSegment,
        builder: (context, state) => ChangeNotifierProvider(
          create: (context) => PlacesController(
            placesRepository: context.read<PlacesRepository>(),
            householdId: HouseholdRoute.idFrom(state),
          ),
          child: const PlacesScreen(),
        ),
        routes: [
          GoRoute(
            path: ':placeId',
            builder: (context, state) => _PlaceEditorRoute(
              householdId: HouseholdRoute.idFrom(state),
              placeId: state.pathParameters['placeId'] ?? '',
            ),
          ),
        ],
      ),
    ],
  ),
];

/// A deep link to a place reads it once; a new place needs nothing read.
class _PlaceEditorRoute extends StatefulWidget {
  const _PlaceEditorRoute({required this.householdId, required this.placeId});

  final String householdId;
  final String placeId;

  @override
  State<_PlaceEditorRoute> createState() => _PlaceEditorRouteState();
}

class _PlaceEditorRouteState extends State<_PlaceEditorRoute> {
  late Future<List<FamilyPlace>> _places = _read();

  Future<List<FamilyPlace>> _read() =>
      context.read<PlacesRepository>().watchPlaces(widget.householdId).first;

  @override
  Widget build(BuildContext context) {
    if (widget.placeId == HouseholdRoute.newPlaceId) {
      return _PlaceEditor(householdId: widget.householdId, place: null);
    }
    return FutureBuilder<List<FamilyPlace>>(
      future: _places,
      builder: (context, places) {
        final error = places.error;
        if (error != null) {
          return NestScaffold(
            body: NestErrorView(
              message: AppCopy.failure(
                error is AppFailure ? error : UnknownFailure(error),
              ),
              retryLabel: AppCopy.retry,
              onRetry: () => setState(() => _places = _read()),
            ),
          );
        }
        final loaded = places.data;
        if (loaded == null) return const NestLoadingView();
        final place = loaded
            .where((place) => place.id == widget.placeId)
            .firstOrNull;
        if (place == null) {
          return const NestScaffold(
            body: NestEmptyView(
              title: LocationCopy.placeGoneTitle,
              message: LocationCopy.placeGoneBody,
              icon: LucideIcons.mapPinOff,
            ),
          );
        }
        return _PlaceEditor(householdId: widget.householdId, place: place);
      },
    );
  }
}

class _PlaceEditor extends StatelessWidget {
  const _PlaceEditor({required this.householdId, required this.place});

  final String householdId;
  final FamilyPlace? place;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) => PlaceEditorController(
      placesRepository: context.read<PlacesRepository>(),
      locationSource: context.read<LocationSource>(),
      householdId: householdId,
      place: place,
    ),
    child: const PlaceEditorScreen(),
  );
}

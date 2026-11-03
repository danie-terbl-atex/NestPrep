import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/live_location/data/firestore_live_location_repository.dart';
import '../features/live_location/data/firestore_places_repository.dart';
import '../features/live_location/data/firestore_trail_repository.dart';
import '../features/live_location/data/foreground_location_reporter.dart';
import '../features/live_location/data/geolocator_location_source.dart';
import '../features/live_location/data/live_location_repository.dart';
import '../features/live_location/data/location_engine.dart';
import '../features/live_location/data/location_reporter.dart';
import '../features/live_location/data/location_source.dart';
import '../features/live_location/data/method_channel_location_engine.dart';
import '../features/live_location/data/places_repository.dart';
import '../features/live_location/data/street_names.dart';
import '../features/live_location/data/trail_repository.dart';
import '../features/live_location/state/always_sharing.dart';
import 'backend_target.dart';
import 'emulator_endpoint.dart';

/// Family location (live-location ADR-0003 to ADR-0007). Above every route:
/// a window share keeps reporting when the person navigates away, and the
/// always-on engine outlives every screen.
List<SingleChildWidget> liveLocationProviders() => [
  Provider<LiveLocationRepository>(
    create: (context) =>
        FirestoreLiveLocationRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<PlacesRepository>(
    create: (context) =>
        FirestorePlacesRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<TrailRepository>(
    create: (context) =>
        FirestoreTrailRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<LocationSource>(
    create: (context) => const GeolocatorLocationSource(),
  ),
  Provider<LocationReporter>(
    create: (context) => ForegroundLocationReporter(
      locationSource: context.read<LocationSource>(),
      liveLocationRepository: context.read<LiveLocationRepository>(),
    ),
  ),
  Provider<LocationEngine>(create: (context) => MethodChannelLocationEngine()),
  Provider<StreetNames?>(
    create: (context) => StreetNames(context.read<LocationEngine>()),
  ),
  ChangeNotifierProvider<AlwaysSharing>(
    create: (context) => AlwaysSharing(
      engine: context.read<LocationEngine>(),
      liveLocationRepository: context.read<LiveLocationRepository>(),
      locationReporter: context.read<LocationReporter>(),
      emulator: BackendTarget.fromEnvironment() == BackendTarget.emulator
          ? EmulatorEndpoint.forThisDevice()
          : null,
    ),
  ),
];

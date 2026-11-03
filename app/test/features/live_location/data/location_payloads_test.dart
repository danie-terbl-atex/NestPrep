import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/live_location/data/firestore_places_repository.dart';
import 'package:nestprep/features/live_location/data/firestore_trail_repository.dart';
import 'package:nestprep/features/live_location/data/location_engine.dart';
import 'package:nestprep/features/live_location/data/method_channel_location_engine.dart';
import 'package:nestprep/features/live_location/model/coordinates.dart';
import 'package:nestprep/features/live_location/model/family_place.dart';
import 'package:nestprep/features/live_location/model/member_location.dart';
import 'package:nestprep/features/live_location/model/trail.dart';

/// The native engines write these documents and Dart reads them; the fixture
/// is the one both sides are held to (live-location ADR-0005).
void main() {
  final fixture = jsonDecode(
    File('test/fixtures/location_payloads.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  Map<String, dynamic> fields(String name) =>
      (fixture[name] as Map<String, dynamic>)['fields'] as Map<String, dynamic>;

  test('the start arguments are exactly the ones the engines read', () {
    final arguments = MethodChannelLocationEngine.startArguments(
      const EngineConfig(
        householdId: 'h1',
        memberId: 'm-sam',
        timeZone: 'Africa/Johannesburg',
        foreground: true,
        places: [
          FamilyPlace(
            id: 'school',
            name: 'School',
            centre: Coordinates(latitude: -26.1, longitude: 28.05),
            radiusMetres: 150,
            icon: PlaceIcon.school,
            alertOnArrive: true,
            alertOnLeave: false,
          ),
        ],
        notificationTitle: 'Sharing your location',
        notificationBody: 'The Oak Street Nest can see where you are.',
        notificationChannelName: 'Location sharing',
        notificationPauseLabel: 'Pause',
      ),
    );
    expect(jsonDecode(jsonEncode(arguments)), fixture['startArguments']);
  });

  test('a day the phone flushed reads back as its points', () {
    final point =
        ((fields('dayFlush')['points'] as Map)['arrayUnion'] as List).single;
    final points = FirestoreTrailRepository.pointsFrom({
      'points': [point],
    });
    expect(points.single.point.latitude, -26.2041);
    expect(points.single.accuracyMetres, 12);
    expect(points.single.at, DateTime.utc(2026, 10, 26, 7, 33, 20));
  });

  test('a point that does not parse is skipped, never a failed day', () {
    expect(
      FirestoreTrailRepository.pointsFrom({
        'points': [
          {'t': 'yesterday', 'la': 1, 'lo': 2},
          {'t': 1793000000, 'la': -26.2, 'lo': 28.0},
        ],
      }),
      hasLength(1),
    );
    expect(FirestoreTrailRepository.pointsFrom(null), isEmpty);
  });

  test('a place event the phone wrote reads back', () {
    final event = FirestoreTrailRepository.eventFrom({
      ...fields('placeEvent'),
      'at': Timestamp.fromDate(DateTime.utc(2026, 11, 2, 7, 30)),
    });
    expect(event?.placeId, 'school');
    expect(event?.kind, PlaceEventKind.arrive);
  });

  test('the live document the engine writes reads as continuous', () {
    final live = Map<String, dynamic>.of(fields('liveContinuous'))
      ..['point'] = const GeoPoint(-26.2041, 28.0473)
      ..['reportedAt'] = Timestamp.fromDate(DateTime.utc(2026, 11, 2, 7))
      ..['sharingUntil'] = Timestamp.fromDate(DateTime.utc(2026, 11, 3, 7))
      ..['id'] = 'm-sam';
    final location = MemberLocation.fromJson(live);
    expect(location.mode, ShareMode.continuous);
    expect(location.motion, DeviceMotion.driving);
    expect(location.batteryPercent, 64);
    expect(
      (fixture['motionValues'] as List).toSet(),
      DeviceMotion.values.map((motion) => motion.name).toSet(),
    );
  });

  test('a place is written with exactly the keys its rule names', () {
    const place = FamilyPlace(
      id: '',
      name: ' School ',
      centre: Coordinates(latitude: -26.1, longitude: 28.05),
      radiusMetres: 150,
      icon: PlaceIcon.school,
      alertOnArrive: true,
      alertOnLeave: false,
    );
    final data = FirestorePlacesRepository.placeData(place);
    expect(data.keys.toSet(), {
      'name',
      'centre',
      'radiusMetres',
      'icon',
      'alerts',
      'updatedAt',
    });
    expect(data['name'], 'School');
    expect(data['alerts'], {'arrive': true, 'leave': false});
    final back = FirestorePlacesRepository.placeFrom('p1', {
      ...data,
      'updatedAt': Timestamp.now(),
    });
    expect(back?.name, 'School');
    expect(back?.icon, PlaceIcon.school);
  });
}

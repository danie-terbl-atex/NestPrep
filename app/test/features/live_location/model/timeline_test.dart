import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/live_location/model/coordinates.dart';
import 'package:nestprep/features/live_location/model/family_place.dart';
import 'package:nestprep/features/live_location/model/timeline.dart';
import 'package:nestprep/features/live_location/model/trail.dart';

final _start = DateTime.utc(2026, 11, 2, 6);
const _home = Coordinates(latitude: -26.1000, longitude: 28.0500);
const _school = Coordinates(latitude: -26.1300, longitude: 28.0700);

TrailPoint _at(int minutes, Coordinates point) => TrailPoint(
  at: _start.add(Duration(minutes: minutes)),
  point: point,
  accuracyMetres: 10,
);

Coordinates _between(double share) => Coordinates(
  latitude: _home.latitude + (_school.latitude - _home.latitude) * share,
  longitude: _home.longitude + (_school.longitude - _home.longitude) * share,
);

const _homePlace = FamilyPlace(
  id: 'home',
  name: 'Home',
  centre: _home,
  radiusMetres: 150,
  icon: PlaceIcon.home,
  alertOnArrive: true,
  alertOnLeave: true,
);

void main() {
  test('a morning reads as home, the drive, then school', () {
    final day = TrailDay(
      points: [
        _at(0, _home),
        _at(45, _home),
        _at(50, _between(0.3)),
        _at(55, _between(0.7)),
        _at(60, _school),
        _at(90, _school),
      ],
      events: const [],
    );

    final entries = Timeline.of(day, const [_homePlace]);

    expect(entries.map((entry) => entry.runtimeType), [
      TimelineStop,
      TimelineJourney,
      TimelineStop,
    ]);
    final home = entries.first as TimelineStop;
    expect(home.place?.name, 'Home');
    expect(home.length, const Duration(minutes: 50));
    final drive = entries[1] as TimelineJourney;
    expect(drive.metres, greaterThan(3500));
    expect((entries.last as TimelineStop).place, isNull);
  });

  test('a phone silent while still is a stay until it next moved', () {
    final day = TrailDay(
      points: [_at(0, _home), _at(240, _between(0.5)), _at(245, _school)],
      events: const [],
    );

    final stop = Timeline.of(day, const []).first as TimelineStop;

    expect(stop.to, _start.add(const Duration(minutes: 240)));
  });

  test('passing through is not a stop', () {
    final day = TrailDay(
      points: [
        for (var minute = 0; minute <= 10; minute++)
          _at(minute, _between(minute / 10)),
      ],
      events: const [],
    );

    expect(Timeline.of(day, const []).whereType<TimelineStop>(), isEmpty);
  });

  test('an empty day has nothing on it', () {
    expect(Timeline.of(TrailDay.empty, const []), isEmpty);
  });

  test('the smaller place wins where two overlap', () {
    const street = FamilyPlace(
      id: 'street',
      name: 'Oak Street',
      centre: _home,
      radiusMetres: 500,
      icon: PlaceIcon.other,
      alertOnArrive: false,
      alertOnLeave: false,
    );
    expect(FamilyPlace.at(_home, const [street, _homePlace])?.id, 'home');
    expect(FamilyPlace.at(_school, const [street, _homePlace]), isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/location_reporting.dart';
import 'package:nestprep/features/live_location/data/foreground_location_reporter.dart';

import '../support/fake_live_location.dart';

/// The gate on background reporting (live-location ADR-0001).
///
/// It is a compile-time define, so `fromEnvironment` always answers
/// `foreground` under `flutter test` and every other branch is unreachable
/// through it — the same reason `BackendTarget` splits parsing from reading
/// the environment. What is worth proving is that a build asking for
/// `background` **fails** rather than quietly reporting foreground-only: a
/// silent downgrade would mean somebody relying on being findable finds out by
/// not being found.
void main() {
  late FakeLiveLocationRepository repository;
  late FakeLocationSource source;

  setUp(() {
    repository = FakeLiveLocationRepository();
    source = FakeLocationSource();
  });

  tearDown(() async {
    await repository.close();
    await source.close();
  });

  test('an unset define is foreground, so a plain build reports nothing '
      'in the background', () {
    expect(LocationReporting.fromEnvironment(), LocationReporting.foreground);
  });

  test('both modes have a name the define can carry', () {
    expect(
      LocationReporting.fromName('foreground'),
      LocationReporting.foreground,
    );
    expect(
      LocationReporting.fromName('background'),
      LocationReporting.background,
    );
  });

  test('a define nobody recognises fails loudly at startup', () {
    expect(
      () => LocationReporting.fromName('sometimes'),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('foreground builds get the reporter that exists', () {
    final reporter = locationReporterFor(
      LocationReporting.foreground,
      locationSource: source,
      liveLocationRepository: repository,
    );
    addTearDown((reporter as ForegroundLocationReporter).dispose);

    expect(reporter, isA<ForegroundLocationReporter>());
  });

  test('a background build refuses to start rather than pretending', () {
    expect(
      () => locationReporterFor(
        LocationReporting.background,
        locationSource: source,
        liveLocationRepository: repository,
      ),
      throwsA(
        isA<UnsupportedError>().having(
          (error) => error.message,
          'message',
          contains('phase 2'),
        ),
      ),
      reason:
          'falling back to foreground would ship a build somebody believes '
          'is reporting in the background, and is not',
    );
  });
}

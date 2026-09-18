import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/live_location/data/foreground_location_reporter.dart';
import 'package:nestprep/features/live_location/data/live_location_repository.dart';
import 'package:nestprep/features/live_location/data/location_source.dart';
import 'package:nestprep/features/live_location/model/coordinates.dart';
import 'package:nestprep/features/live_location/model/device_position.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_live_location.dart';

/// The writer, with a fake device under it.
///
/// Two numbers are the whole running cost of this feature — 100 metres before
/// the platform offers a fix, and 90 seconds before one of them becomes a write
/// (live-location ADR-0001). Neither is visible on a screen, neither fails
/// loudly when it is wrong, and both are the difference between a household of
/// five costing 250 writes a day and costing 400,000.
void main() {
  const somewhere = Coordinates(latitude: -26.2041, longitude: 28.0473);
  const elsewhere = Coordinates(latitude: -25.7479, longitude: 28.2293);

  late FakeLiveLocationRepository repository;
  late FakeLocationSource source;
  late DateTime clock;

  setUp(() {
    repository = FakeLiveLocationRepository();
    source = FakeLocationSource();
    clock = DateTime.utc(2026, 9, 18, 14);
  });

  tearDown(() async {
    await repository.close();
    await source.close();
  });

  ForegroundLocationReporter reporterFor() {
    final reporter = ForegroundLocationReporter(
      locationSource: source,
      liveLocationRepository: repository,
      now: () => clock,
    );
    addTearDown(reporter.dispose);
    return reporter;
  }

  Future<void> startAnHour(ForegroundLocationReporter reporter) =>
      reporter.start(
        householdId: 'h1',
        memberId: 'm-sam',
        until: clock.add(const Duration(hours: 1)),
      );

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('before anything is reported', () {
    test('the person on this phone is asked, and a refusal stops it', () async {
      final reporter = reporterFor();
      source.consent = LocationConsent.refused;

      await expectLater(
        startAnHour(reporter),
        throwsA(
          isA<LocationFailure>().having(
            (failure) => failure.problem,
            'problem',
            LocationProblem.permissionRefused,
          ),
        ),
      );
      expect(source.consentsAsked, 1);
      expect(repository.reported, isEmpty);
    });

    test('a permanent refusal is told apart from a temporary one', () async {
      final reporter = reporterFor();
      source.consent = LocationConsent.refusedForever;

      await expectLater(
        startAnHour(reporter),
        throwsA(
          isA<LocationFailure>().having(
            (failure) => failure.problem,
            'problem',
            LocationProblem.permissionRefusedForever,
          ),
        ),
      );
    });

    test('location switched off on the phone is its own answer', () async {
      final reporter = reporterFor();
      source.consent = LocationConsent.switchedOff;

      await expectLater(
        startAnHour(reporter),
        throwsA(
          isA<LocationFailure>().having(
            (failure) => failure.problem,
            'problem',
            LocationProblem.switchedOff,
          ),
        ),
      );
    });
  });

  group('while a share is open', () {
    test('the device is only asked for a fix after 100 metres', () async {
      final reporter = reporterFor();
      await startAnHour(reporter);

      expect(source.watchedWith, LiveLocationRepository.moveBeforeReporting);
      expect(LiveLocationRepository.moveBeforeReporting, 100);
    });

    test('the first fix is written, with the window on it', () async {
      final reporter = reporterFor();
      await startAnHour(reporter);

      source.emitPosition(
        const DevicePosition(at: somewhere, accuracyMetres: 12),
      );
      await settle();

      expect(repository.reported, hasLength(1));
      final write = repository.reported.single;
      expect(write.memberId, 'm-sam');
      expect(write.at, somewhere);
      expect(write.accuracyMetres, 12);
      expect(write.sharingUntil, clock.add(const Duration(hours: 1)));
    });

    test('a second fix inside 90 seconds is not a second write', () async {
      final reporter = reporterFor();
      await startAnHour(reporter);

      source.emitPosition(
        const DevicePosition(at: somewhere, accuracyMetres: 12),
      );
      await settle();
      clock = clock.add(const Duration(seconds: 89));
      source.emitPosition(
        const DevicePosition(at: elsewhere, accuracyMetres: 12),
      );
      await settle();

      expect(
        repository.reported,
        hasLength(1),
        reason:
            'the throttle is what makes walking pace and driving pace cost '
            'the same 40 writes an hour',
      );
    });

    test('and one past 90 seconds is', () async {
      final reporter = reporterFor();
      await startAnHour(reporter);

      source.emitPosition(
        const DevicePosition(at: somewhere, accuracyMetres: 12),
      );
      await settle();
      clock = clock.add(LiveLocationRepository.reportEvery);
      source.emitPosition(
        const DevicePosition(at: elsewhere, accuracyMetres: 30),
      );
      await settle();

      expect(repository.reported, hasLength(2));
      expect(repository.reported.last.at, elsewhere);
    });

    test('a refused write reaches the screen instead of the zone', () async {
      final reporter = reporterFor();
      await startAnHour(reporter);
      final problems = <AppFailure>[];
      reporter.problems.listen(problems.add, onError: problems.add);

      repository.failWritesWith = const PermissionDeniedFailure();
      source.emitPosition(
        const DevicePosition(at: somewhere, accuracyMetres: 12),
      );
      await settle();

      expect(problems, [isA<PermissionDeniedFailure>()]);
    });

    test('the device giving up says so, and the share ends', () async {
      final reporter = reporterFor();
      await startAnHour(reporter);
      final problems = <AppFailure>[];
      reporter.problems.listen(problems.add, onError: problems.add);

      source.failPositionsWith(StateError('location switched off'));
      await settle();

      expect(problems, [
        isA<LocationFailure>().having(
          (failure) => failure.problem,
          'problem',
          LocationProblem.reportingStopped,
        ),
      ]);

      source.emitPosition(
        const DevicePosition(at: somewhere, accuracyMetres: 12),
      );
      await settle();
      expect(
        repository.reported,
        isEmpty,
        reason: 'silence would have looked like standing still',
      );
    });
  });

  group('starting the same share again', () {
    test('changes nothing, because resuming runs on every emission', () async {
      final reporter = reporterFor();
      await startAnHour(reporter);
      await startAnHour(reporter);

      expect(source.consentsAsked, 1);

      source.emitPosition(
        const DevicePosition(at: somewhere, accuracyMetres: 12),
      );
      await settle();
      expect(repository.reported, hasLength(1));
    });

    test('but a different window is a different share', () async {
      final reporter = reporterFor();
      await startAnHour(reporter);
      await reporter.start(
        householdId: 'h1',
        memberId: 'm-sam',
        until: clock.add(const Duration(hours: 4)),
      );

      expect(source.consentsAsked, 2);
    });
  });

  group('stopping', () {
    test(
      'deletes what the household can see, and reports nothing after',
      () async {
        final reporter = reporterFor();
        await startAnHour(reporter);

        await reporter.stop(householdId: 'h1', memberId: 'm-sam');

        expect(repository.stopped.single.memberId, 'm-sam');

        source.emitPosition(
          const DevicePosition(at: somewhere, accuracyMetres: 12),
        );
        await settle();
        expect(repository.reported, isEmpty);
      },
    );

    test('a refused delete is thrown to whoever asked for it', () async {
      final reporter = reporterFor();
      await startAnHour(reporter);
      repository.failWritesWith = const UnavailableFailure();

      await expectLater(
        reporter.stop(householdId: 'h1', memberId: 'm-sam'),
        throwsA(isA<UnavailableFailure>()),
      );
    });
  });

  test('the window closing ends the share on its own', () async {
    // A real timer on a tiny window, rather than a fake clock: the thing worth
    // proving is that something is actually scheduled, and a fake clock would
    // pass whether or not it was.
    final reporter = reporterFor();
    await reporter.start(
      householdId: 'h1',
      memberId: 'm-sam',
      until: clock.add(const Duration(milliseconds: 20)),
    );

    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(repository.stopped.single.memberId, 'm-sam');

    source.emitPosition(
      const DevicePosition(at: somewhere, accuracyMetres: 12),
    );
    await settle();
    expect(repository.reported, isEmpty);
  });

  test('a window already past ends immediately rather than never', () async {
    final reporter = reporterFor();
    await reporter.start(
      householdId: 'h1',
      memberId: 'm-sam',
      until: clock.subtract(const Duration(minutes: 1)),
    );

    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(repository.stopped, hasLength(1));
  });
}

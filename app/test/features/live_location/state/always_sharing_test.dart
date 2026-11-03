import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/live_location/data/location_engine.dart';
import 'package:nestprep/features/live_location/state/always_sharing.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_live_location.dart';

const _subject = AlwaysSharingSubject(
  householdId: 'h1',
  memberId: 'm-sam',
  timeZone: 'Africa/Johannesburg',
  notificationTitle: 'Sharing your location',
  notificationBody: 'The Parkers can see where you are.',
  notificationChannelName: 'Location sharing',
  notificationPauseLabel: 'Pause',
);

void main() {
  late FakeLocationEngine engine;
  late FakeLiveLocationRepository repository;
  late FakeLocationReporter reporter;
  late AlwaysSharing always;

  setUp(() async {
    engine = FakeLocationEngine();
    repository = FakeLiveLocationRepository();
    reporter = FakeLocationReporter();
    always = AlwaysSharing(
      engine: engine,
      liveLocationRepository: repository,
      locationReporter: reporter,
      observeLifecycle: false,
    );
    await always.refresh();
  });

  tearDown(() async {
    always.dispose();
    await engine.close();
    await repository.close();
    await reporter.close();
  });

  test(
    'starts the engine for this member, in this household and zone',
    () async {
      await always.start(_subject, places: const []);

      final config = engine.started.single;
      expect(config.householdId, 'h1');
      expect(config.memberId, 'm-sam');
      expect(config.timeZone, 'Africa/Johannesburg');
      expect(config.emulatorHost, isNull);
      expect(always.isSharingFor('h1', 'm-sam'), isTrue);
      expect(always.isSharingFor('h2', 'm-sam'), isFalse);
    },
  );

  test(
    'asks a second time on Android 11+, where background is its own request',
    () async {
      engine
        ..current = const EnginePermissions(
          location: LocationAccess.denied,
          motion: MotionAccess.granted,
        )
        ..afterAskingAlwaysSequence = [
          const EnginePermissions(
            location: LocationAccess.whileInUse,
            motion: MotionAccess.granted,
          ),
          const EnginePermissions(
            location: LocationAccess.always,
            motion: MotionAccess.granted,
          ),
        ];

      await always.start(_subject, places: const []);

      expect(engine.alwaysAsked, 2);
      expect(engine.started, hasLength(1));
    },
  );

  test(
    'a window open on this phone gives way to always-on, pin kept',
    () async {
      await always.start(_subject, places: const []);
      expect(reporter.currentStops, [false]);
    },
  );

  test('signing out stops everything and removes the pin first', () async {
    await always.start(_subject, places: const []);

    await always.stopBeforeSignOut();

    expect(engine.stops, 1);
    expect(reporter.currentStops.last, isTrue);
    expect(repository.stopped.single, (householdId: 'h1', memberId: 'm-sam'));
    expect(always.isSharingFor('h1', 'm-sam'), isFalse);
  });

  test(
    'pausing tells the engine even when this side thought it had stopped',
    () async {
      await always.stop(householdId: 'h1', memberId: 'm-sam');
      expect(engine.stops, 1);
    },
  );

  test('asks for "all the time" when only while-in-use is given', () async {
    engine.current = const EnginePermissions(
      location: LocationAccess.whileInUse,
      motion: MotionAccess.granted,
    );

    await always.start(_subject, places: const []);

    expect(engine.alwaysAsked, 1);
    expect(engine.started, hasLength(1));
  });

  test('a no to "all the time" starts nothing and says why', () async {
    engine
      ..current = const EnginePermissions(
        location: LocationAccess.whileInUse,
        motion: MotionAccess.granted,
      )
      ..afterAskingAlways = const EnginePermissions(
        location: LocationAccess.whileInUse,
        motion: MotionAccess.granted,
      );

    await expectLater(
      always.start(_subject, places: const []),
      throwsA(
        isA<LocationFailure>().having(
          (failure) => failure.problem,
          'problem',
          LocationProblem.alwaysRefused,
        ),
      ),
    );
    expect(engine.started, isEmpty);
  });

  test('location switched off on the phone is said, not asked', () async {
    engine.current = const EnginePermissions(
      location: LocationAccess.off,
      motion: MotionAccess.granted,
    );
    await expectLater(
      always.start(_subject, places: const []),
      throwsA(isA<LocationFailure>()),
    );
    expect(engine.alwaysAsked, 0);
  });

  test(
    'pausing stops the engine and removes what the household sees',
    () async {
      await always.start(_subject, places: const []);

      await always.stop(householdId: 'h1', memberId: 'm-sam');

      expect(engine.stops, 1);
      expect(repository.stopped.single, (householdId: 'h1', memberId: 'm-sam'));
      expect(always.isSharingFor('h1', 'm-sam'), isFalse);
    },
  );

  test('premium ending stops it, and says so', () async {
    await always.start(_subject, places: const []);

    await always.stopForLapse(householdId: 'h1', memberId: 'm-sam');

    expect(engine.stops, 1);
    expect(always.stoppedBecause, EngineStopReason.refused);
  });

  test('a lapse elsewhere leaves this household alone', () async {
    await always.start(_subject, places: const []);
    await always.stopForLapse(householdId: 'h2', memberId: 'm-sam');
    expect(engine.stops, 0);
  });

  test('the engine stopping on its own is heard', () async {
    await always.start(_subject, places: const []);

    engine.stopOnItsOwn(EngineStopReason.permissionRevoked);
    await Future<void>.delayed(Duration.zero);

    expect(always.stoppedBecause, EngineStopReason.permissionRevoked);
    expect(always.isSharingFor('h1', 'm-sam'), isFalse);
  });

  test('places and cadence reach a running engine only', () async {
    await always.placesChanged(const []);
    await always.appInForeground(foreground: false);
    expect(engine.placeUpdates, isEmpty);
    expect(engine.cadence, isEmpty);

    await always.start(_subject, places: const []);
    await always.placesChanged(const []);
    await always.appInForeground(foreground: false);
    expect(engine.placeUpdates, hasLength(1));
    expect(engine.cadence, [false]);
    expect(engine.started.single.foreground, isFalse);
  });
}

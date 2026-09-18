import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/live_location/model/coordinates.dart';
import 'package:nestprep/features/live_location/model/live_location_view.dart';
import 'package:nestprep/features/live_location/model/located_member.dart';
import 'package:nestprep/features/live_location/model/member_location.dart';
import 'package:nestprep/features/live_location/model/share_duration.dart';
import 'package:nestprep/features/live_location/state/live_location_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_live_location.dart';
import '../../../support/household_fixtures.dart';

/// The controller behind fake everything: no Firestore, no device, no map
/// (foundation ADR-0006).
///
/// The cases that matter are the consent ones. Starting a share is the only
/// write this screen makes, and it can only ever be for the person holding the
/// phone (live-location ADR-0002).
void main() {
  final now = DateTime.utc(2026, 9, 18, 14);
  const somewhere = Coordinates(latitude: -26.2041, longitude: 28.0473);

  late FakeLiveLocationRepository repository;
  late FakeLocationReporter reporter;

  setUp(() {
    repository = FakeLiveLocationRepository();
    reporter = FakeLocationReporter();
  });

  tearDown(() async {
    await repository.close();
    await reporter.close();
  });

  LiveLocationController controllerFor({
    String viewerMemberId = Fixtures.samMemberId,
  }) {
    final controller = LiveLocationController(
      liveLocationRepository: repository,
      locationReporter: reporter,
      householdId: Fixtures.householdId,
      viewerMemberId: viewerMemberId,
      members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
      now: () => now,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  MemberLocation locationFor(
    String memberId, {
    Duration sharingFor = const Duration(hours: 1),
  }) => MemberLocation(
    id: memberId,
    point: somewhere,
    accuracyMetres: 10,
    reportedAt: now,
    sharingUntil: now.add(sharingFor),
  );

  LiveLocationView dataOf(LiveLocationController controller) =>
      (controller.view as AsyncData<LiveLocationView>).value;

  test(
    'it starts loading and shows the household once the read lands',
    () async {
      final controller = controllerFor();
      expect(controller.view, isA<AsyncLoading<LiveLocationView>>());

      repository.emitLocations([]);
      await Future<void>.delayed(Duration.zero);

      expect(dataOf(controller).others, hasLength(2));
    },
  );

  test('a refused read becomes a failure the screen can render', () async {
    final controller = controllerFor();
    repository.failLocationsWith(const PermissionDeniedFailure());
    await Future<void>.delayed(Duration.zero);

    expect(controller.view, isA<AsyncFailure<LiveLocationView>>());
  });

  test(
    'anything that is not one of ours is still a failure, not a crash',
    () async {
      final controller = controllerFor();
      repository.failLocationsWith(StateError('a socket closed'));
      await Future<void>.delayed(Duration.zero);

      expect(
        (controller.view as AsyncFailure<LiveLocationView>).failure,
        isA<UnknownFailure>(),
      );
    },
  );

  group('starting a share', () {
    test('is for the person holding the phone and nobody else', () async {
      final controller = controllerFor();
      repository.emitLocations([]);
      await Future<void>.delayed(Duration.zero);

      await controller.shareFor(ShareDuration.oneHour);

      expect(reporter.started, hasLength(1));
      expect(reporter.started.single.memberId, Fixtures.samMemberId);
      expect(reporter.started.single.until, now.add(const Duration(hours: 1)));
    });

    test('carries the window the person picked, not a default', () async {
      final controller = controllerFor();

      await controller.shareFor(ShareDuration.fifteenMinutes);
      await controller.shareFor(ShareDuration.fourHours);

      expect(reporter.started.map((start) => start.until), [
        now.add(const Duration(minutes: 15)),
        now.add(const Duration(hours: 4)),
      ]);
    });

    test('a refusal on the device becomes copy, not silence', () async {
      final controller = controllerFor();
      reporter.refuseStartWith = const LocationFailure(
        LocationProblem.permissionRefusedForever,
      );

      await controller.shareFor(ShareDuration.oneHour);

      expect(
        controller.actionFailure,
        isA<LocationFailure>().having(
          (failure) => failure.problem,
          'problem',
          LocationProblem.permissionRefusedForever,
        ),
      );
    });
  });

  group('stopping', () {
    test('asks the reporter to stop for the viewer', () async {
      final controller = controllerFor();

      await controller.stopSharing();

      expect(reporter.stopped.single.memberId, Fixtures.samMemberId);
    });

    test('a refused stop is shown rather than swallowed', () async {
      final controller = controllerFor();
      reporter.refuseStopWith = const UnavailableFailure();

      await controller.stopSharing();

      expect(controller.actionFailure, isA<UnavailableFailure>());
    });
  });

  group('a window that is still open when the app comes back', () {
    test('is picked up again, so the pin does not go stale under a label '
        'that says otherwise', () async {
      // The controller is what opens the read; the test's subject is what the
      // reporter is then asked for, so it is never referred to again.
      controllerFor();
      repository.emitLocations([locationFor(Fixtures.samMemberId)]);
      await Future<void>.delayed(Duration.zero);

      expect(reporter.started, hasLength(1));
      expect(
        reporter.started.single.until,
        now.add(const Duration(hours: 1)),
        reason: 'the window the person opened, not a new one',
      );
    });

    test('is picked up once, however many times the read emits', () async {
      final controller = controllerFor();
      repository.emitLocations([locationFor(Fixtures.samMemberId)]);
      await Future<void>.delayed(Duration.zero);
      repository.emitLocations([locationFor(Fixtures.samMemberId)]);
      await Future<void>.delayed(Duration.zero);

      expect(reporter.started, hasLength(1));
      expect(dataOf(controller).viewer?.isSharing, isTrue);
    });

    test('a window that has closed is never resumed', () async {
      final controller = controllerFor();
      repository.emitLocations([
        locationFor(
          Fixtures.samMemberId,
          sharingFor: const Duration(seconds: -1),
        ),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(
        reporter.started,
        isEmpty,
        reason: 'a share that ended is a decision, not an interruption',
      );
      expect(dataOf(controller).viewer?.presence, MemberPresence.notSharing);
    });

    test(
      'somebody else"s open window is not this device"s to resume',
      () async {
        final controller = controllerFor();
        repository.emitLocations([locationFor(Fixtures.thandiMemberId)]);
        await Future<void>.delayed(Duration.zero);

        expect(reporter.started, isEmpty);
        expect(dataOf(controller).viewer?.isSharing, isFalse);
      },
    );
  });

  test('a share that stops on its own says so', () async {
    final controller = controllerFor();
    reporter.reportProblem(
      const LocationFailure(LocationProblem.reportingStopped),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.actionFailure, isA<LocationFailure>());
  });

  test('retry reopens the read and clears what was there', () async {
    final controller = controllerFor();
    repository.failLocationsWith(const UnavailableFailure());
    await Future<void>.delayed(Duration.zero);
    expect(controller.view, isA<AsyncFailure<LiveLocationView>>());

    await controller.retry();
    expect(controller.view, isA<AsyncLoading<LiveLocationView>>());

    repository.emitLocations([]);
    await Future<void>.delayed(Duration.zero);
    expect(controller.view, isA<AsyncData<LiveLocationView>>());
  });
}

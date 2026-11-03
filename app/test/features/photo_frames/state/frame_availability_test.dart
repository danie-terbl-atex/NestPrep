import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/photo_frames/state/frame_availability.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_photo_frames.dart';
import '../../../support/household_fixtures.dart';

void main() {
  late FakePhotoFrameRepository repository;

  setUp(() => repository = FakePhotoFrameRepository());
  tearDown(() => repository.close());

  FrameAvailability availability({bool isFamily = true}) {
    final availability = FrameAvailability(
      photoFrameRepository: repository,
      householdId: Fixtures.householdId,
      isFamily: isFamily,
    );
    addTearDown(availability.dispose);
    return availability;
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('hidden until the flag is followed', () {
    expect(availability().state, FrameAvailabilityState.hidden);
  });

  test('family with frames on: loading, then none or some', () async {
    final frames = availability()..followFlag(framesOn: true);
    expect(frames.state, FrameAvailabilityState.loading);

    repository.emit([]);
    await settle();
    expect(frames.state, FrameAvailabilityState.none);

    repository.emit([FrameFixtures.frame()]);
    await settle();
    expect(frames.state, FrameAvailabilityState.some);

    repository.emit([]);
    await settle();
    expect(frames.state, FrameAvailabilityState.none);
  });

  test('somebody who is not family never listens', () async {
    final frames = availability(isFamily: false)..followFlag(framesOn: true);
    repository.emit([FrameFixtures.frame()]);
    await settle();

    expect(frames.state, FrameAvailabilityState.hidden);
  });

  test('the flag off keeps it hidden', () async {
    final frames = availability()..followFlag(framesOn: false);
    repository.emit([FrameFixtures.frame()]);
    await settle();

    expect(frames.state, FrameAvailabilityState.hidden);
  });

  test(
    'the flag switching off stops listening; back on starts again',
    () async {
      final frames = availability()..followFlag(framesOn: true);
      repository.emit([FrameFixtures.frame()]);
      await settle();
      expect(frames.state, FrameAvailabilityState.some);

      frames.followFlag(framesOn: false);
      expect(frames.state, FrameAvailabilityState.hidden);
      repository.emit([FrameFixtures.frame()]);
      await settle();
      expect(frames.state, FrameAvailabilityState.hidden);

      frames.followFlag(framesOn: true);
      expect(frames.state, FrameAvailabilityState.loading);
      repository.emit([]);
      await settle();
      expect(frames.state, FrameAvailabilityState.none);
    },
  );

  test('the same flag again is nothing new', () {
    var notified = 0;
    final frames = availability()
      ..followFlag(framesOn: true)
      ..addListener(() => notified++);
    frames.followFlag(framesOn: true);

    expect(notified, 0);
  });

  test('an unreadable list hides it rather than guessing', () async {
    final frames = availability()..followFlag(framesOn: true);
    repository.failWith(const UnavailableFailure());
    await settle();

    expect(frames.state, FrameAvailabilityState.hidden);
  });

  test('dispose stops listening', () async {
    final frames = FrameAvailability(
      photoFrameRepository: repository,
      householdId: Fixtures.householdId,
      isFamily: true,
    )..followFlag(framesOn: true);
    frames.dispose();

    expect(repository.hasListener, isFalse);
  });
}

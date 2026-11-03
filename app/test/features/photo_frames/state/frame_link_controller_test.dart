import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/photo_frames/model/frame_panels.dart';
import 'package:nestprep/features/photo_frames/state/frame_link_controller.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_photo_frames.dart';
import '../../../support/household_fixtures.dart';

void main() {
  late FakePhotoFrameDirectory directory;
  late FrameLinkController link;

  setUp(() {
    directory = FakePhotoFrameDirectory();
    link = FrameLinkController(
      photoFrameDirectory: directory,
      householdId: Fixtures.householdId,
      helpers: [Fixtures.thandi],
    );
  });

  tearDown(() => link.dispose());

  test('starts on the code, scanning', () {
    expect(link.step, FrameLinkStep.code);
    expect(link.isTyping, isFalse);
  });

  test('a scanned frame code moves on to the details', () {
    link.scanned('nestprep://frame/ABC234');
    expect(link.step, FrameLinkStep.details);
    expect(link.code, 'ABC234');
  });

  test('a scan that is not ours says so, and keeps scanning', () {
    link.scanned('https://example.com');
    expect(link.step, FrameLinkStep.code);
    expect(link.scanWasNotOurs, isTrue);

    link.scanned('nestprep://frame/ABC234');
    expect(link.step, FrameLinkStep.details);
    expect(link.scanWasNotOurs, isFalse);
  });

  test('a scan while typing is ignored', () {
    link
      ..typeInstead()
      ..scanned('nestprep://frame/ABC234');
    expect(link.step, FrameLinkStep.code);
  });

  test('a typed code goes on only once it is whole', () {
    link
      ..typeInstead()
      ..setTypedCode('abc23')
      ..useTypedCode();
    expect(link.canUseTypedCode, isFalse);
    expect(link.step, FrameLinkStep.code);

    link
      ..setTypedCode('abc234')
      ..useTypedCode();
    expect(link.step, FrameLinkStep.details);
    expect(link.code, 'ABC234');
  });

  test('a new frame adds events unless it is told not to', () async {
    expect(link.panels.addEvents, isTrue);
    link.scanned('ABC234');
    await link.link('Kitchen frame');
    expect(directory.claimed.single.panels.addEvents, isTrue);
  });

  test('linking claims the code with the name and the panels', () async {
    const panels = FramePanels(todos: false, helperMemberId: 'm-thandi');
    link
      ..scanned('ABC234')
      ..setPanels(panels);
    await link.link('  Kitchen frame ');

    expect(directory.claimed.single.code, 'ABC234');
    expect(directory.claimed.single.name, 'Kitchen frame');
    expect(directory.claimed.single.panels, panels);
    expect(link.step, FrameLinkStep.linked);
  });

  test('one claim at a time', () async {
    directory.holdCalls = Completer<void>();
    link.scanned('ABC234');
    final first = link.link('Kitchen frame');
    unawaited(link.link('Kitchen frame'));
    expect(link.isLinking, isTrue);
    directory.holdCalls!.complete();
    await first;
    expect(directory.claimed, hasLength(1));
  });

  test(
    'a refusal stays on the details, and a different code clears it',
    () async {
      directory.failWith = const PhotoFrameFailure(
        PhotoFrameProblem.frameCodeExpired,
      );
      link.scanned('ABC234');
      await link.link('Kitchen frame');

      expect(link.step, FrameLinkStep.details);
      expect(
        link.failure,
        isA<PhotoFrameFailure>().having(
          (failure) => failure.problem,
          'problem',
          PhotoFrameProblem.frameCodeExpired,
        ),
      );

      link.differentCode();
      expect(link.step, FrameLinkStep.code);
      expect(link.failure, isNull);
      expect(link.code, isNull);
    },
  );
}

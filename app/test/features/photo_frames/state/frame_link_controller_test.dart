import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_area.dart';
import 'package:nestprep/features/add_to_woolworths/model/woolworths_store.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/live_location/model/coordinates.dart';
import 'package:nestprep/features/photo_frames/model/frame_groceries.dart';
import 'package:nestprep/features/photo_frames/model/frame_panels.dart';
import 'package:nestprep/features/photo_frames/state/frame_link_controller.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_photo_frames.dart';
import '../../../support/household_fixtures.dart';

void main() {
  late FakePhotoFrameDirectory directory;
  late FakePhotoFrameRepository repository;
  late FrameLinkController link;
  late List<Coordinates> storesAsked;
  AppFailure? storeFailure;

  setUp(() {
    directory = FakePhotoFrameDirectory();
    repository = FakePhotoFrameRepository();
    storesAsked = [];
    storeFailure = null;
    link = FrameLinkController(
      photoFrameDirectory: directory,
      photoFrameRepository: repository,
      woolworthsStoreFor: (near) async {
        storesAsked.add(near);
        if (storeFailure case final failure?) throw failure;
        return const WoolworthsStore(id: '2008', priceZone: 'p30');
      },
      householdId: Fixtures.householdId,
      helpers: [Fixtures.thandi],
    );
  });

  tearDown(() async {
    link.dispose();
    await repository.close();
  });

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

  group('groceries chosen while linking', () {
    test('no groceries chosen writes nothing after the claim', () async {
      link.scanned('ABC234');
      await link.link('Kitchen frame');
      expect(link.step, FrameLinkStep.linked);
      expect(repository.groceriesSet, isEmpty);
    });

    test('are written to the frame the claim made', () async {
      const groceries = FrameGroceries(
        shop: ProductRetailer.checkers,
        area: CheckersArea.capeTown,
      );
      link
        ..scanned('ABC234')
        ..setGroceries(groceries);
      await link.link('Kitchen frame');

      expect(link.step, FrameLinkStep.linked);
      expect(repository.groceriesSet.single.frameId, 'frame-1');
      expect(repository.groceriesSet.single.groceries, groceries);
      expect(link.groceriesDidNotSave, isFalse);
      expect(storesAsked, isEmpty);
    });

    test('at Woolworths, carry the store found for the area', () async {
      link
        ..scanned('ABC234')
        ..setGroceries(
          const FrameGroceries(
            shop: ProductRetailer.woolworths,
            area: CheckersArea.durban,
          ),
        );
      await link.link('Kitchen frame');

      expect(storesAsked.single, CheckersArea.durban.centre);
      expect(
        repository.groceriesSet.single.groceries?.store,
        const WoolworthsStore(id: '2008', priceZone: 'p30'),
      );
    });

    test('a store lookup that fails links nothing', () async {
      storeFailure = const WoolworthsFailure(
        WoolworthsProblem.catalogueUnreachable,
      );
      link
        ..scanned('ABC234')
        ..setGroceries(
          const FrameGroceries(
            shop: ProductRetailer.woolworths,
            area: CheckersArea.durban,
          ),
        );
      await link.link('Kitchen frame');

      expect(link.step, FrameLinkStep.details);
      expect(link.failure, isA<WoolworthsFailure>());
      expect(directory.claimed, isEmpty);
    });

    test('a refused groceries write still ends linked, and says so', () async {
      repository.failGroceriesWith = const PhotoFrameFailure(
        PhotoFrameProblem.frameNotFound,
      );
      link
        ..scanned('ABC234')
        ..setGroceries(
          const FrameGroceries(
            shop: ProductRetailer.checkers,
            area: CheckersArea.capeTown,
          ),
        );
      await link.link('Kitchen frame');

      expect(link.step, FrameLinkStep.linked);
      expect(link.failure, isNull);
      expect(link.groceriesDidNotSave, isTrue);
    });
  });
}

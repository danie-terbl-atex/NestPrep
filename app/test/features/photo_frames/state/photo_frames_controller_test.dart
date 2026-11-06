import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_area.dart';
import 'package:nestprep/features/add_to_woolworths/model/woolworths_store.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/features/live_location/model/coordinates.dart';
import 'package:nestprep/features/photo_frames/model/frame_groceries.dart';
import 'package:nestprep/features/photo_frames/model/frame_panels.dart';
import 'package:nestprep/features/photo_frames/model/frame_screensaver.dart';
import 'package:nestprep/features/photo_frames/state/photo_frames_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_photo_frames.dart';
import '../../../support/household_fixtures.dart';

void main() {
  late FakePhotoFrameRepository repository;
  late PhotoFramesController controller;
  late List<Coordinates> lookedUp;

  Future<WoolworthsStore> woolworthsStore(Coordinates near) async {
    lookedUp.add(near);
    return const WoolworthsStore(id: '2008', priceZone: 'p60');
  }

  const nanny = Member(
    id: 'm-nanny',
    displayName: 'Grace Nanny',
    color: MemberColor.sky,
    roleName: 'carer',
  );

  setUp(() {
    lookedUp = [];
    repository = FakePhotoFrameRepository();
    controller = PhotoFramesController(
      photoFrameRepository: repository,
      householdId: Fixtures.householdId,
      members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid, nanny],
    );
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  test('loads, then holds the frames as they arrive', () async {
    expect(controller.frames, isA<AsyncLoading<Object?>>());
    repository.emit([FrameFixtures.frame()]);
    await pumpEventQueue();
    expect(
      controller.frames,
      isA<AsyncData<Object?>>().having(
        (state) => (state as AsyncData).value,
        'value',
        hasLength(1),
      ),
    );
  });

  test('an unreadable list is a failure with a retry', () async {
    repository.failWith(const PermissionDeniedFailure());
    await pumpEventQueue();
    expect(controller.frames, isA<AsyncFailure<Object?>>());

    await controller.retry();
    expect(controller.frames, isA<AsyncLoading<Object?>>());
    repository.emit(const []);
    await pumpEventQueue();
    expect(controller.frames, isA<AsyncData<Object?>>());
  });

  test('a helper’s day is offered for helpers and carers, nobody else', () {
    expect(controller.helpers.map((member) => member.id), [
      Fixtures.thandiMemberId,
      nanny.id,
    ]);
    expect(controller.helperById(nanny.id), nanny);
    expect(controller.helperById(Fixtures.samMemberId), isNull);
  });

  test(
    'saving writes the trimmed name, the panels, the screensaver and groceries',
    () async {
      const panels = FramePanels(meals: false, helperMemberId: 'm-thandi');
      const screensaver = FrameScreensaver(idleMinutes: 5, secondsPerPhoto: 30);
      const groceries = FrameGroceries(
        shop: ProductRetailer.pickNPay,
        area: CheckersArea.durban,
      );
      final saved = await controller.save(
        FrameFixtures.frame(),
        name: '  Hall frame ',
        panels: panels,
        screensaver: screensaver,
        groceries: groceries,
        woolworthsStoreFor: woolworthsStore,
      );

      expect(saved, isTrue);
      expect(repository.updated.single.frameId, 'frame-kitchen');
      expect(repository.updated.single.name, 'Hall frame');
      expect(repository.updated.single.panels, panels);
      expect(repository.updated.single.screensaver, screensaver);
      expect(repository.updated.single.groceries, groceries);
      expect(lookedUp, isEmpty);
    },
  );

  test('saving at Woolworths looks the store up for the area, every time, '
      'and no other shop keeps one', () async {
    Future<bool> save(FrameGroceries groceries) => controller.save(
      FrameFixtures.frame(),
      name: 'Hall frame',
      panels: const FramePanels(),
      screensaver: FrameScreensaver.off,
      groceries: groceries,
      woolworthsStoreFor: woolworthsStore,
    );
    const stale = FrameGroceries(
      shop: ProductRetailer.woolworths,
      area: CheckersArea.durban,
      store: WoolworthsStore(id: '1', priceZone: 'p10'),
    );

    expect(await save(stale), isTrue);
    expect(await save(stale.copyWith(shop: ProductRetailer.checkers)), isTrue);

    expect(lookedUp, [CheckersArea.durban.centre]);
    expect(repository.updated.map((update) => update.groceries).toList(), [
      stale.copyWith(
        store: const WoolworthsStore(id: '2008', priceZone: 'p60'),
      ),
      const FrameGroceries(
        shop: ProductRetailer.checkers,
        area: CheckersArea.durban,
      ),
    ]);
  });

  test('a Woolworths area with no store does not save, and says why', () async {
    final saved = await controller.save(
      FrameFixtures.frame(),
      name: 'Hall frame',
      panels: const FramePanels(),
      screensaver: FrameScreensaver.off,
      groceries: const FrameGroceries(
        shop: ProductRetailer.woolworths,
        area: CheckersArea.eastLondon,
      ),
      woolworthsStoreFor: (_) async =>
          throw const WoolworthsFailure(WoolworthsProblem.noStoreNearby),
    );

    expect(saved, isFalse);
    expect(repository.updated, isEmpty);
    expect(
      controller.actionFailure,
      isA<WoolworthsFailure>().having(
        (failure) => failure.problem,
        'problem',
        WoolworthsProblem.noStoreNearby,
      ),
    );
    expect(controller.isSaving, isFalse);
  });

  test('a refused save is kept, and says it did not save', () async {
    repository.failWrites = const PermissionDeniedFailure();
    final saved = await controller.save(
      FrameFixtures.frame(),
      name: 'Hall frame',
      panels: const FramePanels(),
      screensaver: FrameScreensaver.off,
      groceries: null,
      woolworthsStoreFor: woolworthsStore,
    );

    expect(saved, isFalse);
    expect(controller.actionFailure, isA<PermissionDeniedFailure>());
  });

  test('unlinking deletes the frame', () async {
    expect(await controller.unlink(FrameFixtures.frame()), isTrue);
    expect(repository.unlinked, ['frame-kitchen']);
  });

  test('closing a sheet forgets what it refused', () async {
    controller.openSheet();
    repository.failWrites = const UnavailableFailure();
    await controller.unlink(FrameFixtures.frame());
    expect(controller.isInSheet, isTrue);
    expect(controller.actionFailure, isNotNull);

    controller.closeSheet();
    expect(controller.isInSheet, isFalse);
    expect(controller.actionFailure, isNull);
  });

  test('a name is one to forty characters, once trimmed', () {
    expect(PhotoFramesController.isValidName('Kitchen frame'), isTrue);
    expect(PhotoFramesController.isValidName('   '), isFalse);
    expect(PhotoFramesController.isValidName('a' * 40), isTrue);
    expect(PhotoFramesController.isValidName('a' * 41), isFalse);
  });
}

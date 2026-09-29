import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/home_care/model/home_care_board.dart';
import 'package:nestprep/features/home_care/model/home_care_product.dart';
import 'package:nestprep/features/home_care/model/product_kind.dart';
import 'package:nestprep/features/home_care/model/room_kind.dart';
import 'package:nestprep/features/home_care/state/home_care_controller.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_home_care.dart';
import '../../../support/home_care_fixtures.dart';
import '../../../support/household_fixtures.dart';

void main() {
  late FakeCleaningJobRepository jobs;
  late FakeHomeCareLibraryRepository library;
  late HomeCareController controller;

  HomeCareController build(HouseholdView view) => HomeCareController(
    jobRepository: jobs,
    libraryRepository: library,
    householdId: Fixtures.householdId,
    household: view,
  );

  setUp(() {
    jobs = FakeCleaningJobRepository();
    library = FakeHomeCareLibraryRepository();
    controller = build(Fixtures.view());
  });

  tearDown(() async {
    controller.dispose();
    await jobs.close();
    await library.close();
  });

  Future<void> emitAll() async {
    jobs.emitJobs([HomeCareFixtures.job()]);
    library.emitRooms([HomeCareFixtures.kitchen]);
    library.emitProducts(const [HomeCareFixtures.bleach]);
    await pumpEventQueue();
  }

  test('holds its loading state until all three reads have answered', () async {
    jobs.emitJobs([HomeCareFixtures.job()]);
    library.emitRooms([HomeCareFixtures.kitchen]);
    await pumpEventQueue();
    expect(controller.board, isA<AsyncLoading<HomeCareBoard>>());

    library.emitProducts(const [HomeCareFixtures.bleach]);
    await pumpEventQueue();
    final board = (controller.board as AsyncData<HomeCareBoard>).value;
    expect(board.jobs.single.id, 'oven');
    expect(board.productsOf(board.jobs.single).single.name, 'Jik');
  });

  test('family reads every job', () {
    expect(jobs.jobsAskedFor, [null]);
  });

  test('a helper holding `own` asks for exactly her own jobs', () async {
    controller.dispose();
    controller = build(HomeCareFixtures.helperView());
    expect(jobs.jobsAskedFor.last, Fixtures.thandiMemberId);
  });

  test('a helper with no home care is refused before anything is read', () {
    controller.dispose();
    jobs.jobsAskedFor.clear();
    controller = build(HomeCareFixtures.noCleaningView());
    expect(controller.board, isA<AsyncFailure<HomeCareBoard>>());
    expect(jobs.jobsAskedFor, isEmpty);
  });

  test('a read that fails becomes the board’s failure, with a retry', () async {
    library.failRoomsWith(const UnavailableFailure());
    await pumpEventQueue();
    expect(
      (controller.board as AsyncFailure<HomeCareBoard>).failure,
      isA<UnavailableFailure>(),
    );
    await controller.retry();
    expect(controller.board, isA<AsyncLoading<HomeCareBoard>>());
    await emitAll();
    expect(controller.board, isA<AsyncData<HomeCareBoard>>());
  });

  test('a changed grant that narrows the jobs reads them again', () async {
    controller.dispose();
    controller = build(HomeCareFixtures.lookingHelperView());
    expect(jobs.jobsAskedFor.last, isNull);
    controller.followHousehold(HomeCareFixtures.helperView());
    await pumpEventQueue();
    expect(jobs.jobsAskedFor.last, Fixtures.thandiMemberId);
    expect(controller.access.jobScope, Fixtures.thandiMemberId);
  });

  test('the same household twice changes nothing', () async {
    await emitAll();
    var told = 0;
    controller.addListener(() => told++);
    controller.followHousehold(Fixtures.view());
    expect(told, 0);
  });

  group('the library', () {
    test(
      'adds the usual rooms in one write, stamped with the viewer',
      () async {
        await controller.library.addRooms(HomeCareLibraryCopy.usualRooms);
        final (method, arguments) = library.writes.single;
        expect(method, 'addRooms');
        expect(arguments['createdBy'], Fixtures.samMemberId);
        expect(arguments['rooms'], HomeCareLibraryCopy.usualRooms);
      },
    );

    test('saves a room with its name trimmed', () async {
      await controller.library.saveRoom(
        name: '  Scullery ',
        kind: RoomKind.other,
      );
      expect(library.writes.single.$2['name'], 'Scullery');
    });

    test(
      'stamps a new product with the viewer, and keeps an old one’s',
      () async {
        await controller.library.saveProduct(
          const HomeCareProduct(
            id: '',
            name: 'Handy Andy',
            kind: ProductKind.allPurpose,
            createdBy: '',
          ),
        );
        final saved = library.writes.single.$2['product']! as HomeCareProduct;
        expect(saved.createdBy, Fixtures.samMemberId);

        await controller.library.saveProduct(HomeCareFixtures.bleach);
        expect(library.writes.last.$2['product'], HomeCareFixtures.bleach);
      },
    );

    test('a refusal is kept for the banner, not thrown', () async {
      library.failWritesWith = const PermissionDeniedFailure();
      await controller.library.deleteRoom('kitchen');
      expect(controller.actionFailure, isA<PermissionDeniedFailure>());
      controller.dismissActionFailure();
      expect(controller.actionFailure, isNull);
    });

    test('deletes a room and a product by id', () async {
      await controller.library.deleteRoom('kitchen');
      await controller.library.deleteProduct('jik');
      expect(library.methods, ['deleteRoom', 'deleteProduct']);
    });
  });

  test('offers a job to helpers first', () {
    expect(controller.helpers.first.id, Fixtures.thandiMemberId);
  });
}

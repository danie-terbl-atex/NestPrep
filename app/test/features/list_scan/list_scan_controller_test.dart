import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/list_scan/data/list_photo_picker.dart';
import 'package:nestprep/features/list_scan/model/list_reading.dart';
import 'package:nestprep/features/list_scan/state/list_scan_controller.dart';
import 'package:nestprep/features/plan_week/data/shop_week_groceries.dart';
import 'package:nestprep/features/recipes/data/recipe_groceries.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../support/fake_grocery_repository.dart';
import '../../support/fake_list_scan.dart';
import '../../support/grocery_list_harness.dart';
import '../../support/household_fixtures.dart';

void main() {
  late FakeListScanReader reader;
  late FakeListPhotoPicker picker;
  late FakeGroceryRepository groceries;
  late ListScanController controller;

  setUp(() {
    reader = FakeListScanReader();
    picker = FakeListPhotoPicker();
    groceries = FakeGroceryRepository();
    controller = ListScanController(
      listScanReader: reader,
      listPhotoPicker: picker,
      groceries: RecipeGroceries(
        groceryRepository: groceries,
        matched: ShopWeekGroceries(
          groceryRepository: groceries,
          householdId: Fixtures.householdId,
          memberId: Fixtures.samMemberId,
        ),
        householdId: Fixtures.householdId,
        memberId: Fixtures.samMemberId,
      ),
      householdId: Fixtures.householdId,
    );
  });

  tearDown(() async {
    controller.dispose();
    await groceries.close();
  });

  /// Adds, answering each read of the list with [list].
  Future<void> addWith(List<GroceryItem> list) async {
    final adding = controller.addToList();
    for (var i = 0; i < 4; i++) {
      await pumpEventQueue();
      groceries.emitItems(list);
    }
    await adding;
  }

  test('reads the photo it was given, for this household', () async {
    await controller.pick(ListPhotoSource.camera);

    expect(picker.asked, [ListPhotoSource.camera]);
    expect(reader.requests.single.householdId, Fixtures.householdId);
    expect(reader.requests.single.photo, same(aListPhoto));
    expect(controller.step, ListScanStep.review);
    expect(controller.lines.map((line) => line.name), [
      'Full cream milk',
      'Brown bread',
      'Bananas',
    ]);
    expect(controller.callsLeft, 97);
    expect(groceries.added, isEmpty, reason: 'nothing until it is added');
  });

  test('backing out of the picker changes nothing', () async {
    picker.next = null;
    await controller.pick(ListPhotoSource.photos);

    expect(controller.step, ListScanStep.choosing);
    expect(reader.requests, isEmpty);
  });

  test('a failed read comes back to choosing, and the same photo can be '
      'sent again', () async {
    reader.failWith = const AiFailure(AiProblem.aiUnavailable);
    await controller.pick(ListPhotoSource.camera);

    expect(controller.step, ListScanStep.choosing);
    expect(controller.failure, isA<AiFailure>());
    expect(controller.canRetry, isTrue);
    expect(controller.isAiWelcome, isFalse);

    reader.failWith = null;
    await controller.retry();
    expect(controller.step, ListScanStep.review);
    expect(reader.requests, hasLength(2));
  });

  test(
    'adds only the kept lines, as the member changed them, by name',
    () async {
      await controller.pick(ListPhotoSource.camera);
      controller
        ..toggle(1)
        ..change(2, name: '  Bananas ', quantity: '6 ');
      expect(controller.includedCount, 2);

      await addWith(const []);

      expect(groceries.added, [
        (
          name: 'Full cream milk',
          quantity: '2 l',
          addedBy: Fixtures.samMemberId,
        ),
        (name: 'Bananas', quantity: '6', addedBy: Fixtures.samMemberId),
      ]);
      expect(groceries.addedMatched, isEmpty);
      expect(controller.step, ListScanStep.done);
      expect(controller.added, 2);
    },
  );

  test('a line already waiting on the list is not added twice', () async {
    await controller.pick(ListPhotoSource.camera);

    await addWith([groceryItem('full cream milk', id: 'milk')]);

    expect(groceries.added.map((line) => line.name), [
      'Brown bread',
      'Bananas',
    ]);
    expect(controller.added, 2);
  });

  test('a write that fails keeps the review, with the reason', () async {
    await controller.pick(ListPhotoSource.camera);
    groceries.failWritesWith = const PermissionDeniedFailure();

    await addWith(const []);

    expect(controller.step, ListScanStep.review);
    expect(controller.failure, isA<PermissionDeniedFailure>());
    expect(controller.lines, hasLength(3));
  });

  test('leaving a line off and changing a name to nothing', () async {
    await controller.pick(ListPhotoSource.camera);
    controller
      ..leaveOff(0)
      ..leaveOff(0)
      ..change(1, name: '   ', quantity: null);

    expect(controller.lines[0].isIncluded, isFalse);
    expect(controller.lines[1].name, 'Brown bread');
  });

  test('hands the kept lines to the shop sheet, and finishes on what it '
      'added', () async {
    await controller.pick(ListPhotoSource.camera);
    controller.toggle(0);

    expect(
      [for (final line in controller.shopLines) (line.index, line.name)],
      [(1, 'Brown bread'), (2, 'Bananas')],
    );

    controller.shopped(null);
    expect(controller.step, ListScanStep.review);

    controller.shopped(2);
    expect(controller.step, ListScanStep.done);
    expect(controller.added, 2);
  });

  test('an empty read is the review, with nothing to add', () async {
    reader.reading = const ListReading(lines: [], callsLeft: 3);
    await controller.pick(ListPhotoSource.camera);

    expect(controller.step, ListScanStep.review);
    await controller.addToList();
    expect(controller.step, ListScanStep.review);
    expect(groceries.added, isEmpty);
  });

  test('starting over forgets the photo and the lines', () async {
    await controller.pick(ListPhotoSource.camera);
    controller.startOver();

    expect(controller.step, ListScanStep.choosing);
    expect(controller.lines, isEmpty);
    expect(controller.canRetry, isFalse);
    expect(controller.isAiWelcome, isTrue);
  });
}

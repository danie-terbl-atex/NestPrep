import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/model/grocery_list_view.dart';
import 'package:nestprep/features/groceries/state/grocery_list_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_grocery_repository.dart';
import '../../../support/household_fixtures.dart';

final _now = DateTime.utc(2026, 9, 17, 12);

/// Ticking always writes both fields together, so a fixture that sets only one
/// is a shape the app never produces.
GroceryItem item(String name, {DateTime? boughtAt, String id = 'i'}) =>
    GroceryItem(
      id: id,
      name: name,
      addedBy: Fixtures.samMemberId,
      addedAt: _now,
      boughtAt: boughtAt,
      boughtBy: boughtAt == null ? null : Fixtures.samMemberId,
    );

void main() {
  late FakeGroceryRepository repository;
  late GroceryListController controller;

  setUp(() {
    repository = FakeGroceryRepository();
    controller = GroceryListController(
      groceryRepository: repository,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      now: () => _now,
    );
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  GroceryListView dataOf() {
    final state = controller.list;
    expect(state, isA<AsyncData<GroceryListView>>());
    return (state as AsyncData<GroceryListView>).value;
  }

  test('stays loading until the read has answered', () async {
    expect(controller.list, isA<AsyncLoading<GroceryListView>>());

    repository.emitItems([item('Milk')]);
    await pumpEventQueue();
    expect(controller.list, isA<AsyncData<GroceryListView>>());
  });

  test(
    'shows what is still to buy and what was bought within the day',
    () async {
      repository.emitItems([
        ...[item('Milk', id: 'milk')],
        ...[
          item(
            'Bread',
            id: 'bread',
            boughtAt: _now.subtract(const Duration(hours: 2)),
          ),
          item(
            'Jam',
            id: 'jam',
            boughtAt: _now.subtract(const Duration(hours: 30)),
          ),
        ],
      ]);
      await pumpEventQueue();

      final view = dataOf();
      expect(view.toBuy.map((i) => i.name), ['Milk']);
      expect(view.justBought.map((i) => i.name), ['Bread']);
    },
  );

  test(
    'ranks the chips from everything bought, not just the last day',
    () async {
      repository.emitItems([
        item('Milk', id: 'a', boughtAt: _now.subtract(const Duration(days: 2))),
        item('Milk', id: 'b', boughtAt: _now.subtract(const Duration(days: 9))),
        item('Eggs', id: 'c', boughtAt: _now.subtract(const Duration(days: 3))),
      ]);
      await pumpEventQueue();

      expect(dataOf().suggestions.map((s) => s.name), ['Milk', 'Eggs']);
      expect(dataOf().justBought, isEmpty);
    },
  );

  test(
    'is empty when there is nothing to buy and nothing just bought',
    () async {
      repository.emitItems([]);
      await pumpEventQueue();
      expect(dataOf().isEmpty, isTrue);
    },
  );

  test('adds a trimmed name in the acting member"s name', () async {
    await controller.add('  Milk  ');
    expect(repository.added.single.name, 'Milk');
    expect(repository.added.single.addedBy, Fixtures.samMemberId);
  });

  test('refuses to add nothing at all', () async {
    await controller.add('   ');
    expect(repository.added, isEmpty);
  });

  test(
    'turns an empty quantity into no quantity rather than an empty string',
    () async {
      await controller.add('Milk', quantity: '   ');
      expect(repository.added.single.quantity, isNull);
    },
  );

  test(
    'ticking an unbought item buys it; ticking a bought one puts it back',
    () async {
      await controller.toggleBought(item('Milk', id: 'milk'));
      expect(repository.ticked.single.isBought, isTrue);

      await controller.toggleBought(item('Bread', id: 'bread', boughtAt: _now));
      expect(repository.ticked.last.isBought, isFalse);
    },
  );

  test('a chip adds a new unbought item with that name', () async {
    repository.emitItems([
      item('Milk', id: 'a', boughtAt: _now.subtract(const Duration(days: 1))),
    ]);
    await pumpEventQueue();

    await controller.addFromSuggestion(dataOf().suggestions.single);
    expect(repository.added.single.name, 'Milk');
  });

  test(
    'a refused write becomes copy the screen can show, and clears',
    () async {
      repository.failWritesWith = const PermissionDeniedFailure();
      await controller.toggleBought(item('Milk'));
      expect(controller.actionFailure, isA<PermissionDeniedFailure>());

      controller.dismissActionFailure();
      expect(controller.actionFailure, isNull);
    },
  );

  test('a read that fails becomes a failure state with a way back', () async {
    repository.failItemsWith(const UnavailableFailure());
    await pumpEventQueue();
    expect(controller.list, isA<AsyncFailure<GroceryListView>>());

    await controller.retry();
    expect(controller.list, isA<AsyncLoading<GroceryListView>>());
  });

  test('renaming trims, and refuses to blank a name', () async {
    await controller.rename(item('Milk', id: 'milk'), name: '  Full cream  ');
    expect(repository.renamed.single.name, 'Full cream');

    await controller.rename(item('Milk', id: 'milk'), name: '   ');
    expect(repository.renamed, hasLength(1));
  });

  test('removing passes the item on', () async {
    await controller.remove(item('Milk', id: 'milk'));
    expect(repository.removed, ['milk']);
  });
}

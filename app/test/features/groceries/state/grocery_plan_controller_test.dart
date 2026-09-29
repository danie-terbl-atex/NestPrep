import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/groceries/model/grocery_need.dart';
import 'package:nestprep/features/groceries/model/grocery_need_reason.dart';
import 'package:nestprep/features/groceries/model/grocery_plan_settings.dart';
import 'package:nestprep/features/groceries/model/grocery_plan_view.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_grocery_source.dart';
import '../../../support/grocery_plan_fixtures.dart';
import '../../../support/grocery_plan_harness.dart';

GroceryPlanView viewOf(GroceryPlanHarness harness) =>
    (harness.controller.view as AsyncData<GroceryPlanView>).value;

/// The plans controller (groceries ADR-0002, ADR-0004): it proposes, it writes
/// only what a person chose — or, kept in step, what the diff says — and it
/// never loops on a refusal.
void main() {
  late GroceryPlanHarness harness;

  setUp(() => harness = GroceryPlanHarness());
  tearDown(() => harness.close());

  test('waits for every source, the list and the settings', () async {
    harness.repository
      ..emitItems(const [])
      ..emitSettings(GroceryPlanSettings.empty);
    harness.meals.emit([GroceryPlanHarness.dinner('Bread', 2)]);
    await pumpEventQueue();
    expect(harness.controller.view, isA<AsyncLoading<GroceryPlanView>>());

    harness.lunches.emit([GroceryPlanHarness.lunch('bread', 5)]);
    await pumpEventQueue();
    final line = viewOf(harness).diff.toAdd.single;
    expect(line.name, 'Bread');
    expect(line.note, 'For 5 lunches + Tuesday dinner');
    expect(harness.meals.watchedWeeks, [planWeek]);
  });

  test('proposing writes nothing until a person applies', () async {
    harness.open(mealNeeds: [GroceryPlanHarness.dinner('Bread', 2)]);
    await pumpEventQueue();
    expect(harness.repository.planChanges, isEmpty);

    await harness.controller.apply(
      addKeys: {'bread'},
      refreshIds: const {},
      removeIds: const {},
    );
    await pumpEventQueue();
    final create = harness.repository.planChanges.single.changes.creates.single;
    expect(create.id, 'plan-$planWeek-bread');
    expect(harness.repository.items.single.isFromPlans, isTrue);
    expect(viewOf(harness).diff.added, hasLength(1));
  });

  test('kept in step, planning a meal puts it on the list and clearing it '
      'takes it off', () async {
    harness.open(
      settings: const GroceryPlanSettings(keepInStep: true),
      mealNeeds: [GroceryPlanHarness.dinner('Mince', 2)],
    );
    await pumpEventQueue();
    expect(harness.repository.items.single.name, 'Mince');

    harness.meals.emit(const []);
    await pumpEventQueue();
    expect(harness.repository.items, isEmpty);
    expect(harness.repository.planChanges, hasLength(2));
  });

  test('kept in step, it never touches a typed or a ticked item', () async {
    harness.open(settings: const GroceryPlanSettings(keepInStep: true));
    harness.repository.emitItems([
      typedItem('Bread'),
      plannedItem('Mince', boughtAt: planNow),
    ]);
    await pumpEventQueue();
    harness.meals.emit(const []);
    await pumpEventQueue();
    expect(harness.repository.planChanges, isEmpty);
  });

  test('a refused keep-in-step write is not retried for ever', () async {
    harness.repository.failWritesWith = const PermissionDeniedFailure();
    harness.open(
      settings: const GroceryPlanSettings(keepInStep: true),
      mealNeeds: [GroceryPlanHarness.dinner('Mince', 2)],
    );
    await pumpEventQueue();
    expect(harness.controller.actionFailure, isNull, reason: 'maybe a race');

    // The plans ask for exactly the same again: now it is said, and it stops.
    harness.lunches.emit(const []);
    await pumpEventQueue();
    expect(harness.controller.actionFailure, isA<PermissionDeniedFailure>());
    harness.meals.emit([GroceryPlanHarness.dinner('Mince', 2)]);
    await pumpEventQueue();
    expect(harness.repository.planChanges, isEmpty);
  });

  test('marking a staple takes it out of the proposals', () async {
    harness.open(mealNeeds: [GroceryPlanHarness.dinner('Salt', 2)]);
    await pumpEventQueue();
    await harness.controller.setStaple('salt', isStaple: true);
    await pumpEventQueue();
    expect(harness.repository.stapleWrites.single.key, 'salt');
    expect(viewOf(harness).diff.staples.single.name, 'Salt');
    expect(viewOf(harness).diff.toAdd, isEmpty);
  });

  test(
    'a labelled source plugs in and its needs merge with the plans',
    () async {
      final stock = FakeGrocerySource(
        id: 'homeCareStock',
        area: HouseholdArea.homeCare,
      );
      addTearDown(stock.close);
      final plugged = GroceryPlanHarness(extraSources: [stock]);
      addTearDown(plugged.close);

      plugged.open(mealNeeds: [GroceryPlanHarness.dinner('Dish soap', 3)]);
      stock.emit(const [
        GroceryNeed(name: 'dish soap', reason: LabelledReason('Running low')),
      ]);
      await pumpEventQueue();
      expect(
        viewOf(plugged).diff.toAdd.single.note,
        'For Wednesday dinner · Running low',
      );
    },
  );

  test('somebody blind to a plan cannot turn keeping in step on', () async {
    final blind = GroceryPlanHarness(seesEverySource: false);
    addTearDown(blind.close);
    blind.open(settings: const GroceryPlanSettings(keepInStep: true));
    await pumpEventQueue();

    expect(viewOf(blind).canKeepInStep, isFalse);
    await blind.controller.setKeepInStep(true);
    expect(blind.repository.keepInStepWrites, isEmpty);
    // Kept in step by somebody else, their phone still never writes.
    blind.meals.emit([GroceryPlanHarness.dinner('Mince', 1)]);
    await pumpEventQueue();
    expect(blind.repository.planChanges, isEmpty);
    // Turning it off is always allowed.
    await blind.controller.setKeepInStep(false);
    expect(blind.repository.keepInStepWrites, [false]);
  });

  test('a reader of the list writes nothing at all', () async {
    final reader = GroceryPlanHarness(canEdit: false);
    addTearDown(reader.close);
    reader.open(mealNeeds: [GroceryPlanHarness.dinner('Mince', 1)]);
    await pumpEventQueue();
    await reader.controller.apply(
      addKeys: {'mince'},
      refreshIds: const {},
      removeIds: const {},
    );
    await reader.controller.setStaple('mince', isStaple: true);
    expect(reader.repository.planChanges, isEmpty);
    expect(reader.repository.stapleWrites, isEmpty);
  });

  test(
    'a source that fails shows the failure, and retry reads again',
    () async {
      harness.open();
      harness.lunches.fail(const PermissionDeniedFailure());
      await pumpEventQueue();
      expect(harness.controller.view, isA<AsyncFailure<GroceryPlanView>>());

      await harness.controller.retry();
      expect(harness.controller.view, isA<AsyncLoading<GroceryPlanView>>());
      harness.open();
      await pumpEventQueue();
      expect(harness.controller.view, isA<AsyncData<GroceryPlanView>>());
    },
  );
}

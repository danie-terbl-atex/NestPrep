import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nestprep/features/groceries/data/firestore_grocery_repository.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/model/grocery_plan_changes.dart';

import 'household_fixture.dart';

/// The grocery repository against the real Firestore (ADR-0010).
///
/// `setBought` is the one worth the trip. Ticking stamps the server's time and
/// who did it; unticking clears **both**, and it clears them to a real `null`
/// rather than removing the fields — which is why `boughtAt` uses
/// `NullableTimestampConverter` and not the server-timestamp one. Get that wrong
/// and an item added arrives already bought, which the rules then refuse.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late TestHousehold home;
  late FirestoreGroceryRepository groceries;

  setUpAll(() async {
    home = await signInAndCreateAHousehold();
    groceries = FirestoreGroceryRepository(home.firestore);
  });

  setUp(() async => home = await home.freshHousehold());

  tearDownAll(() async => home.signOut());

  Future<GroceryItem> onlyItem() async =>
      (await groceries.watchItems(home.id).first).single;

  group('adding', () {
    test('an item arrives unbought, with both bought fields null', () async {
      // The failure mode this guards: using the server-timestamp converter here
      // would stamp `boughtAt` on create, so a new item would be bought already.
      await groceries.add(
        householdId: home.id,
        name: 'Milk',
        quantity: '2 l',
        addedBy: home.memberId,
      );

      final item = await onlyItem();
      expect(item.name, 'Milk');
      expect(item.quantity, '2 l');
      expect(item.boughtAt, isNull);
      expect(item.boughtBy, isNull);
      expect(item.addedAt, isNotNull, reason: 'the server stamped it');
    });

    test(
      'quantity is optional, because "a few" is what people write',
      () async {
        await groceries.add(
          householdId: home.id,
          name: 'Apples',
          addedBy: home.memberId,
        );
        expect((await onlyItem()).quantity, isNull);
      },
    );
  });

  group('ticking and unticking', () {
    test('ticking stamps the time and the member', () async {
      await groceries.add(
        householdId: home.id,
        name: 'Milk',
        addedBy: home.memberId,
      );
      final id = (await onlyItem()).id;

      await groceries.setBought(
        householdId: home.id,
        itemId: id,
        isBought: true,
        memberId: home.memberId,
      );

      final item = await onlyItem();
      expect(item.boughtAt, isNotNull);
      expect(item.boughtBy, home.memberId);
    });

    test('unticking clears both, not just the flag', () async {
      // A `boughtBy` left behind on an unbought item is a lie about who bought
      // something nobody has bought.
      await groceries.add(
        householdId: home.id,
        name: 'Milk',
        addedBy: home.memberId,
      );
      final id = (await onlyItem()).id;

      await groceries.setBought(
        householdId: home.id,
        itemId: id,
        isBought: true,
        memberId: home.memberId,
      );
      await groceries.setBought(
        householdId: home.id,
        itemId: id,
        isBought: false,
        memberId: home.memberId,
      );

      final item = await onlyItem();
      expect(item.boughtAt, isNull);
      expect(item.boughtBy, isNull);
    });

    test(
      'ticking twice is not an error and changes nothing about who',
      () async {
        await groceries.add(
          householdId: home.id,
          name: 'Milk',
          addedBy: home.memberId,
        );
        final id = (await onlyItem()).id;

        for (var i = 0; i < 2; i++) {
          await groceries.setBought(
            householdId: home.id,
            itemId: id,
            isBought: true,
            memberId: home.memberId,
          );
        }

        expect((await onlyItem()).boughtBy, home.memberId);
      },
    );
  });

  group('renaming and removing', () {
    test('renaming keeps everything else', () async {
      await groceries.add(
        householdId: home.id,
        name: 'Milk',
        quantity: '2 l',
        addedBy: home.memberId,
      );
      final before = await onlyItem();

      // The quantity is passed back deliberately. `rename` writes both fields,
      // so `quantity` is required-and-nullable: a caller says whether it means
      // keep this or clear it, and omitting it can no longer erase it by
      // accident. Here it means keep.
      await groceries.rename(
        householdId: home.id,
        itemId: before.id,
        name: 'Full cream milk',
        quantity: before.quantity,
      );

      final after = await onlyItem();
      expect(after.name, 'Full cream milk');
      expect(after.quantity, before.quantity);
      expect(after.addedBy, before.addedBy);
    });

    test('removing takes it off the list', () async {
      await groceries.add(
        householdId: home.id,
        name: 'Milk',
        addedBy: home.memberId,
      );
      final id = (await onlyItem()).id;

      await groceries.remove(householdId: home.id, itemId: id);

      expect(await groceries.watchItems(home.id).first, isEmpty);
    });
  });

  // groceries phase 2 (groceries ADR-0002): what the week's plans write, in one
  // batch, through the real converters and rules.
  group('the week’s plans', () {
    const week = '2026-W40';
    const create = (
      id: 'plan-$week-bread',
      name: 'Bread',
      quantity: '2 loaves',
      key: 'bread',
      week: week,
      note: 'For 5 lunches + Tuesday dinner',
    );

    test('a planned item arrives with its source, then refreshes', () async {
      await groceries.applyPlanChanges(
        householdId: home.id,
        changes: const GroceryPlanChanges(creates: [create]),
        memberId: home.memberId,
      );
      final planned = await onlyItem();
      expect(planned.id, create.id);
      expect(planned.isFromPlans, isTrue);
      expect(planned.sourceWeek, week);

      await groceries.applyPlanChanges(
        householdId: home.id,
        changes: const GroceryPlanChanges(
          refreshes: [
            (itemId: 'plan-$week-bread', quantity: '3 loaves', note: 'For 6'),
          ],
        ),
        memberId: home.memberId,
      );
      expect((await onlyItem()).quantity, '3 loaves');
    });

    test('editing a planned item makes it the editor’s', () async {
      await groceries.applyPlanChanges(
        householdId: home.id,
        changes: const GroceryPlanChanges(creates: [create]),
        memberId: home.memberId,
      );
      await groceries.rename(
        householdId: home.id,
        itemId: create.id,
        name: 'Brown bread',
        quantity: '1',
      );
      final adopted = await onlyItem();
      expect(adopted.isFromPlans, isFalse);
      expect(adopted.sourceNote, isNull);
    });

    test('keep-in-step and staples are one settings document', () async {
      await groceries.setKeepInStep(
        householdId: home.id,
        keepInStep: true,
        memberId: home.memberId,
      );
      await groceries.setStaple(
        householdId: home.id,
        key: 'salt',
        isStaple: true,
        memberId: home.memberId,
      );
      final settings = await groceries.watchPlanSettings(home.id).first;
      expect(settings.keepInStep, isTrue);
      expect(settings.staples, ['salt']);
      expect(settings.updatedBy, home.memberId);
    });
  });
}

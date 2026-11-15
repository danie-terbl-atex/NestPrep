import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nestprep/features/starter_content/data/firestore_starter_content_repository.dart';
import 'package:nestprep/features/starter_content/model/starter_content.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import 'household_fixture.dart';

/// The examples are written by the app as an ordinary member (household
/// ADR-0010), so the only proof that a new household really gets them is the
/// rules accepting every one of them — and letting its admin take them away.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();

  late TestHousehold household;
  late FirestoreStarterContentRepository repository;
  final clock = HouseholdClock('Africa/Johannesburg');

  setUpAll(() async {
    household = await signInAndCreateAHousehold();
    repository = FirestoreStarterContentRepository(household.firestore);
  });

  Future<QuerySnapshot<Map<String, dynamic>>> all(String collection) =>
      household.firestore
          .collection('households/${household.id}/$collection')
          .get(const GetOptions(source: Source.server));

  testWidgets('the rules take every example, and an admin clears them', (
    tester,
  ) async {
    await repository.seed(
      householdId: household.id,
      memberId: household.memberId,
      today: clock.today,
    );

    expect((await all('tasks')).docs, hasLength(StarterContent.taskIds.length));
    expect(
      (await all('events')).docs,
      hasLength(StarterContent.eventIds.length),
    );
    expect(
      (await all('groceryItems')).docs,
      hasLength(StarterContent.groceryIds.length),
    );
    expect((await all('meals')).docs.single.id, StarterContent.dinnerId);
    final plan = (await all('mealPlans')).docs.single;
    expect(plan.id, clock.today.weekStart.iso);
    expect(
      (plan.data()['slots'] as Map).values.single,
      StarterContent.dinnerId,
    );

    final own = await household.firestore
        .collection('households/${household.id}/tasks')
        .add({
          'title': 'Mine',
          'note': null,
          'dueDate': clock.today.iso,
          'recurrence': null,
          'assigneeIds': <String>[],
          'createdBy': household.memberId,
          'routineId': null,
          'createdAt': FieldValue.serverTimestamp(),
          'points': 0,
          'needsApproval': false,
        });

    await repository.clear(householdId: household.id, clock: clock);

    expect((await all('tasks')).docs.single.id, own.id);
    expect((await all('events')).docs, isEmpty);
    expect((await all('groceryItems')).docs, isEmpty);
    expect((await all('meals')).docs, isEmpty);
    expect((await all('mealPlans')).docs.single.data()['slots'], isEmpty);

    await repository.clear(householdId: household.id, clock: clock);
  });
}

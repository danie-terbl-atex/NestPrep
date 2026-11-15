import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../../../shared/time/calendar_date.dart';
import '../../../shared/time/household_clock.dart';
import '../../calendar/model/household_event.dart';
import '../../groceries/model/grocery_item.dart';
import '../../meal_planning/model/meal.dart';
import '../../meal_planning/model/week_plan.dart';
import '../../todos/model/task.dart';
import '../model/starter_content.dart';
import 'starter_content_repository.dart';

final class FirestoreStarterContentRepository
    implements StarterContentRepository {
  FirestoreStarterContentRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _household(String householdId) =>
      _firestore.collection('households').doc(householdId);

  CollectionReference<Task> _tasks(String householdId) => typedCollection(
    _household(householdId).collection('tasks'),
    fromJson: Task.fromJson,
    toJson: (task) => task.toJson(),
  );

  CollectionReference<HouseholdEvent> _events(String householdId) =>
      typedCollection(
        _household(householdId).collection('events'),
        fromJson: HouseholdEvent.fromJson,
        toJson: (event) => event.toJson(),
      );

  CollectionReference<GroceryItem> _groceries(String householdId) =>
      typedCollection(
        _household(householdId).collection('groceryItems'),
        fromJson: GroceryItem.fromJson,
        toJson: (item) => item.toJson(),
      );

  CollectionReference<Meal> _meals(String householdId) => typedCollection(
    _household(householdId).collection('meals'),
    fromJson: Meal.fromJson,
    toJson: (meal) => meal.toJson(),
  );

  CollectionReference<WeekPlan> _plans(String householdId) => typedCollection(
    _household(householdId).collection('mealPlans'),
    fromJson: WeekPlan.fromJson,
    toJson: (plan) => plan.toJson(),
  );

  @override
  Future<void> seed({
    required String householdId,
    required String memberId,
    required CalendarDate today,
  }) => _guarded(() {
    final content = StarterContent.forNewHousehold(
      today: today,
      memberId: memberId,
    );
    final batch = _firestore.batch();
    for (final task in content.tasks) {
      batch.set(_tasks(householdId).doc(task.id), task);
    }
    for (final event in content.events) {
      batch.set(_events(householdId).doc(event.id), event);
    }
    for (final item in content.groceries) {
      batch.set(_groceries(householdId).doc(item.id), item);
    }
    batch.set(_meals(householdId).doc(content.dinner.id), content.dinner);
    batch.set(
      _plans(householdId).doc(content.dinnerWeek.iso),
      WeekPlan(
        id: content.dinnerWeek.iso,
        slots: {content.dinnerSlotKey: content.dinner.id},
      ),
    );
    return batch.commit();
  });

  @override
  Future<void> clear({
    required String householdId,
    required HouseholdClock clock,
  }) => _guarded(() async {
    final batch = _firestore.batch();
    for (final id in StarterContent.taskIds) {
      batch.delete(_tasks(householdId).doc(id));
    }
    for (final id in StarterContent.eventIds) {
      batch.delete(_events(householdId).doc(id));
    }
    for (final id in StarterContent.groceryIds) {
      batch.delete(_groceries(householdId).doc(id));
    }

    // The dinner sits in the week it was planned for; a plan must never point
    // at a meal that is gone (meal-planning ADR-0001).
    final dinner = _meals(householdId).doc(StarterContent.dinnerId);
    final planned = (await dinner.get()).data();
    if (planned != null) {
      final week = clock.dateOf(planned.createdAt ?? clock.now).weekStart;
      final plan = (await _plans(householdId).doc(week.iso).get()).data();
      final keys = plan?.slotsUsing(StarterContent.dinnerId) ?? const [];
      if (keys.isNotEmpty) {
        batch.update(_plans(householdId).doc(week.iso), {
          for (final key in keys) 'slots.$key': FieldValue.delete(),
        });
      }
      batch.delete(dinner);
    }
    await batch.commit();
  });

  Future<void> _guarded(Future<void> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}

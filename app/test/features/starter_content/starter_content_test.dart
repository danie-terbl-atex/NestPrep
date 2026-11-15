import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/starter_content/model/starter_content.dart';
import 'package:nestprep/shared/recurrence/recurrence_rule.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

/// The examples are written by the app as an ordinary member, so every one of
/// them has to be a document the rules accept on a create. This reads the
/// rules' own key lists rather than a copy of them.
void main() {
  final monday = CalendarDate(2026, 11, 16);
  StarterContent madeOn(CalendarDate today) =>
      StarterContent.forNewHousehold(today: today, memberId: 'm-sam');

  Set<String> createKeys(String partial, String collection) {
    final source = File('../rules/firestore/household/$partial.rules')
        .readAsStringSync();
    final block = source.substring(source.indexOf('match /$collection/'));
    final list = RegExp(r'hasOnly\(\s*\[([^\]]*)\]').firstMatch(block)!;
    return RegExp(r"'([^']+)'")
        .allMatches(list.group(1)!)
        .map((m) => m.group(1)!)
        .toSet();
  }

  test('every example is marked by its id and nothing else', () {
    final content = madeOn(monday);
    final ids = [
      ...content.tasks.map((t) => t.id),
      ...content.events.map((e) => e.id),
      ...content.groceries.map((g) => g.id),
      content.dinner.id,
    ];
    expect(ids.every(StarterContent.isExample), isTrue);
    expect(ids.toSet(), hasLength(ids.length));
    expect(StarterContent.taskIds, content.tasks.map((t) => t.id));
    expect(StarterContent.eventIds, content.events.map((e) => e.id));
    expect(StarterContent.groceryIds, content.groceries.map((g) => g.id));
    expect(StarterContent.isExample('abc123'), isFalse);
  });

  test('each document carries only what its create rule allows', () {
    final content = madeOn(monday);
    final tasks = createKeys('todos', 'tasks');
    final events = createKeys('calendar', 'events');
    final groceries = createKeys('groceries', 'groceryItems');
    final meals = createKeys('meal_planning', 'meals');

    for (final task in content.tasks) {
      expect(tasks.containsAll(task.toJson().keys), isTrue, reason: task.id);
      expect(task.points, 0, reason: 'stars need a child to earn them');
      expect(task.createdBy, 'm-sam');
    }
    for (final event in content.events) {
      expect(events.containsAll(event.toJson().keys), isTrue, reason: event.id);
      expect(event.createdBy, 'm-sam');
    }
    for (final item in content.groceries) {
      expect(
        groceries.containsAll(item.toJson().keys),
        isTrue,
        reason: item.id,
      );
      expect(item.boughtAt, isNull);
      expect(item.boughtBy, isNull);
      expect(item.isFromPlans, isFalse);
      expect(item.addedBy, 'm-sam');
    }
    expect(meals.containsAll(content.dinner.toJson().keys), isTrue);
    expect(content.dinner.nameKey, content.dinner.nameKey.toLowerCase());
  });

  test(
    'whatever day a household is made, its first screens have something',
    () {
      for (var offset = 0; offset < 7; offset++) {
        final today = monday.addDays(offset);
        final content = madeOn(today);

        expect(
          content.tasks.where(
            (t) => t.dueDate == today && t.assigneeIds.isEmpty,
          ),
          hasLength(2),
          reason: 'two for anyone, due today, so Today and Mine both show them',
        );
        expect(content.events.first.date, today);
        expect(content.events.first.isAllDay, isTrue);

        final schoolRun = content.events[1];
        expect(schoolRun.date.weekday, lessThanOrEqualTo(5));
        expect(schoolRun.date.daysUntil(today), lessThanOrEqualTo(0));
        expect(content.events[2].date.weekday, 3);
        expect(content.events[3].date.weekday, 6);
        for (final event in content.events.skip(1)) {
          expect(today.daysUntil(event.date), inInclusiveRange(0, 7));
        }

        expect(content.dinnerWeek, today.weekStart);
        expect(content.dinnerSlotKey, '${today.weekday}_dinner');
      }
    },
  );

  test('nothing repeats for ever', () {
    final content = madeOn(monday);
    final rules = <RecurrenceRule>[
      for (final task in content.tasks) ?task.recurrence,
      for (final event in content.events) ?event.recurrence,
    ];
    expect(rules, hasLength(3));
    for (final rule in rules) {
      expect(rule.isExpandable, isTrue);
      expect(monday.daysUntil(rule.until!), lessThanOrEqualTo(28));
    }
  });

  test('titles fit a row and notes fit the field', () {
    final content = madeOn(monday);
    for (final title in [
      ...content.tasks.map((t) => t.title),
      ...content.events.map((e) => e.title),
      ...content.groceries.map((g) => g.name),
      content.dinner.name,
    ]) {
      expect(title.length, lessThanOrEqualTo(40), reason: title);
    }
    for (final event in content.events) {
      expect(event.note!.length, lessThanOrEqualTo(500));
    }
  });
}

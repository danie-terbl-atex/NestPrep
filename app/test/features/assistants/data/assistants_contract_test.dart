import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/assistants/model/assistant_scope.dart';
import 'package:nestprep/features/assistants/model/assistant_via.dart';
import 'package:nestprep/features/calendar/model/household_event.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

/// The assistants' contract between the two languages and the rules
/// (assistants ADR-0003, ADR-0005), read from each side's own source so
/// neither can drift alone — the lesson on contracts between two languages.
///
/// The provenance fields are the sharp edge. The rules' create lists name
/// every field a client may write, and their edits are `onlyChanged`, so an
/// app that wrote `createdVia` on a create, or rewrote a whole document on an
/// edit and dropped it, would be refused. The app's creates write the model's
/// `toJson` and its edits are field-by-field `update`s, so the two checks
/// here are what keep both true.
void main() {
  final scopesFile = File('../functions/src/assistants/assistant_scopes.ts');
  final principalFile = File('../functions/src/assistants/principal.ts');
  final calendarRules = File('../rules/firestore/household/calendar.rules');
  final groceryRules = File('../rules/firestore/household/groceries.rules');
  final calendarRepository = File(
    'lib/features/calendar/data/firestore_calendar_repository.dart',
  );
  final groceryRepository = File(
    'lib/features/groceries/data/firestore_grocery_repository.dart',
  );

  List<String> stringsOf(File file, String constant) {
    final source = file.readAsStringSync();
    final start = source.indexOf('$constant = [');
    final block = source.substring(start, source.indexOf('] as const', start));
    return RegExp("'([^']+)'")
        .allMatches(block)
        .map((match) => match.group(1)!)
        .toList();
  }

  /// The field names in the first `hasOnly([...])` after [anchor].
  Set<String> createFields(File rules, String anchor) {
    final source = rules.readAsStringSync();
    final from = source.indexOf('hasOnly(', source.indexOf(anchor));
    final block = source.substring(from, source.indexOf(']', from));
    return RegExp("'(\\w+)'")
        .allMatches(block)
        .map((match) => match.group(1)!)
        .toSet();
  }

  /// Every field name any `onlyChanged([...])` in [rules] lets an edit move.
  Set<String> editableFields(File rules) => {
    for (final call in RegExp(
      r'onlyChanged\(\s*\[([^\]]*)\]',
    ).allMatches(rules.readAsStringSync()))
      for (final field in RegExp("'(\\w+)'").allMatches(call.group(1)!))
        field.group(1)!,
  };

  test('every source is where this test thinks it is', () {
    for (final file in [
      scopesFile,
      principalFile,
      calendarRules,
      groceryRules,
      calendarRepository,
      groceryRepository,
    ]) {
      expect(file.existsSync(), isTrue, reason: file.path);
    }
  });

  test('the scopes are the Functions’ scopes, in their order', () {
    expect(
      AssistantScope.values.map((scope) => scope.wire).toList(),
      stringsOf(scopesFile, 'ASSISTANT_SCOPES'),
    );
  });

  test('the assistants are the Functions’ assistants', () {
    expect(
      AssistantVia.values.map((via) => via.name).toList(),
      stringsOf(principalFile, 'ASSISTANT_VIAS'),
    );
  });

  group('an event', () {
    final event = HouseholdEvent(
      id: 'e1',
      title: 'Swimming',
      note: 'Bring towels',
      date: CalendarDate.parse('2026-10-30'),
      startMinute: 900,
      endMinute: 960,
      memberIds: const ['m-kid'],
      createdBy: 'm-sam',
      createdVia: AssistantVia.claude,
    );

    test('created by the app writes only what the rules let it', () {
      expect(
        createFields(calendarRules, 'match /events/'),
        containsAll(event.toJson().keys),
      );
    });

    test('carries its assistant where no client can write or move it', () {
      expect(
        createFields(calendarRules, 'match /events/'),
        isNot(contains('createdVia')),
      );
      expect(editableFields(calendarRules), isNot(contains('createdVia')));
      expect(
        calendarRepository.readAsStringSync(),
        isNot(contains('createdVia')),
      );
    });
  });

  group('a grocery item', () {
    const item = GroceryItem(
      id: 'i1',
      name: 'Milk',
      quantity: '2 l',
      addedBy: 'm-sam',
      sourceKey: 'milk',
      sourceWeek: '2026-W44',
      sourceNote: 'For 5 lunches',
      addedVia: AssistantVia.chatgpt,
    );

    test('created by the app writes only what the rules let it', () {
      expect(
        createFields(groceryRules, 'match /groceryItems/'),
        containsAll(item.toJson().keys),
      );
      expect(item.toJson()['addedAt'], isA<FieldValue>());
    });

    test('carries its assistant where no client can write or move it', () {
      expect(
        createFields(groceryRules, 'match /groceryItems/'),
        isNot(contains('addedVia')),
      );
      expect(editableFields(groceryRules), isNot(contains('addedVia')));
      expect(groceryRepository.readAsStringSync(), isNot(contains('addedVia')));
    });
  });

  test('neither repository rewrites a document it did not just create', () {
    // Every `set(` is on a new document — `doc()` or a plan's new id — or the
    // merged grocery settings; an edit is an `update`, which keeps whatever
    // it does not name.
    for (final file in [calendarRepository, groceryRepository]) {
      final source = file.readAsStringSync();
      final sets = RegExp(r'\.set\(').allMatches(source).length;
      final fresh = RegExp(
        r'document\.set\(|batch\.set\(\s*items\.doc\(create\.id\)'
        r'|\.doc\(id\)\s*\.set\(\s*EventException|SetOptions\(merge: true\)',
      ).allMatches(source).length;
      expect(fresh, sets, reason: file.path);
    }
  });
}

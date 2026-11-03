import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/assistants/model/assistant_activity.dart';
import 'package:nestprep/features/assistants/model/assistant_connection.dart';
import 'package:nestprep/features/assistants/model/assistant_scope.dart';
import 'package:nestprep/features/assistants/model/assistant_via.dart';
import 'package:nestprep/features/calendar/model/household_event.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';

/// What a Function writes, read back the way the app reads it (assistants
/// ADR-0003, ADR-0005) — and the provenance on events and grocery items,
/// which the app reads and never writes.
void main() {
  final at = DateTime.utc(2026, 10, 29, 8);

  group('a connection', () {
    Map<String, Object?> stored({Object? via = 'claude'}) => {
      'id': 'g1',
      'uid': 'uid-sam',
      'memberId': 'm-sam',
      'clientId': 'https://claude.ai/oauth/client.json',
      'clientName': 'Claude',
      'host': 'claude.ai',
      'via': via,
      'scopes': ['lists:write', 'calendar:read', 'shop:checkout'],
      'consent': {'version': 1, 'at': Timestamp.fromDate(at)},
      'createdAt': Timestamp.fromDate(at),
      'lastUsedAt': Timestamp.fromDate(at),
      'refreshGeneration': 3,
    };

    test('reads the grant a Function wrote', () {
      final connection = AssistantConnection.fromJson(stored());
      expect(connection.id, 'g1');
      expect(connection.uid, 'uid-sam');
      expect(connection.memberId, 'm-sam');
      expect(connection.clientName, 'Claude');
      expect(connection.via, AssistantVia.claude);
      expect(connection.createdAt, at);
      expect(connection.lastUsedAt, at);
    });

    test('lists what it may do in a fixed order, and drops a scope it '
        'has never heard of', () {
      expect(AssistantConnection.fromJson(stored()).grantedScopes, [
        AssistantScope.calendarRead,
        AssistantScope.listsWrite,
      ]);
    });

    test('an assistant this build does not know reads as an assistant', () {
      expect(
        AssistantConnection.fromJson(stored(via: 'gemini')).via,
        AssistantVia.assistant,
      );
    });

    test('a grant never used yet has no last use', () {
      final connection = AssistantConnection.fromJson({
        ...stored(),
        'lastUsedAt': null,
      });
      expect(connection.lastUsedAt, isNull);
    });
  });

  test('an activity entry reads ids and the tool, never what was written', () {
    final activity = AssistantActivity.fromJson({
      'id': 'a1',
      'grantId': 'g1',
      'memberId': 'm-sam',
      'via': 'chatgpt',
      'tool': 'add_grocery_items',
      'target': {'kind': 'groceryItem', 'id': 'i1'},
      'at': Timestamp.fromDate(at),
      'expiresAt': Timestamp.fromDate(at.add(const Duration(days: 90))),
    });
    expect(activity.grantId, 'g1');
    expect(activity.via, AssistantVia.chatgpt);
    expect(activity.tool, 'add_grocery_items');
    expect(activity.at, at);
  });

  group('an event an assistant made', () {
    Map<String, Object?> stored(Object? via) => {
      'id': 'e1',
      'title': 'Swimming',
      'date': '2026-10-30',
      'startMinute': 900,
      'endMinute': 960,
      'memberIds': ['m-kid'],
      'createdBy': 'm-sam',
      'createdAt': Timestamp.fromDate(at),
      'createdVia': ?via,
    };

    test('says which assistant made it', () {
      expect(
        HouseholdEvent.fromJson(stored('claude')).createdVia,
        AssistantVia.claude,
      );
      expect(
        HouseholdEvent.fromJson(stored('chatgpt')).createdVia,
        AssistantVia.chatgpt,
      );
      expect(
        HouseholdEvent.fromJson(stored('someday-bot')).createdVia,
        AssistantVia.assistant,
      );
    });

    test('one a person made has none', () {
      expect(HouseholdEvent.fromJson(stored(null)).createdVia, isNull);
    });

    test('never writes it back: a create would be refused, and an edit '
        'keeps what is stored by not sending it', () {
      final event = HouseholdEvent.fromJson(stored('claude'));
      final written = event.toJson();
      expect(written.containsKey('createdVia'), isFalse);
      final readBack = HouseholdEvent.fromJson({...written, 'id': 'e1'});
      expect(readBack.copyWith(createdVia: event.createdVia), event);
    });
  });

  group('a grocery item an assistant added', () {
    Map<String, Object?> stored(Object? via) => {
      'id': 'i1',
      'name': 'Milk',
      'quantity': '2 l',
      'addedBy': 'm-sam',
      'addedAt': Timestamp.fromDate(at),
      'boughtAt': null,
      'boughtBy': null,
      'addedVia': ?via,
    };

    test('says which assistant added it', () {
      expect(
        GroceryItem.fromJson(stored('chatgpt')).addedVia,
        AssistantVia.chatgpt,
      );
      expect(
        GroceryItem.fromJson(stored('someday-bot')).addedVia,
        AssistantVia.assistant,
      );
      expect(GroceryItem.fromJson(stored(null)).addedVia, isNull);
    });

    test('never writes it back', () {
      final item = GroceryItem.fromJson(stored('claude'));
      final written = item.toJson();
      expect(written.containsKey('addedVia'), isFalse);
      final readBack = GroceryItem.fromJson({...written, 'id': 'i1'});
      expect(readBack.copyWith(addedVia: item.addedVia), item);
    });
  });
}

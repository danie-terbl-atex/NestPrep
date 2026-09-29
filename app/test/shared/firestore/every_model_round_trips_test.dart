import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/calendar/model/event_exception.dart';
import 'package:nestprep/features/household/model/household.dart';
import 'package:nestprep/features/household/model/member.dart';

import '../../support/model_fixtures.dart';

/// Every model's Firestore boundary, driven through the converters (`ENG-09`).
///
/// This is the layer no other test touched. The controllers are tested behind
/// fake repositories that hand back models already built, and the rules and
/// Function tests write raw maps from the other side — so `fromJson` and
/// `toJson` were reached by nothing. `household.g.dart`, the root document every
/// collection in the app nests under, was 0 of 15 lines covered.
///
/// Three things per model, and the second is the one that earns its keep:
///
/// 1. **It round-trips.** `fromJson(toJson(x) + id)` equals `x`, the way
///    `typedCollection` does it on a real read.
/// 2. **Exactly the expected keys are written.** A field leaves the document
///    through one wrong `@JsonKey(includeToJson: false)` — with no error, no
///    warning and no other failing test.
/// 3. **`id` is never in the body.** The document id is the document's name;
///    stored in the body as well it is a second copy that is wrong the moment
///    anything is copied or re-keyed.
void main() {
  final fixtures = modelFixtures();

  test('every model with a JSON boundary has a fixture', () {
    // The count is the ratchet: a twenty-eighth stored model has to be added
    // here before this passes again.
    expect(fixtures.map((fixture) => fixture.label).toSet().length, 27);
  });

  for (final fixture in fixtures) {
    group(fixture.label, () {
      test('writes exactly the fields it is meant to store', () {
        expect(
          fixture.toJson().keys.toSet(),
          fixture.keys,
          reason: fixture.note,
        );
      });

      test('never writes the document id into the document', () {
        expect(fixture.toJson().containsKey('id'), isFalse);
      });

      test('survives a round trip through the converters', () {
        expect(
          fixture.fromJson({...fixture.toJson(), 'id': fixture.id}),
          fixture.value,
        );
      });
    });
  }

  group('the converters themselves', () {
    test('a timestamp comes back as the same instant in UTC', () {
      final local = DateTime(2026, 9, 18, 8, 30);
      final read = Household.fromJson({
        'id': 'h1',
        'name': 'Snyman',
        'timeZone': 'Africa/Johannesburg',
        'members': const <String, String>{},
        'createdAt': Timestamp.fromDate(local),
      }).createdAt;

      expect(read, local.toUtc());
      expect(read!.isUtc, isTrue);
    });

    test('a raw DateTime in a document is refused, not guessed at', () {
      // Proves the fixtures go through the real converter rather than happening
      // to match: only a Timestamp reads back.
      final stored = modelFixtures()
          .firstWhere((fixture) => fixture.label == 'Household')
          .toJson();
      expect(stored['createdAt'], fixtureTimestamp);

      expect(
        () => Household.fromJson({
          'id': 'h1',
          'name': 'Snyman',
          'timeZone': 'Africa/Johannesburg',
          'members': const <String, String>{},
          'createdAt': fixtureInstant,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('a colour outside the palette reads as the fallback, never throws', () {
      // A member document written by an older build, or by hand in the console,
      // must not take the whole household screen down.
      expect(
        Member.fromJson({
          'id': 'm1',
          'displayName': 'Ada',
          'color': 'not-a-colour',
          'role': 'admin',
        }).color,
        MemberColor.violet,
      );
    });

    test('a malformed calendar date is refused rather than guessed', () {
      expect(
        () => EventException.fromJson({
          'id': 'x1',
          'eventId': 'e1',
          'occurrenceDate': 20260928,
          'skippedBy': 'm1',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

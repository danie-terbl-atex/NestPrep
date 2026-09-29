import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_grant_converter.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';

/// A grant read off Firestore the way the rules read it (household ADR-0003):
/// anything unexpected narrows what the app shows, and nothing widens it.
void main() {
  group('a stored grant, read', () {
    test('keeps what it says', () {
      final grant = AccessGrant.fromJson({'calendar': 'view', 'todos': 'own'});
      expect(grant?.levelIn(HouseholdArea.calendar), AccessLevel.view);
      expect(grant?.levelIn(HouseholdArea.todos), AccessLevel.own);
    });

    test('reads an area it does not mention as none', () {
      final grant = AccessGrant.fromJson({'calendar': 'view'});
      expect(grant?.levelIn(HouseholdArea.documents), AccessLevel.none);
    });

    test('reads a level it does not know as none', () {
      final grant = AccessGrant.fromJson({'documents': 'superuser'});
      expect(grant?.levelIn(HouseholdArea.documents), AccessLevel.none);
    });

    test('reads own where an area has no "own" as none', () {
      final grant = AccessGrant.fromJson({'groceries': 'own'});
      expect(grant?.levelIn(HouseholdArea.groceries), AccessLevel.none);
    });

    test('skips an area nobody has heard of', () {
      final grant = AccessGrant.fromJson({'garage': 'edit'});
      expect(grant, AccessGrant.uniform(AccessLevel.none));
    });

    test('is no grant at all when it is not a map', () {
      expect(AccessGrant.fromJson('edit'), isNull);
      expect(AccessGrant.fromJson(null), isNull);
    });
  });

  group('a grant, written', () {
    test('names every area, so the callable never meets a gap', () {
      final json = AccessGrant({HouseholdArea.homeCare: AccessLevel.own})
          .toJson();
      expect(json.keys, [for (final area in HouseholdArea.values) area.key]);
      expect(json['homeCare'], 'own');
      expect(json['calendar'], 'none');
    });

    test('reads back as itself', () {
      final grant = AccessGrant({
        HouseholdArea.calendar: AccessLevel.view,
        HouseholdArea.nannyHub: AccessLevel.edit,
      });
      expect(AccessGrant.fromJson(grant.toJson()), grant);
    });
  });

  test('changing one area leaves the rest alone', () {
    final grant = AccessGrant.uniform(AccessLevel.view)
        .withLevel(HouseholdArea.documents, AccessLevel.none);
    expect(grant.levelIn(HouseholdArea.documents), AccessLevel.none);
    expect(grant.levelIn(HouseholdArea.calendar), AccessLevel.view);
    expect(grant.openAreas, isNot(contains(HouseholdArea.documents)));
  });

  test('the household map skips an entry that is not a grant', () {
    final map = const GrantsByUidConverter().fromJson({
      'u1': {'calendar': 'view'},
      'u2': 'edit',
    });
    expect(map.keys, ['u1']);
  });
}

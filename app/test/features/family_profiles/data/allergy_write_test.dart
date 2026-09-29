import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/data/allergy_write.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/family_profiles/model/allergy.dart';
import 'package:nestprep/features/family_profiles/model/allergy_detail.dart';
import 'package:nestprep/features/family_profiles/model/allergy_draft.dart';
import 'package:nestprep/features/family_profiles/model/allergy_severity.dart';
import 'package:nestprep/features/family_profiles/model/other_allergy.dart';

/// What one allergy change merges into a profile. The shape matters twice: the
/// rules judge the merged document, and a merge keeps whatever it is not told
/// about — so a replaced entry that is not deleted in the same write stays.
void main() {
  String newId() => 'new-id';
  const sesame = AllergyDraft.known(
    allergen: Allergen.sesame,
    severity: AllergySeverity.severe,
  );
  final peanut = Allergy.known(
    Allergen.peanut,
    const AllergyDetail(severity: AllergySeverity.mild),
  );
  final kiwi = Allergy.other(
    'k1',
    const OtherAllergy(name: 'Kiwi', severity: AllergySeverity.mild),
  );

  Map<String, Object?> mapAt(Map<String, Object?> fields, String key) =>
      fields[key]! as Map<String, Object?>;

  test('a new fixed allergen writes every field of it, null included', () {
    final fields = allergyWriteFields(draft: sesame, newOtherId: newId);
    expect(fields.keys, ['allergies']);
    expect(mapAt(fields, 'allergies'), {
      'sesame': {'severity': 'severe', 'note': null},
    });
  });

  test('changing peanuts to sesame deletes peanuts in the same write', () {
    final allergies = mapAt(
      allergyWriteFields(draft: sesame, newOtherId: newId, replacing: peanut),
      'allergies',
    );
    expect(allergies['peanut'], isA<FieldValue>());
    expect(allergies['sesame'], {'severity': 'severe', 'note': null});
  });

  test(
    'changing the severity of peanuts writes peanuts once, not a delete',
    () {
      const worse = AllergyDraft.known(
        allergen: Allergen.peanut,
        severity: AllergySeverity.severe,
        note: 'Pen',
      );
      final allergies = mapAt(
        allergyWriteFields(draft: worse, newOtherId: newId, replacing: peanut),
        'allergies',
      );
      expect(allergies, {
        'peanut': {'severity': 'severe', 'note': 'Pen'},
      });
    },
  );

  test('a new free-text allergy gets a fresh id', () {
    const bees = AllergyDraft.other(
      otherName: 'Bee stings',
      severity: AllergySeverity.severe,
    );
    final fields = allergyWriteFields(draft: bees, newOtherId: newId);
    expect(mapAt(fields, 'otherAllergies'), {
      'new-id': {'name': 'Bee stings', 'severity': 'severe', 'note': null},
    });
  });

  test('editing a free-text allergy keeps its id', () {
    const worse = AllergyDraft.other(
      otherName: 'Kiwi fruit',
      severity: AllergySeverity.moderate,
    );
    final others = mapAt(
      allergyWriteFields(draft: worse, newOtherId: newId, replacing: kiwi),
      'otherAllergies',
    );
    expect(others.keys, ['k1']);
  });

  test(
    'turning a free-text allergy into a fixed one moves it in one write',
    () {
      final fields = allergyWriteFields(
        draft: sesame,
        newOtherId: newId,
        replacing: kiwi,
      );
      expect(mapAt(fields, 'otherAllergies')['k1'], isA<FieldValue>());
      expect(mapAt(fields, 'allergies').keys, ['sesame']);
    },
  );

  test('removing deletes from whichever map the allergy lives in', () {
    expect(
      mapAt(allergyRemovalFields(peanut), 'allergies')['peanut'],
      isA<FieldValue>(),
    );
    expect(allergyRemovalFields(peanut).keys, ['allergies']);
    expect(
      mapAt(allergyRemovalFields(kiwi), 'otherAllergies')['k1'],
      isA<FieldValue>(),
    );
  });
}

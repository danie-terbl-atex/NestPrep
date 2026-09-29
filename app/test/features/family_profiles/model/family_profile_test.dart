import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/family_profiles/model/allergy_severity.dart';
import 'package:nestprep/features/family_profiles/model/dietary_flag.dart';
import 'package:nestprep/features/family_profiles/model/family_profile.dart';
import 'package:nestprep/features/family_profiles/model/readable_json.dart';

import '../../../support/fake_family_profiles.dart';

/// Reading a stored profile forgivingly — and in one direction only: when in
/// doubt, an allergy is kept and made **more** serious, never dropped or made
/// milder (family-profiles ADR-0001, `BE-10`).
void main() {
  FamilyProfile read(Map<String, Object?> json) =>
      FamilyProfile.fromJson({'id': 'm-kid', ...json});

  group('a document with nothing in it', () {
    test('is an empty profile, not a failure', () {
      final profile = read(const {});
      expect(profile, FamilyProfile.empty('m-kid'));
      expect(profile.isChild, isFalse);
      expect(profile.allAllergies, isEmpty);
      expect(profile.hasFood, isFalse);
      expect(profile.hasSizes, isFalse);
      expect(profile.hasSchool, isFalse);
    });
  });

  group('allergies', () {
    test('are read by allergen, with severity and note', () {
      final profile = read({
        'allergies': {
          'peanut': {'severity': 'severe', 'note': 'Pen in her bag'},
        },
      });
      final peanut = profile.allergies[Allergen.peanut]!;
      expect(peanut.severity, AllergySeverity.severe);
      expect(peanut.note, 'Pen in her bag');
    });

    test('a severity this build does not know reads as severe', () {
      final profile = read({
        'allergies': {
          'milk': {'severity': 'anaphylactic'},
        },
      });
      expect(
        profile.allergies[Allergen.milk]!.severity,
        AllergySeverity.severe,
      );
    });

    test('an allergy that is not even a map is still an allergy — severe', () {
      final profile = read({
        'allergies': {'egg': 'yes'},
      });
      expect(profile.allergies[Allergen.egg]!.severity, AllergySeverity.severe);
    });

    test(
      'an allergen a newer build added is shown as free text, not dropped',
      () {
        final profile = read({
          'allergies': {
            'lupin': {'severity': 'moderate', 'note': 'New'},
          },
          'otherAllergies': {
            'k1': {'name': 'Kiwi', 'severity': 'mild'},
          },
        });
        expect(profile.allergies, isEmpty);
        final names = {
          for (final allergy in profile.allAllergies) allergy.otherName,
        };
        expect(names, {'lupin', 'Kiwi'});
        final lupin = profile.otherAllergies[unrecognisedAllergenKey('lupin')]!;
        expect(lupin.severity, AllergySeverity.moderate);
      },
    );

    test('every allergy comes back most dangerous first', () {
      final severities = [
        for (final allergy in FamilyFixtures.kid.allAllergies) allergy.severity,
      ];
      expect(severities, [
        AllergySeverity.severe,
        AllergySeverity.moderate,
        AllergySeverity.mild,
      ]);
      expect(FamilyFixtures.kid.hasSevereAllergy, isTrue);
    });
  });

  group('diet', () {
    test('keeps the codes it knows and skips the ones it does not', () {
      final profile = read({
        'diet': ['halal', 'paleo', 'nutFree'],
      });
      expect(profile.diet, {DietaryFlag.halal, DietaryFlag.nutFree});
    });

    test('writes the set in one fixed order, so a save is repeatable', () {
      final json = const FamilyProfile(
        id: 'm',
        diet: {DietaryFlag.dairyFree, DietaryFlag.nutFree},
      ).toJson();
      expect(json['diet'], ['nutFree', 'dairyFree']);
    });
  });

  group('a malformed entry costs that entry, never the whole family', () {
    test('likes that are not text are skipped', () {
      expect(
        read({
          'likes': ['Pasta', 3, null],
        }).likes,
        ['Pasta'],
      );
    });

    test('a free-text allergy with no name is kept under its key', () {
      final profile = read({
        'otherAllergies': {'k9': 'bees'},
      });
      final allergy = profile.otherAllergies['k9']!;
      expect(allergy.name, 'k9');
      expect(allergy.severity, AllergySeverity.severe);
    });

    test('a grade that is not text is no grade', () {
      expect(read({'grade': 3, 'isChild': 'yes'}).grade, isNull);
    });
  });

  test('knows when there is no more room for a free-text allergy', () {
    expect(FamilyFixtures.kid.canAddOtherAllergy, isTrue);
    final full = read({
      'otherAllergies': {
        for (var i = 0; i < FamilyProfile.otherAllergyLimit; i++)
          'o$i': {'name': 'x$i', 'severity': 'mild'},
      },
    });
    expect(full.canAddOtherAllergy, isFalse);
  });
}

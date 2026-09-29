import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/medication.dart';
import 'package:nestprep/features/family_profiles/model/member_health.dart';

import '../../../support/fake_family_profiles.dart';

/// Medicines read in the order of the day, because that is the order they are
/// given in.
void main() {
  test('times read in the order of the day, each once', () {
    const medication = Medication(name: 'x', times: [1200, 420, 1200]);
    expect(medication.timesInOrder, [420, 1200]);
    expect(medication.firstTime, 420);
    expect(medication.isWhenNeeded, isFalse);
  });

  test('no times is a when-needed medicine, and it sorts last', () {
    const inhaler = Medication(name: 'Inhaler');
    expect(inhaler.isWhenNeeded, isTrue);
    expect(inhaler.firstTime, Medication.minutesInADay);
  });

  test('a person"s medicines come in the order they are given', () {
    const health = MemberHealth(
      id: 'm',
      medications: {
        'b': Medication(name: 'Evening', times: [1140]),
        'a': Medication(name: 'When needed'),
        'c': FamilyFixtures.inhaler,
      },
    );
    expect(health.inOrderOfTheDay.map((entry) => entry.id), ['c', 'b', 'a']);
  });

  test('a malformed medicine is shown under its id, its bad times dropped', () {
    final health = MemberHealth.fromJson({
      'id': 'm',
      'medications': {
        'x1': {
          'dose': '5 ml',
          'times': [420, 'noon', 9999],
        },
        'x2': 'nonsense',
      },
    });
    expect(
      health.medications['x1'],
      const Medication(name: 'x1', dose: '5 ml', times: [420]),
    );
    expect(health.medications['x2']!.name, 'x2');
  });

  test('knows when there is no room for another medicine', () {
    expect(MemberHealth.empty('m').canAddMedication, isTrue);
    final full = MemberHealth(
      id: 'm',
      medications: {
        for (var i = 0; i < MemberHealth.medicationLimit; i++)
          '$i': const Medication(name: 'x'),
      },
    );
    expect(full.canAddMedication, isFalse);
  });
}

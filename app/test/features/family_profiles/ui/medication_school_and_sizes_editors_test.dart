import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/medication.dart';
import 'package:nestprep/shared/copy/app_copy.dart';

import '../../../support/family_editor_harness.dart';

/// The medication, school and sizes editors on a profile, driven the same
/// way as `allergy_and_food_editors_test.dart`.
void main() {
  late FamilyEditorHarness harness;

  setUp(() => harness = FamilyEditorHarness());
  tearDown(() => harness.close());

  Future<void> open(WidgetTester tester) => harness.open(tester);
  Future<void> tapText(WidgetTester tester, String text) =>
      harness.tapText(tester, text);
  Future<void> tapLabelled(WidgetTester tester, String label) =>
      harness.tapLabelled(tester, label);
  Future<void> typeInto(WidgetTester tester, String label, String text) =>
      harness.typeInto(tester, label, text);
  (String, Map<String, Object?>) onlyWrite() => harness.onlyWrite();

  group('medication', () {
    testWidgets('adds a medicine with a time from the clock', (tester) async {
      await open(tester);
      await tapLabelled(tester, FamilyCopy.addMedication);
      await typeInto(tester, FamilyCopy.medicationName, 'Antihistamine');
      await typeInto(tester, FamilyCopy.medicationDose, '5 ml');
      await tapText(tester, FamilyCopy.medicationAddTime);
      // The platform's own picker, opened at breakfast.
      await tapText(tester, 'OK');
      expect(find.text('07:00'), findsWidgets);
      await tapText(tester, FamilyCopy.save);

      final (method, arguments) = onlyWrite();
      expect(method, 'saveMedication');
      expect(arguments['medicationId'], isNull);
      expect(
        arguments['medication'],
        const Medication(name: 'Antihistamine', dose: '5 ml', times: [420]),
      );
    });

    testWidgets('edits one by its id, and can take a time away', (
      tester,
    ) async {
      await open(tester);
      await tapText(tester, 'Inhaler');
      await tapLabelled(tester, FamilyCopy.removeTime('20:00'));
      await tapText(tester, FamilyCopy.save);

      final arguments = onlyWrite().$2;
      expect(arguments['medicationId'], 'a');
      expect((arguments['medication']! as Medication).times, [420]);
    });

    testWidgets('removes one only after asking', (tester) async {
      await open(tester);
      await tapText(tester, 'Inhaler');
      await tapText(tester, FamilyCopy.remove);
      await tapText(tester, FamilyCopy.remove);
      expect(onlyWrite().$1, 'removeMedication');
      expect(onlyWrite().$2['medicationId'], 'a');
    });

    testWidgets('a nameless medicine cannot be saved', (tester) async {
      await open(tester);
      await tapLabelled(tester, FamilyCopy.addMedication);
      await tapText(tester, FamilyCopy.save);
      expect(harness.repository.writes, isEmpty);
      expect(find.text(FamilyCopy.medicationWhenNeededHint), findsOneWidget);
    });
  });

  group('school', () {
    testWidgets('chooses none, and sets a grade', (tester) async {
      await open(tester);
      await tapLabelled(
        tester,
        FamilyCopy.editSection(FamilyCopy.sectionSchool),
      );
      await tapText(tester, FamilyCopy.schoolNone);
      await typeInto(tester, FamilyCopy.grade, 'Grade 4');
      await tapText(tester, FamilyCopy.save);

      expect(onlyWrite().$1, 'saveSchooling');
      expect(onlyWrite().$2['schoolId'], isNull);
      expect(onlyWrite().$2['grade'], 'Grade 4');
    });

    testWidgets('an admin adds a school without leaving, and it is chosen', (
      tester,
    ) async {
      await open(tester);
      await tapLabelled(
        tester,
        FamilyCopy.editSection(FamilyCopy.sectionSchool),
      );
      await tapText(tester, FamilyCopy.addSchool);
      await typeInto(tester, FamilyCopy.schoolName, 'Greenfields');
      await tapText(tester, FamilyCopy.save);
      expect(find.text('Greenfields'), findsOneWidget);
      await tapText(tester, FamilyCopy.save);

      expect(harness.repository.writes.map((write) => write.$1), [
        'addSchool',
        'saveSchooling',
      ]);
      expect(harness.repository.writes.last.$2['schoolId'], 'school-1');
    });
  });

  testWidgets('sizes are saved as typed, and a blank one is none', (
    tester,
  ) async {
    await open(tester);
    await tapLabelled(tester, FamilyCopy.editSection(FamilyCopy.sectionSizes));
    await typeInto(tester, FamilyCopy.clothingSize, '9–10');
    await typeInto(tester, FamilyCopy.shoeSize, '');
    await tapText(tester, FamilyCopy.save);

    final arguments = onlyWrite().$2;
    expect(arguments['clothingSize'], '9–10');
    expect(arguments['shoeSize'], isNull);
  });
}

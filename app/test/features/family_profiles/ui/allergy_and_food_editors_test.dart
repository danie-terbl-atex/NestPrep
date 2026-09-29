import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/family_profiles/model/allergy.dart';
import 'package:nestprep/features/family_profiles/model/allergy_draft.dart';
import 'package:nestprep/features/family_profiles/model/allergy_severity.dart';
import 'package:nestprep/features/family_profiles/model/dietary_flag.dart';
import 'package:nestprep/shared/copy/app_copy.dart';

import '../../../support/family_editor_harness.dart';

/// The allergy and food editors on a profile, driven the way a parent drives
/// them: open the section, change it in its sheet, save — and assert what was
/// asked of the backend, not how the sheet is built (`FE-20`).
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

  group('allergies', () {
    testWidgets('adds one of the nine, at a severity', (tester) async {
      await open(tester);
      await tapLabelled(tester, FamilyCopy.addAllergy);

      // Peanuts is already recorded, so it is edited where it is, not offered.
      expect(find.text('Peanuts'), findsOneWidget);
      await tapText(tester, 'Sesame');
      await tapText(tester, FamilyCopy.severityName(AllergySeverity.severe));
      await typeInto(tester, FamilyCopy.allergyNote, 'Pen in the bag');
      await tapText(tester, FamilyCopy.save);

      final (method, arguments) = onlyWrite();
      expect(method, 'saveAllergy');
      expect(
        arguments['draft'],
        const AllergyDraft.known(
          allergen: Allergen.sesame,
          severity: AllergySeverity.severe,
          note: 'Pen in the bag',
        ),
      );
      expect(arguments['replacing'], isNull);
    });

    testWidgets('adds one in the household"s own words', (tester) async {
      await open(tester);
      await tapLabelled(tester, FamilyCopy.addAllergy);
      await tapText(tester, FamilyCopy.allergenOther);

      await tapText(tester, FamilyCopy.save);
      expect(
        harness.repository.writes,
        isEmpty,
        reason: 'no name is not an allergy',
      );
      expect(find.text(FamilyCopy.otherAllergyName), findsOneWidget);

      await typeInto(tester, FamilyCopy.otherAllergyName, 'Bee stings');
      await tapText(tester, FamilyCopy.save);

      final draft = onlyWrite().$2['draft']! as AllergyDraft;
      expect(draft.otherName, 'Bee stings');
      expect(draft.severity, AllergySeverity.moderate, reason: 'the default');
    });

    testWidgets('edits one in place, carrying what it replaces', (
      tester,
    ) async {
      await open(tester);
      await tapText(tester, 'Peanuts');
      await tapText(tester, FamilyCopy.severityName(AllergySeverity.moderate));
      await tapText(tester, FamilyCopy.save);

      final arguments = onlyWrite().$2;
      final replacing = arguments['replacing']! as Allergy;
      expect(replacing.allergen, Allergen.peanut);
      expect(
        (arguments['draft']! as AllergyDraft).severity,
        AllergySeverity.moderate,
      );
    });

    testWidgets('removes one only after asking', (tester) async {
      await open(tester);
      await tapText(tester, 'Kiwi');
      await tapText(tester, FamilyCopy.remove);
      expect(find.text(FamilyCopy.removeAllergyConfirm), findsOneWidget);
      await tapText(tester, FamilyCopy.cancel);
      expect(harness.repository.writes, isEmpty);

      await tapText(tester, 'Kiwi');
      await tapText(tester, FamilyCopy.remove);
      await tapText(tester, FamilyCopy.remove);
      final (method, arguments) = onlyWrite();
      expect(method, 'removeAllergy');
      expect((arguments['allergy']! as Allergy).otherName, 'Kiwi');
    });
  });

  group('food', () {
    testWidgets('adds a like, drops a dislike, and changes the diet', (
      tester,
    ) async {
      await open(tester);
      await tapLabelled(tester, FamilyCopy.editSection(FamilyCopy.sectionFood));

      await typeInto(tester, FamilyCopy.likes, 'Sushi');
      await tester.tap(find.bySemanticsLabel(FamilyCopy.addChip).first);
      await tester.pumpAndSettle();
      // Typing a like the list already has adds nothing.
      await typeInto(tester, FamilyCopy.likes, 'pasta');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tapLabelled(tester, FamilyCopy.removeChip('Mushrooms'));
      await tapText(tester, FamilyCopy.dietName(DietaryFlag.vegetarian));
      await tapText(tester, FamilyCopy.save);

      final (method, arguments) = onlyWrite();
      expect(method, 'saveFood');
      expect(arguments['likes'], ['Pasta', 'Apples', 'Sushi']);
      expect(arguments['dislikes'], isEmpty);
      expect(arguments['diet'], {DietaryFlag.halal, DietaryFlag.vegetarian});
    });
  });
}

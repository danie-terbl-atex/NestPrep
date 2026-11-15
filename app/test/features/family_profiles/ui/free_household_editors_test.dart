import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/features/subscriptions/ui/paywall_page.dart';
import 'package:nestprep/shared/copy/app_copy.dart';

import '../../../support/family_editor_harness.dart';

/// A household without Premium still keeps a profile (subscriptions
/// ADR-0008): what a child likes, wears and where they go to school save as
/// they always did, each as its own fields and nothing about health, while
/// the allergy and medication sections ask for Premium and write nothing.
void main() {
  late FamilyEditorHarness harness;

  setUp(() => harness = FamilyEditorHarness(isPremium: false));
  tearDown(() => harness.close());

  const healthWrites = {
    'saveAllergy',
    'removeAllergy',
    'saveMedication',
    'removeMedication',
  };
  const healthKeys = {
    'allergies',
    'otherAllergies',
    'draft',
    'replacing',
    'allergy',
    'medication',
    'medicationId',
    'medications',
  };

  void carriesNoHealth() {
    for (final (method, arguments) in harness.repository.writes) {
      expect(healthWrites, isNot(contains(method)));
      expect(arguments.keys.toSet().intersection(healthKeys), isEmpty);
    }
  }

  testWidgets('saves a like, with the food fields and nothing else', (
    tester,
  ) async {
    await harness.open(tester);
    await harness.tapLabelled(
      tester,
      FamilyCopy.editSection(FamilyCopy.sectionFood),
    );
    await harness.typeInto(tester, FamilyCopy.likes, 'Sushi');
    await tester.tap(find.bySemanticsLabel(FamilyCopy.addChip).first);
    await tester.pumpAndSettle();
    await harness.tapText(tester, FamilyCopy.save);

    final (method, arguments) = harness.onlyWrite();
    expect(method, 'saveFood');
    expect(arguments['likes'], ['Pasta', 'Apples', 'Sushi']);
    expect(arguments.keys, {'memberId', 'likes', 'dislikes', 'diet'});
    carriesNoHealth();
    expect(find.byType(PaywallPage), findsNothing);
  });

  testWidgets('saves a size, with the size fields and nothing else', (
    tester,
  ) async {
    await harness.open(tester);
    await harness.tapLabelled(
      tester,
      FamilyCopy.editSection(FamilyCopy.sectionSizes),
    );
    await harness.typeInto(tester, FamilyCopy.clothingSize, '9–10');
    await harness.tapText(tester, FamilyCopy.save);

    final (method, arguments) = harness.onlyWrite();
    expect(method, 'saveSizes');
    expect(arguments['clothingSize'], '9–10');
    expect(arguments.keys, {'memberId', 'clothingSize', 'shoeSize'});
    carriesNoHealth();
    expect(find.byType(PaywallPage), findsNothing);
  });

  testWidgets('saves the school, with the school fields and nothing else', (
    tester,
  ) async {
    await harness.open(tester);
    await harness.tapLabelled(
      tester,
      FamilyCopy.editSection(FamilyCopy.sectionSchool),
    );
    await harness.tapText(tester, FamilyCopy.schoolNone);
    await harness.typeInto(tester, FamilyCopy.grade, 'Grade 4');
    await harness.tapText(tester, FamilyCopy.save);

    final (method, arguments) = harness.onlyWrite();
    expect(method, 'saveSchooling');
    expect(arguments['grade'], 'Grade 4');
    expect(arguments.keys, {'memberId', 'schoolId', 'grade'});
    carriesNoHealth();
    expect(find.byType(PaywallPage), findsNothing);
  });

  for (final (section, action, field) in [
    ('allergy', FamilyCopy.addAllergy, FamilyCopy.allergenLabel),
    ('medication', FamilyCopy.addMedication, FamilyCopy.medicationName),
  ]) {
    testWidgets('the locked $section section opens no editor and writes '
        'nothing', (tester) async {
      await harness.open(tester);
      await harness.tapLabelled(tester, FamilyCopy.lockedAction(action));

      expect(find.byType(PaywallPage), findsOneWidget);
      expect(
        harness.subscriptions.paywallOpens.opened.single.trigger,
        PremiumFeature.healthProfile,
      );
      expect(find.text(field), findsNothing);
      expect(harness.repository.writes, isEmpty);
    });
  }

  testWidgets('what was recorded before is not offered for editing', (
    tester,
  ) async {
    await harness.open(tester);

    expect(find.text('Peanuts'), findsNothing);
    expect(find.text('Inhaler'), findsNothing);
    expect(harness.repository.writes, isEmpty);
  });
}

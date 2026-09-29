import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/family_profiles/model/member_health.dart';
import 'package:nestprep/features/family_profiles/state/family_controller.dart';
import 'package:nestprep/features/family_profiles/state/member_health_controller.dart';
import 'package:nestprep/features/family_profiles/ui/family_member_screen.dart';
import 'package:provider/provider.dart';

import 'fake_family_profiles.dart';
import 'household_fixtures.dart';
import 'pump_screen.dart';

/// A child's profile open in front of an admin, with the fakes behind it —
/// what every editor test starts from, so the two editor files share one
/// way of opening a sheet, typing and tapping rather than two (`ENG-01`).
final class FamilyEditorHarness {
  FamilyEditorHarness() {
    family = FamilyController(
      familyProfileRepository: repository,
      childProfileDirectory: repository,
      householdId: Fixtures.householdId,
      household: Fixtures.view(),
    );
    health = MemberHealthController(
      familyProfileRepository: repository,
      householdId: Fixtures.householdId,
      memberId: Fixtures.kidMemberId,
      isVisible: true,
    );
  }

  final repository = FakeFamilyProfileRepository();
  late final FamilyController family;
  late final MemberHealthController health;

  Future<void> close() async {
    family.dispose();
    health.dispose();
    await repository.close();
  }

  /// A tall phone: a tap below a sheet's fold lands somewhere else (the vault
  /// lesson), and these tests are about the sheets, not about scrolling them.
  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420 * 3, 2000 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpScreen(
      tester,
      const FamilyMemberScreen(memberId: Fixtures.kidMemberId),
      providers: [
        ChangeNotifierProvider<FamilyController>.value(value: family),
        ChangeNotifierProvider<MemberHealthController>.value(value: health),
      ],
    );
    repository.emitProfiles([FamilyFixtures.kid]);
    repository.emitSchools([FamilyFixtures.oakwood]);
    repository.emitHealth(
      const MemberHealth(
        id: Fixtures.kidMemberId,
        medications: {'a': FamilyFixtures.inhaler},
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  Future<void> tapLabelled(WidgetTester tester, String label) async {
    await tester.tap(find.bySemanticsLabel(label).last);
    await tester.pumpAndSettle();
  }

  /// Types into the field labelled [label] — found by its own label, so a
  /// sheet with several fields types into the right one.
  Future<void> typeInto(WidgetTester tester, String label, String text) async {
    final field = find.descendant(
      of: find.ancestor(
        of: find.text(label),
        matching: find.byType(NestTextField),
      ),
      matching: find.byType(EditableText),
    );
    await tester.enterText(field.first, text);
    await tester.pump();
  }

  (String, Map<String, Object?>) onlyWrite() => repository.writes.single;
}

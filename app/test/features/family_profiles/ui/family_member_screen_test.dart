import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/allergy_severity.dart';
import 'package:nestprep/features/family_profiles/model/family_access.dart';
import 'package:nestprep/features/family_profiles/model/food_rules.dart';
import 'package:nestprep/features/family_profiles/model/member_health.dart';
import 'package:nestprep/features/family_profiles/state/family_controller.dart';
import 'package:nestprep/features/family_profiles/state/member_health_controller.dart';
import 'package:nestprep/features/family_profiles/ui/family_member_screen.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_family_profiles.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// One person's profile, read by an admin and by a helper — the two viewers the
/// rules treat differently (family-profiles ADR-0001).
void main() {
  late FakeFamilyProfileRepository repository;
  late FamilyController family;
  late MemberHealthController health;

  void build(HouseholdView view, {String memberId = Fixtures.kidMemberId}) {
    family = FamilyController(
      familyProfileRepository: repository,
      householdId: Fixtures.householdId,
      household: view,
    );
    health = MemberHealthController(
      familyProfileRepository: repository,
      householdId: Fixtures.householdId,
      memberId: memberId,
      isVisible: FamilyAccess.of(view).canSeeHealth(memberId),
    );
  }

  setUp(() {
    repository = FakeFamilyProfileRepository();
    build(Fixtures.view());
  });

  tearDown(() async {
    family.dispose();
    health.dispose();
    await repository.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    HouseholdView? view,
    String memberId = Fixtures.kidMemberId,
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) => pumpScreen(
    tester,
    FamilyMemberScreen(memberId: memberId),
    providers: [
      ChangeNotifierProvider<FamilyController>.value(value: family),
      ChangeNotifierProvider<MemberHealthController>.value(value: health),
    ],
    view: view,
    brightness: brightness,
    textScale: scale,
  );

  Future<void> loaded(WidgetTester tester) async {
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

  /// A tall phone, so a sheet's save button is on screen without scrolling —
  /// a tap below a sheet's fold lands somewhere else (the vault lesson).
  void tallPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(420 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<void> tapLabelled(WidgetTester tester, String label) async {
    final target = find.bySemanticsLabel(label);
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  group('what an admin sees', () {
    testWidgets('a severe allergy first, named, and the school"s rule', (
      tester,
    ) async {
      tallPhone(tester);
      await pump(tester);
      await loaded(tester);

      expect(find.text(FamilyCopy.severeWarning(['Peanuts'])), findsOneWidget);
      // The peanut allergy and the school both rule nuts out, and both are
      // named, because they ask different things of whoever packs the lunch.
      expect(
        find.text(
          FamilyCopy.nutFreeBecause([
            NutFreeReason.allergy,
            NutFreeReason.school,
          ]),
        ),
        findsOneWidget,
      );
      expect(find.text('Adrenaline pen in her bag'), findsOneWidget);
      expect(
        find.text(FamilyCopy.severityName(AllergySeverity.severe)),
        findsOneWidget,
      );
    });

    testWidgets('every section, filled', (tester) async {
      tallPhone(tester);
      await pump(tester);
      await loaded(tester);

      expect(find.text('Pasta'), findsOneWidget);
      expect(find.text('Mushrooms'), findsOneWidget);
      expect(find.text('Halal'), findsOneWidget);
      expect(find.text('Inhaler'), findsOneWidget);
      expect(find.text('07:00'), findsOneWidget);
      expect(find.text('20:00'), findsOneWidget);
      expect(find.text('Oakwood Primary · Grade 3'), findsOneWidget);
      expect(find.text(FamilyCopy.schoolNutFree), findsOneWidget);
      expect(find.text('UK 13'), findsOneWidget);
      await tester.scrollUntilVisible(find.text(FamilyCopy.privacyNote), 300);
      expect(find.text(FamilyCopy.privacyNote), findsOneWidget);
    });

    testWidgets('an empty profile says so in each section, with its way in', (
      tester,
    ) async {
      tallPhone(tester);
      family.dispose();
      health.dispose();
      build(Fixtures.view(), memberId: Fixtures.samMemberId);
      await pump(tester, memberId: Fixtures.samMemberId);
      repository.emitProfiles(const []);
      repository.emitSchools(const []);
      repository.emitHealth(MemberHealth.empty(Fixtures.samMemberId));
      await tester.pumpAndSettle();

      expect(find.text(FamilyCopy.noAllergies), findsOneWidget);
      expect(find.text(FamilyCopy.noFood), findsOneWidget);
      expect(find.text(FamilyCopy.noMedication), findsOneWidget);
      expect(find.text(FamilyCopy.noSchool), findsOneWidget);
      expect(find.text(FamilyCopy.noSizes), findsOneWidget);
      expect(find.bySemanticsLabel(FamilyCopy.addAllergy), findsOneWidget);
      expect(find.bySemanticsLabel(FamilyCopy.addMedication), findsOneWidget);
    });

    testWidgets('medication that fails to load does not take the profile '
        'with it', (tester) async {
      tallPhone(tester);
      await pump(tester);
      repository.emitProfiles([FamilyFixtures.kid]);
      repository.emitSchools([FamilyFixtures.oakwood]);
      repository.failHealthWith(const UnavailableFailure());
      await tester.pumpAndSettle();

      expect(find.text('Pasta'), findsOneWidget);
      expect(
        find.text(AppCopy.failure(const UnavailableFailure())),
        findsOneWidget,
      );
      expect(find.text(AppCopy.retry), findsOneWidget);
    });

    testWidgets('a person removed while open is said to be gone', (
      tester,
    ) async {
      await pump(tester, memberId: 'm-gone');
      await loaded(tester);
      expect(find.text(FamilyCopy.memberGoneTitle), findsOneWidget);
    });
  });

  group('what a helper sees', () {
    // A helper a parent let see the family's profiles, and not their
    // medicine (household ADR-0003, family-profiles ADR-0002).
    final helper = Fixtures.helperView(
      AccessGrant.uniform(AccessLevel.none)
          .withLevel(HouseholdArea.familyProfiles, AccessLevel.view),
    );

    setUp(() {
      family.dispose();
      health.dispose();
      repository.healthWatched.clear();
      build(helper);
    });

    testWidgets('the allergies — whoever feeds a child must know', (
      tester,
    ) async {
      tallPhone(tester);
      await pump(tester, view: helper);
      await loaded(tester);
      expect(find.text(FamilyCopy.severeWarning(['Peanuts'])), findsOneWidget);
    });

    testWidgets('but not the medication, and never asks for it', (
      tester,
    ) async {
      tallPhone(tester);
      await pump(tester, view: helper);
      await loaded(tester);
      expect(find.text(FamilyCopy.medicationHiddenTitle), findsOneWidget);
      expect(find.text('Inhaler'), findsNothing);
      expect(repository.healthWatched, isEmpty);
    });

    testWidgets('and has no way to change a child"s profile', (tester) async {
      tallPhone(tester);
      await pump(tester, view: helper);
      await loaded(tester);
      for (final label in [
        FamilyCopy.addAllergy,
        FamilyCopy.addMedication,
        FamilyCopy.editSection(FamilyCopy.sectionFood),
        FamilyCopy.editSection(FamilyCopy.sectionSchool),
        FamilyCopy.editSection(FamilyCopy.sectionSizes),
        FamilyCopy.markAsChild,
      ]) {
        expect(find.bySemanticsLabel(label), findsNothing, reason: label);
      }
    });
  });

  group('editing', () {
    testWidgets('marking and unmarking a child is one tap', (tester) async {
      tallPhone(tester);
      await pump(tester);
      await loaded(tester);
      await tapLabelled(tester, FamilyCopy.markAsChild);
      expect(repository.writes.single.$1, 'setIsChild');
      expect(repository.writes.single.$2['isChild'], isFalse);
    });

    testWidgets('a refused edit is said in words, and can be dismissed', (
      tester,
    ) async {
      tallPhone(tester);
      await pump(tester);
      await loaded(tester);
      repository.failWritesWith = const PermissionDeniedFailure();
      await tapLabelled(tester, FamilyCopy.markAsChild);
      expect(
        find.text(AppCopy.failure(const PermissionDeniedFailure())),
        findsOneWidget,
      );
      await tester.tap(find.text(AppCopy.back));
      await tester.pumpAndSettle();
      expect(
        find.text(AppCopy.failure(const PermissionDeniedFailure())),
        findsNothing,
      );
    });
  });

  testWidgets('renders in dark and at 200% text without overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, brightness: Brightness.dark, scale: 2);
    await loaded(tester);
    expect(tester.takeException(), isNull);

    // Scroll the whole profile through, so every section is laid out.
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/household/model/access_defaults.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/household/state/member_access_controller.dart';
import 'package:nestprep/features/household/ui/member_access_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_household.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// The per-helper access editor (household ADR-0003): what Thandi can see,
/// chosen area by area, saved once, and said in words at every step.
void main() {
  late FakeHouseholdDirectory directory;
  late MemberAccessController controller;

  /// Thandi, claimed, holding the helper defaults the household records.
  HouseholdView household({String viewer = Fixtures.samUid}) => HouseholdView(
    household: Fixtures.household().copyWith(
      access: {Fixtures.thandiUid: AccessDefaults.helper},
    ),
    members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
    viewerUid: viewer,
  );

  setUp(() {
    directory = FakeHouseholdDirectory();
    controller = MemberAccessController(
      householdDirectory: directory,
      householdId: Fixtures.householdId,
      memberId: Fixtures.thandiMemberId,
      startingFrom: AccessDefaults.helper,
    );
  });

  tearDown(() => controller.dispose());

  Future<void> pump(
    WidgetTester tester, {
    String memberId = Fixtures.thandiMemberId,
    HouseholdView? view,
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    await pumpScreen(
      tester,
      MemberAccessScreen(memberId: memberId),
      providers: [
        ChangeNotifierProvider<MemberAccessController>.value(value: controller),
      ],
      view: view ?? household(),
      brightness: brightness,
      textScale: scale,
    );
    await tester.pumpAndSettle();
  }

  NestButton saveButton(WidgetTester tester) =>
      tester.widget<NestButton>(find.byType(NestButton).last);

  testWidgets('names the person and every area, with what they can do now', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text(Fixtures.thandi.displayName), findsOneWidget);
    expect(
      find.text(AccessCopy.areaName(HouseholdArea.calendar)),
      findsOneWidget,
    );
    expect(
      find.text(AccessCopy.levelMeaning(AccessLevel.view, 'Thandi Helper')),
      findsWidgets,
      reason: 'the choice is spelled out, not left to one word on a chip',
    );
  });

  testWidgets('nothing changed is not offered as a save', (tester) async {
    await pump(tester);
    expect(saveButton(tester).onPressed, isNull);
  });

  testWidgets('opening the documents and saving sends the whole grant', (
    tester,
  ) async {
    await pump(tester);

    final documents = find.ancestor(
      of: find.text(AccessCopy.areaName(HouseholdArea.documents)),
      matching: find.byType(NestCard),
    );
    await tester.scrollUntilVisible(documents, 200);
    await tester.tap(
      find.descendant(
        of: documents,
        matching: find.text(AccessCopy.levelName(AccessLevel.view)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(NestButton).last);
    await tester.pumpAndSettle();

    final saved = directory.accessSet.single;
    expect(saved.memberId, Fixtures.thandiMemberId);
    expect(saved.access.levelIn(HouseholdArea.documents), AccessLevel.view);
    expect(saved.access.levelIn(HouseholdArea.homeCare), AccessLevel.own);
    expect(find.text(AccessCopy.accessSaved), findsOneWidget);
  });

  testWidgets('"Nothing" hides every area in one tap', (tester) async {
    await pump(tester);

    await tester.tap(find.text(AccessCopy.accessPresetNothing));
    await tester.pumpAndSettle();

    expect(controller.draft, AccessGrant.uniform(AccessLevel.none));
    expect(saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('a medical grant carries a warning to think twice', (
    tester,
  ) async {
    await pump(tester);
    controller.setLevel(HouseholdArea.medical, AccessLevel.view);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(AccessCopy.accessMedicalCaution),
      200,
    );
    expect(find.text(AccessCopy.accessMedicalCaution), findsOneWidget);
  });

  testWidgets('a refused save is a sentence the person can dismiss', (
    tester,
  ) async {
    directory.failWith = const HouseholdFailure(HouseholdProblem.notAnAdmin);
    await pump(tester);

    await tester.tap(find.text(AccessCopy.accessPresetNothing));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(NestButton).last);
    await tester.pumpAndSettle();

    expect(
      find.text(AppCopy.householdProblem(HouseholdProblem.notAnAdmin)),
      findsOneWidget,
    );
  });

  testWidgets('a parent has nothing to choose, and is told why', (
    tester,
  ) async {
    await pump(tester, memberId: Fixtures.samMemberId);
    expect(find.text(AccessCopy.accessFamilyTitle), findsOneWidget);
    expect(find.byType(NestButton), findsNothing);
  });

  testWidgets('somebody no longer in the household is said so', (tester) async {
    await pump(tester, memberId: 'm-gone');
    expect(find.text(AccessCopy.accessNotFoundTitle), findsOneWidget);
  });

  testWidgets('a helper who opens it is told only an admin can', (
    tester,
  ) async {
    await pump(tester, view: household(viewer: Fixtures.thandiUid));
    expect(
      find.text(AppCopy.householdProblem(HouseholdProblem.notAnAdmin)),
      findsOneWidget,
    );
    expect(directory.accessSet, isEmpty);
  });

  testWidgets('it holds at phone width in dark at 200% text', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, brightness: Brightness.dark, scale: 2);
    await tester.scrollUntilVisible(
      find.text(AccessCopy.areaName(HouseholdArea.nannyHub)),
      300,
    );
    expect(tester.takeException(), isNull);
  });

  test(
    'a household with no grant for a claimed helper reads as everything',
    () {
      final view = HouseholdView(
        household: const Household(
          id: 'h1',
          name: 'x',
          timeZone: 'Africa/Johannesburg',
          members: {Fixtures.thandiUid: 'helper'},
        ),
        members: [Fixtures.thandi],
        viewerUid: Fixtures.samUid,
      );
      expect(view.isAwaitingAccessChoice(Fixtures.thandi), isTrue);
    },
  );
}

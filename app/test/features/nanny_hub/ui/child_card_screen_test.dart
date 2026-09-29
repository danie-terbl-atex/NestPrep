import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/nanny_hub_route.dart';
import 'package:nestprep/features/family_profiles/model/member_health.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/nanny_hub/model/care_routine.dart';
import 'package:nestprep/shared/copy/app_copy.dart';

import '../../../support/fake_family_profiles.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/nanny_fixtures.dart';
import '../../../support/pump_nanny_hub.dart';

void main() {
  late NannyFakes fakes;

  setUp(() => fakes = NannyFakes());
  tearDown(() => fakes.close());

  final cardPath = NannyHubRoute.childPathFor(
    Fixtures.householdId,
    Fixtures.kidMemberId,
  );

  Future<void> open(
    WidgetTester tester, {
    HouseholdView? view,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    await pumpNannyHub(
      tester,
      fakes,
      location: cardPath,
      view: view ?? NannyFixtures.carerView(),
      brightness: brightness,
      textScale: textScale,
    );
    fakes.answerAFullHub();
    await tester.pump();
    fakes.family.emitHealth(
      const MemberHealth(
        id: Fixtures.kidMemberId,
        medications: {'m1': FamilyFixtures.inhaler},
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('allergies come first, then medication, then the routine', (
    tester,
  ) async {
    await open(tester);
    final allergies = tester.getTopLeft(find.text(NannyCopy.allergies)).dy;
    final medication = tester.getTopLeft(find.text(NannyCopy.medication)).dy;
    expect(allergies, lessThan(medication));
    expect(find.text('Peanuts'), findsOneWidget);
    expect(find.text('Severe · Adrenaline pen in her bag'), findsOneWidget);
    await tester.scrollUntilVisible(find.text(NannyCopy.routine), 200);
    expect(find.text('Inhaler'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Inhaler')).dy,
      lessThan(tester.getTopLeft(find.text(NannyCopy.routine)).dy),
    );
  });

  testWidgets('the routine reads in the order of the day, untimed last', (
    tester,
  ) async {
    await open(tester);
    await tester.scrollUntilVisible(find.text('Story before sleep'), 200);
    final snack = tester.getTopLeft(find.text('Snack')).dy;
    final bath = tester.getTopLeft(find.text('Bath')).dy;
    final story = tester.getTopLeft(find.text('Story before sleep')).dy;
    expect(snack, lessThan(bath));
    expect(bath, lessThan(story));
    expect(find.text('15:00'), findsOneWidget);
    expect(find.text(NannyCopy.anyTime), findsOneWidget);
  });

  testWidgets('likes come from the family profile, and comfort from the card', (
    tester,
  ) async {
    await open(tester);
    await tester.scrollUntilVisible(find.text('Blue bunny'), 200);
    expect(find.text('Pasta'), findsOneWidget);
    expect(find.text('Mushrooms'), findsOneWidget);
    expect(find.text('Blue bunny'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Scared of the dark.'), 200);
    expect(find.text('Two songs and the night light.'), findsOneWidget);
  });

  testWidgets('a carer the grant keeps out is told, and never asks', (
    tester,
  ) async {
    await open(tester, view: NannyFixtures.carerWithoutProfilesView());
    expect(find.text(NannyCopy.allergiesHiddenTitle), findsWidgets);
    expect(find.text(NannyCopy.medicationHiddenTitle), findsOneWidget);
    expect(find.text('Peanuts'), findsNothing);
    expect(fakes.family.profilesAskedFor, isEmpty);
    expect(fakes.family.healthWatched, isEmpty);
  });

  testWidgets('a carer at edit changes the routine, and it is saved tidied', (
    tester,
  ) async {
    // Tall enough that the sheet's save button is on screen — a tap below
    // the fold of a sheet lands somewhere else (vault lesson).
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await open(tester);
    await tester.scrollUntilVisible(find.byTooltip(NannyCopy.editRoutine), 200);
    await tester.tap(find.byTooltip(NannyCopy.editRoutine));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Bath'),
      '  Bath time  ',
    );
    await tester.tap(find.text(NannyCopy.save));
    await tester.pumpAndSettle();
    final (method, arguments) = fakes.hub.writes.single;
    expect(method, 'saveRoutines');
    expect(
      (arguments['routines']! as List<CareRoutine>).map((it) => it.label),
      ['Snack', 'Bath time', 'Story before sleep'],
    );
  });

  testWidgets('a carer at view is offered no way to change anything', (
    tester,
  ) async {
    await open(tester, view: NannyFixtures.lookOnlyCarerView());
    await tester.scrollUntilVisible(find.text(NannyCopy.settling), 200);
    expect(find.byTooltip(NannyCopy.editRoutine), findsNothing);
    expect(find.byTooltip(NannyCopy.editComfort), findsNothing);
    expect(find.text(NannyCopy.addPhoto), findsNothing);
  });

  testWidgets('a child removed while the card is open is said, not blank', (
    tester,
  ) async {
    await pumpNannyHub(
      tester,
      fakes,
      location: NannyHubRoute.childPathFor(Fixtures.householdId, 'm-gone'),
    );
    fakes.answerAFullHub();
    await tester.pumpAndSettle();
    expect(find.text(NannyCopy.childGoneTitle), findsOneWidget);
  });

  testWidgets('holds at 360 wide, in dark, at 200% text', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await open(tester, brightness: Brightness.dark, textScale: 2);
    await tester.scrollUntilVisible(find.text(NannyCopy.settling), 300);
    expect(tester.takeException(), isNull);
  });
}

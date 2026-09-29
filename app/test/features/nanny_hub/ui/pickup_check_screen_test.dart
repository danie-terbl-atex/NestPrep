import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/nanny_hub_route.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/nanny_hub/model/emergency_contact.dart';
import 'package:nestprep/features/nanny_hub/model/pickup_change.dart';
import 'package:nestprep/features/nanny_hub/model/pickup_person.dart';
import 'package:nestprep/features/nanny_hub/model/school_run.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/nanny_fixtures.dart';
import '../../../support/nanny_pickup_fixtures.dart';
import '../../../support/pump_nanny_hub.dart';

/// "Who is at the door?" (nanny-hub ADR-0005): the listed adults, photo
/// first, today's expected one marked — and, always, do not release a child
/// to anybody else.
void main() {
  late NannyFakes fakes;

  setUp(() => fakes = NannyFakes());
  tearDown(() => fakes.close());

  const kid = 'Kid Parker';

  Future<void> open(
    WidgetTester tester, {
    String childId = Fixtures.kidMemberId,
    HouseholdView? view,
    List<PickupPerson> people = const [],
    List<SchoolRun> runs = const [],
    List<PickupChange> changes = const [],
    List<EmergencyContact>? contacts,
    bool answer = true,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpNannyHub(
      tester,
      fakes,
      location: NannyHubRoute.pickupCheckPathFor(Fixtures.householdId, childId),
      view: view ?? NannyFixtures.carerView(),
      brightness: brightness,
      textScale: textScale,
    );
    fakes.answerEverything(
      cards: [NannyFixtures.kidCard],
      contacts: contacts ?? [PickupFixtures.mom, NannyFixtures.gogo],
    );
    if (!answer) {
      await tester.pump();
      return;
    }
    fakes.pickups.emitAll(
      peopleList: people,
      runList: runs,
      changeList: changes,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('waits for the pickups before showing anybody', (tester) async {
    await open(tester, answer: false);
    expect(find.text(NannyPickupCopy.notOnListTitle(kid)), findsNothing);
    expect(find.text(NannyPickupCopy.nobodyAllowedTitle(kid)), findsNothing);
  });

  testWidgets('a failed read is said in words, never read as "nobody"', (
    tester,
  ) async {
    await open(tester, answer: false);
    fakes.pickups.people.addError(const UnavailableFailure());
    await tester.pumpAndSettle();
    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    expect(find.text(NannyPickupCopy.nobodyAllowedTitle(kid)), findsNothing);
  });

  testWidgets('a child nobody is listed for shows only do-not-release', (
    tester,
  ) async {
    await open(tester);
    expect(find.text(NannyPickupCopy.nobodyAllowedTitle(kid)), findsOneWidget);
    expect(find.text(NannyPickupCopy.notOnListTitle(kid)), findsNothing);
    expect(find.text(NannyPickupCopy.checkIntro(kid)), findsNothing);
  });

  testWidgets('shows everybody listed, and still says not-on-the-list', (
    tester,
  ) async {
    await open(tester, people: [PickupFixtures.gogo, PickupFixtures.thabo]);
    expect(find.text('Gogo Dlamini'), findsOneWidget);
    expect(find.text('Thabo Mokoena'), findsOneWidget);
    expect(find.text('Shows her ID; drives a white Polo'), findsOneWidget);
    // Pinned under the people, so it is on screen without scrolling.
    expect(
      find.text(NannyPickupCopy.notOnListTitle(kid)).hitTestable(),
      findsOneWidget,
    );
    expect(find.text(NannyPickupCopy.expectedToday), findsNothing);
  });

  testWidgets('somebody listed only for another child is not shown', (
    tester,
  ) async {
    await open(
      tester,
      people: [
        PickupFixtures.gogo.copyWith(childIds: ['someone-else']),
      ],
    );
    expect(find.text('Gogo Dlamini'), findsNothing);
    expect(find.text(NannyPickupCopy.nobodyAllowedTitle(kid)), findsOneWidget);
  });

  testWidgets('today’s expected collector comes first, marked with the time', (
    tester,
  ) async {
    await open(
      tester,
      people: [PickupFixtures.thabo, PickupFixtures.gogo],
      runs: [PickupFixtures.todaysRun],
    );
    expect(find.text(NannyPickupCopy.expectedAt('14:30')), findsOneWidget);
    final gogo = tester.getTopLeft(find.text('Gogo Dlamini')).dy;
    final thabo = tester.getTopLeft(find.text('Thabo Mokoena')).dy;
    expect(gogo, lessThan(thabo));
  });

  testWidgets('a household member collecting today is named on their own', (
    tester,
  ) async {
    await open(
      tester,
      people: [PickupFixtures.gogo],
      runs: [PickupFixtures.todaysRun],
      changes: [PickupFixtures.nomsaToday],
    );
    expect(find.text('Nomsa Carer'), findsOneWidget);
    expect(find.text(NannyPickupCopy.expectedAt('15:00')), findsOneWidget);
  });

  testWidgets('a parent is one tap away, the digits only', (tester) async {
    await open(tester, people: [PickupFixtures.gogo]);
    await tester.tap(find.text(NannyPickupCopy.callParent('Mom')));
    await tester.pumpAndSettle();
    expect(fakes.opener.opened, [Uri.parse('tel:+27825550100')]);
  });

  testWidgets('a listed person with a number is one tap away too', (
    tester,
  ) async {
    await open(tester, people: [PickupFixtures.gogo]);
    await tester.tap(find.text(NannyPickupCopy.callPerson('Gogo Dlamini')));
    await tester.pumpAndSettle();
    expect(fakes.opener.opened, [Uri.parse('tel:0825550199')]);
    expect(
      find.text(NannyPickupCopy.callPerson('Thabo Mokoena')),
      findsNothing,
    );
  });

  testWidgets('with no parent number, the emergency sheet is one tap away', (
    tester,
  ) async {
    await open(tester, contacts: const []);
    expect(find.text(NannyPickupCopy.noParentNumber), findsOneWidget);
    await tester.tap(find.text(NannyPickupCopy.openEmergency));
    await tester.pumpAndSettle();
    expect(find.text(NannyCopy.emergencyTitle), findsOneWidget);
  });

  testWidgets('a child who is gone is said, not blank', (tester) async {
    await open(tester, childId: 'm-gone');
    expect(find.text(NannyPickupCopy.childGoneTitle), findsOneWidget);
  });

  testWidgets('holds at 360 wide, in dark, at 200% text', (tester) async {
    await open(
      tester,
      people: [PickupFixtures.gogo, PickupFixtures.thabo],
      runs: [PickupFixtures.todaysRun],
      brightness: Brightness.dark,
      textScale: 2,
    );
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Thabo Mokoena'));
    expect(
      find.text(NannyPickupCopy.notOnListTitle(kid)).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/nanny_hub_route.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/nanny_hub/model/contact_kind.dart';
import 'package:nestprep/features/nanny_hub/model/emergency_number.dart';
import 'package:nestprep/features/nanny_hub/model/home_sheet.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/nanny_fixtures.dart';
import '../../../support/pump_nanny_hub.dart';

void main() {
  late NannyFakes fakes;

  setUp(() => fakes = NannyFakes());
  tearDown(() => fakes.close());

  Future<void> open(
    WidgetTester tester, {
    HouseholdView? view,
    bool filledIn = true,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    await pumpNannyHub(
      tester,
      fakes,
      location: NannyHubRoute.emergencyPathFor(Fixtures.householdId),
      view: view,
      brightness: brightness,
      textScale: textScale,
    );
    if (filledIn) {
      fakes.answerAFullHub();
    } else {
      fakes.answerEverything();
    }
    await tester.pumpAndSettle();
  }

  String callLabel(EmergencyNumber number) => NannyCopy.callNumber(
    NannyCopy.emergencyNumberName(number),
    number.digits,
  );

  testWidgets('the public numbers are there and dial in one tap, even when '
      'nothing is filled in', (tester) async {
    await open(tester, view: NannyFixtures.carerView(), filledIn: false);
    for (final number in EmergencyNumber.values) {
      expect(find.text(callLabel(number)), findsOneWidget);
    }
    await tester.tap(find.text(callLabel(EmergencyNumber.ambulance)));
    await tester.pumpAndSettle();
    expect(fakes.opener.opened, [Uri.parse('tel:10177')]);
    expect(find.text(NannyCopy.noAddress), findsOneWidget);
    expect(find.text(NannyCopy.noContacts), findsOneWidget);
  });

  testWidgets('each contact is one tap to call, with the digits only', (
    tester,
  ) async {
    await open(tester, view: NannyFixtures.carerView());
    await scrollTo(tester, find.text('Dr Naidoo'));
    await tester.tap(find.byTooltip(NannyCopy.call('Dr Naidoo')));
    await tester.pumpAndSettle();
    expect(fakes.opener.opened, [Uri.parse('tel:+27115550101')]);
  });

  testWidgets('shows the address to read out and the medical aid', (
    tester,
  ) async {
    await open(tester, view: NannyFixtures.carerView());
    expect(find.text('12 Acacia Lane, Parkhurst'), findsOneWidget);
    expect(find.textContaining('Discovery'), findsOneWidget);
  });

  testWidgets('a phone that will not dial says so, in words', (tester) async {
    fakes.opener.opens = false;
    await open(tester, view: NannyFixtures.carerView());
    await tester.tap(find.text(callLabel(EmergencyNumber.police)));
    await tester.pumpAndSettle();
    expect(
      find.text(
        AppCopy.failure(const NannyHubFailure(NannyHubProblem.cannotCall)),
      ),
      findsOneWidget,
    );
  });

  group('a parent', () {
    testWidgets('adds a contact, and cannot save a number with letters', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await open(tester);
      await tester.tap(find.byTooltip(NannyCopy.addContact));
      await tester.pumpAndSettle();
      await tester.enterText(fieldLabelled(NannyCopy.contactName), 'Gran');
      await tester.enterText(fieldLabelled(NannyCopy.contactPhone), 'call me');
      await tester.pumpAndSettle();
      expect(find.text(NannyCopy.phoneNotValid), findsOneWidget);
      await tester.tap(find.text(NannyCopy.save));
      await tester.pumpAndSettle();
      expect(fakes.hub.writes, isEmpty);

      await tester.enterText(
        fieldLabelled(NannyCopy.contactPhone),
        '082 555 0123',
      );
      await tester.tap(
        find.text(NannyCopy.contactKindName(ContactKind.backup)).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(NannyCopy.save));
      await tester.pumpAndSettle();
      final (method, arguments) = fakes.hub.writes.single;
      expect(method, 'addContact');
      expect(arguments['name'], 'Gran');
      expect(arguments['phone'], '082 555 0123');
      expect(arguments['kind'], ContactKind.backup);
    });

    testWidgets('changes the address and the medical aid', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await open(tester);
      await tester.tap(find.byTooltip(NannyCopy.editHomeDetails));
      await tester.pumpAndSettle();
      await tester.enterText(
        fieldLabelled(NannyCopy.medicalAidPlan),
        ' Classic ',
      );
      await tester.tap(find.text(NannyCopy.save));
      await tester.pumpAndSettle();
      final (method, arguments) = fakes.hub.writes.single;
      expect(method, 'saveSheet');
      final sheet = arguments['sheet']! as HomeSheet;
      expect(sheet.medicalAidPlan, 'Classic');
      expect(sheet.address, '12 Acacia Lane, Parkhurst');
    });

    testWidgets('removes a contact, after saying so', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await open(tester);
      await tester.tap(find.text('Gogo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(NannyCopy.delete));
      await tester.pumpAndSettle();
      await tester.tap(find.text(NannyCopy.delete).last);
      await tester.pumpAndSettle();
      final (method, arguments) = fakes.hub.writes.single;
      expect(method, 'removeContact');
      expect(arguments, {'contactId': 'c-gogo'});
    });
  });

  testWidgets('a carer at view calls, and is offered no change', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await open(tester, view: NannyFixtures.lookOnlyCarerView());
    expect(find.byTooltip(NannyCopy.addContact), findsNothing);
    expect(find.byTooltip(NannyCopy.editHomeDetails), findsNothing);
    await tester.tap(find.text('Gogo'));
    await tester.pumpAndSettle();
    expect(find.text(NannyCopy.editContact), findsNothing);
    await tester.tap(find.byTooltip(NannyCopy.call('Gogo')));
    await tester.pumpAndSettle();
    expect(fakes.opener.opened, [Uri.parse('tel:0825550199')]);
  });

  testWidgets('holds at 360 wide, in dark, at 200% text', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await open(tester, brightness: Brightness.dark, textScale: 2);
    await scrollTo(tester, find.text('Dr Naidoo'));
    expect(tester.takeException(), isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/household/state/household_gate_controller.dart';
import 'package:nestprep/features/household/ui/household_gate_screen.dart';
import 'package:nestprep/features/household/ui/join_household_form.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_household.dart';
import '../../../support/pump_screen.dart';

/// The screen somebody sees once, on the day they join: make a household, or
/// type the code somebody sent them.
///
/// It was at three covered lines out of thirty-three, with both of its forms
/// near zero — the first screen a new account meets was the least-tested one.
void main() {
  late FakeHouseholdDirectory directory;
  late HouseholdGateController controller;

  setUp(() {
    directory = FakeHouseholdDirectory();
    controller = HouseholdGateController(
      householdDirectory: directory,
      suggestedName: 'Sam Parent',
      defaultTimeZone: 'Africa/Johannesburg',
    );
  });

  tearDown(() => controller.dispose());

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) => pumpScreen(
    tester,
    const HouseholdGateScreen(),
    providers: [
      ChangeNotifierProvider<HouseholdGateController>.value(value: controller),
    ],
    brightness: brightness,
    textScale: scale,
  );

  Finder fieldLabelled(String label) => find.descendant(
    of: find.ancestor(
      of: find.text(label),
      matching: find.byType(NestTextField),
    ),
    matching: find.byType(TextField),
  );

  testWidgets('offers both ways in, and starts on creating', (tester) async {
    await pump(tester);

    expect(find.text(AppCopy.householdCreate), findsOneWidget);
    expect(find.text(AppCopy.householdJoin), findsOneWidget);
    expect(fieldLabelled(AppCopy.householdNameLabel), findsOneWidget);
  });

  testWidgets('the name Google gave us is already in the box', (tester) async {
    await pump(tester);
    expect(
      find.text('Sam Parent'),
      findsOneWidget,
      reason: 'nobody should have to type their own name on day one',
    );
  });

  testWidgets('a household needs a name before it can be created', (
    tester,
  ) async {
    await pump(tester);

    final before = tester.widget<NestButton>(
      find.widgetWithText(NestButton, AppCopy.householdCreateAction),
    );
    expect(before.onPressed, isNull);

    await tester.enterText(
      fieldLabelled(AppCopy.householdNameLabel),
      'The Parkers',
    );
    await tester.pumpAndSettle();

    final after = tester.widget<NestButton>(
      find.widgetWithText(NestButton, AppCopy.householdCreateAction),
    );
    expect(after.onPressed, isNotNull);
  });

  testWidgets('creating sends the household name and the person name', (
    tester,
  ) async {
    await pump(tester);

    await tester.enterText(
      fieldLabelled(AppCopy.householdNameLabel),
      'The Parkers',
    );
    await tester.pumpAndSettle();
    // The nest and the question sit above the form now, so the button can
    // be below the fold of the test's surface.
    final create = find.widgetWithText(
      NestButton,
      AppCopy.householdCreateAction,
    );
    await tester.ensureVisible(create);
    await tester.pumpAndSettle();
    await tester.tap(create);
    await tester.pumpAndSettle();

    final created = directory.created.single;
    expect(created.name, 'The Parkers');
    expect(created.adminDisplayName, 'Sam Parent');
  });

  group('joining with a code', () {
    Future<void> openJoin(WidgetTester tester) async {
      await tester.tap(find.text(AppCopy.householdJoin));
      await tester.pumpAndSettle();
    }

    testWidgets('a short code cannot be submitted', (tester) async {
      await pump(tester);
      await openJoin(tester);

      await tester.enterText(fieldLabelled(AppCopy.inviteCodeLabel), 'ABC');
      await tester.pumpAndSettle();

      final join = tester.widget<NestButton>(
        find.widgetWithText(NestButton, AppCopy.householdJoinAction),
      );
      expect(
        join.onPressed,
        isNull,
        reason: 'a code is exactly ${JoinHouseholdForm.codeLength} characters',
      );
    });

    testWidgets('a code typed in lower case is sent in upper', (tester) async {
      await pump(tester);
      await openJoin(tester);

      await tester.enterText(
        fieldLabelled(AppCopy.inviteCodeLabel),
        'abcd2345',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(NestButton, AppCopy.householdJoinAction),
      );
      await tester.pumpAndSettle();

      expect(directory.redeemed, [
        'ABCD2345',
      ], reason: 'nobody types a code the way it was printed');
    });

    testWidgets('a refused code says so and leaves the code to fix', (
      tester,
    ) async {
      directory.failWith = const HouseholdFailure(
        HouseholdProblem.inviteExpired,
      );
      await pump(tester);
      await openJoin(tester);

      await tester.enterText(
        fieldLabelled(AppCopy.inviteCodeLabel),
        'ABCD2345',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(NestButton, AppCopy.householdJoinAction),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NestBanner), findsOneWidget);
      expect(
        tester
            .widget<TextField>(fieldLabelled(AppCopy.inviteCodeLabel))
            .controller
            ?.text,
        'ABCD2345',
        reason: 'a refusal must not empty the box they just filled',
      );
    });
  });

  testWidgets('it holds at phone width in dark at 200% text', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, brightness: Brightness.dark, scale: 2);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

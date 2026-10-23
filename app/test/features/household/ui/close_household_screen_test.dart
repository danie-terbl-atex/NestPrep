import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/account_data/ui/account_export_screen.dart';
import 'package:nestprep/features/account_data/ui/delete_account_screen.dart';
import 'package:nestprep/features/household/state/close_household_controller.dart';
import 'package:nestprep/features/household/ui/close_household_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/accessibility_audit.dart';
import '../../../support/fake_household.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// Close household (household ADR-0007): what it says before anything
/// happens, that the button stays shut until the word is typed, that a
/// refusal is words, and dark at 200% text on a 360-wide phone (`FE-08`,
/// `FE-10`, `FE-13`, `FE-14`).
void main() {
  late FakeHouseholdDirectory directory;

  setUp(() => directory = FakeHouseholdDirectory());

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    GoRoute placeholder(String path) =>
        GoRoute(path: path, builder: (_, _) => Text('page $path'));
    await pumpRouter(
      tester,
      router: GoRouter(
        initialLocation: '/close',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Text('home')),
          GoRoute(
            path: '/close',
            builder: (_, _) => ChangeNotifierProvider(
              create: (_) => CloseHouseholdController(
                householdDirectory: directory,
                householdId: Fixtures.householdId,
              ),
              child: const CloseHouseholdScreen(),
            ),
          ),
          placeholder(AccountExportScreen.path),
          placeholder(DeleteAccountScreen.path),
        ],
      ),
      providers: const [],
      brightness: brightness,
      textScale: scale,
    );
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  NestButton closeButton(WidgetTester tester) => tester.widget<NestButton>(
    find.widgetWithText(NestButton, CloseHouseholdCopy.closeButton),
  );

  testWidgets('says what goes, and who loses access, before anything', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text(CloseHouseholdCopy.lead('The Parkers')), findsOneWidget);
    // Thandi, the helper, is the one other account in the fixture.
    expect(find.text(CloseHouseholdCopy.othersLoseAccess(1)), findsOneWidget);
    await scrollTo(tester, find.text(CloseHouseholdCopy.premiumNote));
    expect(find.text(CloseHouseholdCopy.premiumNote), findsOneWidget);
  });

  testWidgets('stays shut until CLOSE is typed, then closes once', (
    tester,
  ) async {
    await pump(tester);
    await scrollTo(tester, find.text(CloseHouseholdCopy.closeButton));
    expect(closeButton(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'close');
    await tester.pumpAndSettle();
    expect(closeButton(tester).onPressed, isNotNull);

    await tester.tap(find.text(CloseHouseholdCopy.closeButton));
    // The button spins until the session moves the screen on, so it never
    // settles; a couple of frames is the call landing.
    await tester.pump();
    await tester.pump();

    expect(directory.closed, [
      (householdId: Fixtures.householdId, confirmation: 'CLOSE'),
    ]);
    // Done, and waiting for the session to move the screen on: never twice.
    expect(find.text(CloseHouseholdCopy.closing), findsOneWidget);
  });

  testWidgets('a refusal is words, and the word can be tried again', (
    tester,
  ) async {
    directory.failWith = const HouseholdFailure(
      HouseholdProblem.otherAdultsRemain,
    );
    await pump(tester);
    await scrollTo(tester, find.text(CloseHouseholdCopy.closeButton));
    await tester.enterText(find.byType(TextField), 'CLOSE');
    await tester.pumpAndSettle();
    await tester.tap(find.text(CloseHouseholdCopy.closeButton));
    await tester.pumpAndSettle();

    expect(
      find.text(AppCopy.householdProblem(HouseholdProblem.otherAdultsRemain)),
      findsOneWidget,
    );
    expect(closeButton(tester).onPressed, isNotNull);
  });

  testWidgets('offers a copy of the data and account deletion instead', (
    tester,
  ) async {
    await pump(tester);
    await scrollTo(tester, find.text(CloseHouseholdCopy.deleteAccountButton));
    await tester.tap(find.text(CloseHouseholdCopy.deleteAccountButton));
    await tester.pumpAndSettle();
    expect(find.text('page ${DeleteAccountScreen.path}'), findsOneWidget);
  });

  testWidgets('is accessible and survives dark at 200% on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, brightness: Brightness.dark, scale: 2);
    await scrollTo(tester, find.text(CloseHouseholdCopy.closeButton));
    expect(tester.takeException(), isNull);
    await expectAccessible(tester, 'close household');
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/accounts/state/register_controller.dart';
import 'package:nestprep/features/household/state/invite_welcome_controller.dart';
import 'package:nestprep/features/household/state/pending_invite.dart';
import 'package:nestprep/features/household/ui/invite_welcome_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_auth.dart';
import '../../../support/fake_household.dart';
import '../../../support/pump_screen.dart';

/// Step one of three for an invited person with no account yet (household
/// ADR-0011).
void main() {
  late FakeHouseholdDirectory directory;
  late FakeAuthGateway auth;
  late PendingInvite pending;
  late InviteWelcomeController controller;
  late RegisterController register;

  setUp(() {
    directory = FakeHouseholdDirectory();
    auth = FakeAuthGateway();
    pending = PendingInvite(links: const Stream.empty())..offerCode('ABCD2345');
    controller = InviteWelcomeController(
      householdDirectory: directory,
      pendingInvite: pending,
    );
    register = RegisterController(authGateway: auth);
  });

  tearDown(() async {
    controller.dispose();
    register.dispose();
    pending.dispose();
    await auth.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    await pumpScreen(
      tester,
      const InviteWelcomeScreen(),
      providers: [
        ChangeNotifierProvider<InviteWelcomeController>.value(
          value: controller,
        ),
        ChangeNotifierProvider<RegisterController>.value(value: register),
      ],
      brightness: brightness,
      textScale: scale,
    );
    await controller.load();
    await tester.pumpAndSettle();
  }

  final createButton = find.widgetWithText(NestButton, AppCopy.registerSubmit);

  testWidgets('says whose family it is, and that the account comes first', (
    tester,
  ) async {
    await pump(tester);

    expect(
      find.text(AppCopy.onboardingStep(1, 3, AppCopy.stepAccount)),
      findsOneWidget,
    );
    expect(
      find.text(AccessCopy.inviteLinkTitle('The Parkers')),
      findsOneWidget,
    );
    expect(find.textContaining(AccessCopy.inviteWelcomeNext), findsOneWidget);
    expect(createButton, findsOneWidget);
  });

  testWidgets('a dead invite is said at once, with no account to make', (
    tester,
  ) async {
    directory.failWith = const HouseholdFailure(HouseholdProblem.inviteExpired);
    await pump(tester);

    expect(find.text(AccessCopy.inviteWelcomeRefusedTitle), findsOneWidget);
    expect(
      find.text(
        AppCopy.failure(const HouseholdFailure(HouseholdProblem.inviteExpired)),
      ),
      findsOneWidget,
    );
    expect(createButton, findsNothing);

    await tester.tap(find.text(AccessCopy.inviteWelcomeOtherCode));
    await tester.pumpAndSettle();
    expect(pending.code, isNull);
  });

  testWidgets('an unreadable preview keeps the way in, in general words', (
    tester,
  ) async {
    directory.failWith = const UnavailableFailure();
    await pump(tester);

    expect(find.text(AccessCopy.inviteWelcomeGeneralTitle), findsOneWidget);
    expect(createButton, findsOneWidget);
  });

  testWidgets('makes the account from the typed details', (tester) async {
    await pump(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Thandi');
    await tester.enterText(fields.at(1), 'thandi@nestprep.test');
    await tester.enterText(fields.at(2), 'nestprep-8');
    await tester.pump();
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(auth.registrations, ['thandi@nestprep.test']);
  });

  testWidgets('somebody with an account signs in instead', (tester) async {
    await pump(tester);

    await tester.tap(find.text(AccessCopy.inviteWelcomeExisting));
    await tester.pumpAndSettle();

    expect(createButton, findsNothing);
    expect(find.text(AppCopy.signInForgotPassword), findsOneWidget);
  });

  testWidgets('not now drops the invite', (tester) async {
    await pump(tester);

    final notNow = find.widgetWithText(NestButton, AccessCopy.inviteLinkNotNow);
    await tester.ensureVisible(notNow);
    await tester.tap(notNow);
    await tester.pumpAndSettle();

    expect(pending.code, isNull);
  });

  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('reads at 200% text, 360 wide, in ${brightness.name}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await pump(tester, brightness: brightness, scale: 2);

      expect(tester.takeException(), isNull);
      await tester.tap(find.text(AccessCopy.inviteWelcomeExisting));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

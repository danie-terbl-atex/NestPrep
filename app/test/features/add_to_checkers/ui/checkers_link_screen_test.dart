import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_link_status.dart';
import 'package:nestprep/features/add_to_checkers/state/checkers_link_controller.dart';
import 'package:nestprep/features/add_to_checkers/ui/checkers_link_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/checkers_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_checkers.dart';
import '../../../support/pump_screen.dart';

Future<FakeCheckersDirectory> pumpLink(
  WidgetTester tester, {
  FakeCheckersDirectory? directory,
  Brightness brightness = Brightness.light,
  double scale = 1,
}) async {
  final fake = directory ?? FakeCheckersDirectory();
  await pumpScreen(
    tester,
    const CheckersLinkScreen(),
    providers: [
      ChangeNotifierProvider(
        create: (_) => CheckersLinkController(directory: fake),
      ),
    ],
    brightness: brightness,
    textScale: scale,
  );
  await tester.pumpAndSettle();
  return fake;
}

/// Linking a member's own Checkers account: honest about who we are and how
/// long it lasts, a code only from a tap, and a way to unlink.
void main() {
  testWidgets('says NestPrep is not Checkers, and that it lasts an hour', (
    tester,
  ) async {
    final directory = await pumpLink(tester);
    expect(find.text(CheckersCopy.notAffiliated), findsOneWidget);
    expect(find.text(CheckersCopy.linkHourNote), findsOneWidget);
    expect(directory.otpRequests, isEmpty);
  });

  testWidgets('number, code, linked', (tester) async {
    final directory = await pumpLink(tester);
    await tester.enterText(find.byType(TextField), '082 123 4567');
    await tester.pump();
    await tester.tap(find.text(CheckersCopy.sendCode));
    await tester.pumpAndSettle();
    expect(directory.otpRequests.single, '082 123 4567');
    expect(
      find.text(CheckersCopy.codeSentTo('+27 82 *** 4567')),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.tap(find.text(CheckersCopy.verify));
    await tester.pumpAndSettle();
    expect(find.text(CheckersCopy.linkedTitle), findsOneWidget);
    expect(find.text(CheckersCopy.unlink), findsOneWidget);
  });

  testWidgets('a wrong code is said under the field, not as an error code', (
    tester,
  ) async {
    final directory = FakeCheckersDirectory()
      ..verifyFailure = const CheckersFailure(CheckersProblem.wrongCode);
    await pumpLink(tester, directory: directory);
    await tester.enterText(find.byType(TextField), '0821234567');
    await tester.pump();
    await tester.tap(find.text(CheckersCopy.sendCode));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0000');
    await tester.pump();
    await tester.tap(find.text(CheckersCopy.verify));
    await tester.pumpAndSettle();

    expect(
      find.text(CheckersCopy.problem(CheckersProblem.wrongCode)),
      findsOneWidget,
    );
    expect(find.text(CheckersCopy.linkedTitle), findsNothing);
  });

  testWidgets('send is off until the number could be one', (tester) async {
    final directory = await pumpLink(tester);
    await tester.enterText(find.byType(TextField), '082');
    await tester.pump();
    await tester.tap(find.text(CheckersCopy.sendCode));
    await tester.pump();
    expect(directory.otpRequests, isEmpty);
  });

  testWidgets('a linked account can be unlinked', (tester) async {
    final directory = FakeCheckersDirectory()
      ..status = CheckersLinkStatus(
        isLinked: true,
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 40)),
        mobileMasked: '+27 82 *** 4567',
      );
    await pumpLink(tester, directory: directory);
    await tester.tap(find.text(CheckersCopy.unlink));
    await tester.pumpAndSettle();
    expect(directory.unlinks, 1);
    expect(find.text(CheckersCopy.sendCode), findsOneWidget);
  });

  testWidgets('a status that cannot be read offers a retry', (tester) async {
    final directory = FakeCheckersDirectory()
      ..statusFailure = const UnavailableFailure();
    await pumpLink(tester, directory: directory);
    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    directory.statusFailure = null;
    await tester.tap(find.text(AppCopy.retry));
    await tester.pumpAndSettle();
    expect(find.text(CheckersCopy.sendCode), findsOneWidget);
  });

  testWidgets('survives dark at 200% text on a 360-wide phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpLink(tester, brightness: Brightness.dark, scale: 2);
    expect(tester.takeException(), isNull);
  });
}

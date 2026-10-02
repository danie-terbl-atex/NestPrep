import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/features/kid_accounts/model/kid_device.dart';
import 'package:nestprep/features/kid_accounts/state/kid_sign_in_controller.dart';
import 'package:nestprep/features/kid_accounts/ui/kid_sign_in_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/kid_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_kid_sign_in.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// The parent's side of kid sign-in (accounts ADR-0003): which children can
/// sign in and where, the code that lets a new device in, and the two ways to
/// end it.
void main() {
  late FakeKidSignInDirectory directory;
  late FakeKidDeviceRepository devices;
  late KidSignInController controller;

  KidDevice tablet({String id = 'kid_tablet', String label = 'Tablet'}) =>
      KidDevice(
        id: id,
        memberId: Fixtures.kidMemberId,
        label: label,
        pairedBy: Fixtures.samUid,
        pairedAt: DateTime.utc(2026, 9, 28, 9),
      );

  void build({List<Member>? members}) {
    controller = KidSignInController(
      kidSignInDirectory: directory,
      kidDeviceRepository: devices,
      householdId: Fixtures.householdId,
      members: members ?? [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
    );
  }

  setUp(() {
    directory = FakeKidSignInDirectory();
    devices = FakeKidDeviceRepository();
    build();
  });

  tearDown(() async {
    controller.dispose();
    await devices.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) => pumpScreen(
    tester,
    const KidSignInScreen(),
    providers: [
      ChangeNotifierProvider<KidSignInController>.value(value: controller),
    ],
    brightness: brightness,
    textScale: scale,
  );

  Future<void> emit(WidgetTester tester, List<KidDevice> list) async {
    devices.emit(list);
    await tester.pumpAndSettle();
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.text(KidCopy.manageAddDevice));
    await tester.pumpAndSettle();
  }

  Future<void> makeCode(WidgetTester tester, {String label = ''}) async {
    await openSheet(tester);
    if (label.isNotEmpty) {
      await tester.enterText(find.byType(TextField), label);
    }
    await tester.tap(find.text(KidCopy.pairMakeCode));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('the four states', () {
    testWidgets('holds the layout while it loads', (tester) async {
      await pump(tester);
      await tester.pump();
      expect(find.byKey(const ValueKey('loading')), findsOneWidget);
      expect(find.text(KidCopy.manageTitle), findsOneWidget);
    });

    testWidgets('a household with no child to sign in says how to add one', (
      tester,
    ) async {
      controller.dispose();
      build(members: [Fixtures.sam, Fixtures.thandi]);
      await pump(tester);
      await emit(tester, const []);

      expect(find.text(KidCopy.manageEmptyTitle), findsOneWidget);
      expect(find.text(KidCopy.manageGoToHousehold), findsOneWidget);
    });

    testWidgets('an unreadable list offers a retry', (tester) async {
      await pump(tester);
      devices.failWith(const UnavailableFailure());
      await tester.pumpAndSettle();
      expect(find.text(AppCopy.retry), findsOneWidget);
    });

    testWidgets('each child, with where they are signed in', (tester) async {
      await pump(tester);
      await emit(tester, [tablet(), tablet(id: 'kid_phone', label: '')]);

      expect(find.text(Fixtures.kid.displayName), findsOneWidget);
      expect(find.text(KidCopy.manageDeviceCount(2)), findsOneWidget);
      expect(find.text('Tablet'), findsOneWidget);
      expect(find.text(KidCopy.manageUnnamedDevice), findsOneWidget);
      expect(find.text(Fixtures.sam.displayName), findsNothing);
    });

    testWidgets('a child signed in nowhere says so', (tester) async {
      await pump(tester);
      await emit(tester, const []);
      expect(find.text(KidCopy.manageNoDevices), findsOneWidget);
      expect(find.text(KidCopy.manageSignOutEverywhere), findsNothing);
    });
  });

  group('adding a device', () {
    testWidgets('shows the code with how long it has left', (tester) async {
      await pump(tester);
      await emit(tester, const []);

      await makeCode(tester, label: 'Tablet');

      expect(directory.created.single.label, 'Tablet');
      for (final letter in ['A', 'B', 'C', '2', '3', '1']) {
        expect(find.text(letter), findsOneWidget);
      }
      expect(find.textContaining('left'), findsOneWidget);
      expect(find.text(KidCopy.pairWaiting), findsOneWidget);
    });

    testWidgets('celebrates the moment the device uses it', (tester) async {
      await pump(tester);
      await emit(tester, const []);
      await makeCode(tester);

      devices.emit([tablet()]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.text(KidCopy.pairSucceeded(Fixtures.kid.displayName)),
        findsOneWidget,
      );
      await tester.tap(find.text(KidCopy.pairDone));
      await tester.pumpAndSettle();
      expect(directory.cancelled, isEmpty, reason: 'a used code is not live');
    });

    testWidgets('closing without using it retires the code', (tester) async {
      await pump(tester);
      await emit(tester, const []);
      await makeCode(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(directory.cancelled, ['ABC231']);
    });

    testWidgets('a code that ran out offers a new one', (tester) async {
      directory.expiresAt = DateTime.now().toUtc().subtract(
        const Duration(seconds: 1),
      );
      await pump(tester);
      await emit(tester, const []);
      await makeCode(tester);

      expect(find.text(KidCopy.pairExpired), findsOneWidget);
      directory.expiresAt = null;
      await tester.tap(find.text(KidCopy.pairMakeAnother));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(directory.created, hasLength(2));
      expect(find.text(KidCopy.pairWaiting), findsOneWidget);
    });

    testWidgets('a refusal is said in the sheet', (tester) async {
      directory.failWith = const KidSignInFailure(
        KidSignInProblem.tooManyDevices,
      );
      await pump(tester);
      await emit(tester, const []);
      await makeCode(tester);

      expect(
        find.text(KidCopy.problem(KidSignInProblem.tooManyDevices)),
        findsOneWidget,
      );
    });

    testWidgets('is not offered past five devices', (tester) async {
      await pump(tester);
      await emit(tester, [for (var i = 0; i < 5; i++) tablet(id: 'kid_$i')]);

      final add = tester.widget<NestButton>(
        find.widgetWithText(NestButton, KidCopy.manageAddDevice),
      );
      expect(add.onPressed, isNull);
    });
  });

  group('ending a sign-in', () {
    testWidgets('one device, after asking', (tester) async {
      await pump(tester);
      await emit(tester, [tablet()]);

      await tester.tap(find.byIcon(LucideIcons.logOut));
      await tester.pumpAndSettle();
      expect(find.text(KidCopy.manageRevokeConfirm), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text(KidCopy.manageRevoke),
        ),
      );
      await tester.pumpAndSettle();

      expect(directory.revoked, ['kid_tablet']);
    });

    testWidgets('and taking no for an answer', (tester) async {
      await pump(tester);
      await emit(tester, [tablet()]);

      await tester.tap(find.byIcon(LucideIcons.logOut));
      await tester.pumpAndSettle();
      await tester.tap(find.text(KidCopy.manageCancel));
      await tester.pumpAndSettle();

      expect(directory.revoked, isEmpty);
    });

    testWidgets('every device at once, after asking', (tester) async {
      await pump(tester);
      await emit(tester, [tablet()]);

      await tester.tap(find.text(KidCopy.manageSignOutEverywhere));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text(KidCopy.manageSignOutEverywhere),
        ),
      );
      await tester.pumpAndSettle();

      expect(directory.reset, [Fixtures.kidMemberId]);
    });

    testWidgets('a refused sign-out becomes a banner', (tester) async {
      directory.failWith = const KidSignInFailure(
        KidSignInProblem.deviceNotFound,
      );
      await pump(tester);
      await emit(tester, [tablet()]);

      await controller.revoke(tablet());
      await tester.pumpAndSettle();

      expect(
        find.text(KidCopy.problem(KidSignInProblem.deviceNotFound)),
        findsOneWidget,
      );
    });
  });

  testWidgets('survives dark at 200% text on a 360-wide phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, brightness: Brightness.dark, scale: 2);
    await emit(tester, [tablet(label: 'The big family tablet in the kitchen')]);
    expect(tester.takeException(), isNull);

    // At 200% the card is below the list's first build, so scroll to it.
    await tester.scrollUntilVisible(find.text(KidCopy.manageAddDevice), 200);
    await tester.pumpAndSettle();
    await makeCode(tester);
    expect(tester.takeException(), isNull);
  });
}

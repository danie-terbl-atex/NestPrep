import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/household/model/member_role.dart';
import 'package:nestprep/features/household/state/join_invite_controller.dart';
import 'package:nestprep/features/household/state/pending_invite.dart';
import 'package:nestprep/features/household/ui/join_invite_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_household.dart';
import '../../../support/pump_screen.dart';

void main() {
  late FakeHouseholdDirectory directory;
  late StreamController<Uri> links;
  late PendingInvite pending;
  late JoinInviteController controller;

  setUp(() async {
    directory = FakeHouseholdDirectory();
    links = StreamController<Uri>();
    pending = PendingInvite(links: links.stream);
    links.add(Uri.parse('nestprep://invite/ABCD2345'));
    await pumpEventQueue();
    controller = JoinInviteController(
      householdDirectory: directory,
      pendingInvite: pending,
    );
  });

  tearDown(() async {
    controller.dispose();
    pending.dispose();
    await links.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    await pumpScreen(
      tester,
      const JoinInviteScreen(),
      providers: [
        ChangeNotifierProvider<JoinInviteController>.value(value: controller),
      ],
      brightness: brightness,
      textScale: scale,
    );
    await controller.load();
    await tester.pumpAndSettle();
  }

  final joinButton = find.widgetWithText(
    NestButton,
    AccessCopy.inviteLinkTitle('The Parkers'),
  );

  testWidgets('shows the household, the profile, its role and who asked', (
    tester,
  ) async {
    await pump(tester);

    expect(directory.previewed, ['ABCD2345']);
    expect(
      find.text(
        AccessCopy.inviteLinkBody(
          memberName: 'Thandi',
          role: MemberRole.helper,
          invitedBy: 'Sam',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(AccessCopy.roleBlurb(MemberRole.helper)), findsOneWidget);
    expect(joinButton, findsOneWidget);
  });

  testWidgets('joining redeems the code and spends the link', (tester) async {
    await pump(tester);

    await tester.tap(joinButton);
    await tester.pumpAndSettle();

    expect(directory.redeemed, ['ABCD2345']);
    expect(pending.code, isNull);
  });

  testWidgets('not now spends the link and joins nothing', (tester) async {
    await pump(tester);

    await tester.tap(
      find.widgetWithText(NestButton, AccessCopy.inviteLinkNotNow),
    );
    await tester.pumpAndSettle();

    expect(directory.redeemed, isEmpty);
    expect(pending.code, isNull);
  });

  for (final problem in [
    HouseholdProblem.inviteExpired,
    HouseholdProblem.inviteAlreadyUsed,
    HouseholdProblem.inviteNotFound,
    HouseholdProblem.alreadyInHousehold,
  ]) {
    testWidgets('a refused invite says why: ${problem.name}', (tester) async {
      directory.failWith = HouseholdFailure(problem);
      await pump(tester);

      expect(
        find.text(AppCopy.failure(HouseholdFailure(problem))),
        findsOneWidget,
      );
      expect(find.text(AccessCopy.inviteLinkRefused), findsOneWidget);
      expect(joinButton, findsNothing);
      expect(pending.code, 'ABCD2345');

      await tester.tap(
        find.widgetWithText(NestButton, AccessCopy.inviteLinkClose),
      );
      await tester.pumpAndSettle();
      expect(pending.code, isNull);
    });
  }

  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('reads at 200% text in ${brightness.name}', (tester) async {
      await pump(tester, brightness: brightness, scale: 2);
      expect(tester.takeException(), isNull);
      expect(joinButton, findsOneWidget);
    });
  }
}

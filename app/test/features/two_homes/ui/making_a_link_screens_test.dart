import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/household/data/invite_sharer.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/features/two_homes/model/co_parent_home.dart';
import 'package:nestprep/features/two_homes/model/custody_schedule.dart';
import 'package:nestprep/features/two_homes/model/custody_side.dart';
import 'package:nestprep/features/two_homes/model/two_homes_access.dart';
import 'package:nestprep/features/two_homes/state/join_link_controller.dart';
import 'package:nestprep/features/two_homes/state/link_controller.dart';
import 'package:nestprep/features/two_homes/state/link_setup_controller.dart';
import 'package:nestprep/features/two_homes/state/schedule_draft.dart';
import 'package:nestprep/features/two_homes/ui/join_link_screen.dart';
import 'package:nestprep/features/two_homes/ui/link_setup_screen.dart';
import 'package:nestprep/features/two_homes/ui/privacy_screen.dart';
import 'package:nestprep/features/two_homes/ui/schedule_request_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_invite_sharer.dart';
import '../../../support/fake_two_homes.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_two_homes.dart';
import '../../../support/two_homes_model_fixtures.dart';

/// Making a code, accepting one, suggesting a new schedule, and the privacy
/// boundary shown at each (household ADR-0004).
void main() {
  late FakeTwoHomesDirectory directory;
  late FakeInviteSharer sharer;
  final today = CalendarDate(2026, 9, 30);

  setUp(() {
    directory = FakeTwoHomesDirectory();
    sharer = FakeInviteSharer();
  });

  /// Scrolls the screen's own list — not a multi-line field's scroll inside
  /// it — until all of [finder] is on screen: a tap on the part below the
  /// fold lands somewhere else
  /// (`lessons/scroll-to-the-last-line-of-what-you-will-tap-not-the-first`).
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder.first);
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.descendant(
    of: find.widgetWithText(NestTextField, label),
    matching: find.byType(EditableText),
  );

  group('making a code', () {
    Future<void> open(
      WidgetTester tester, {
      List<Member>? kids,
      Brightness brightness = Brightness.light,
      double textScale = 1,
      bool narrow = false,
    }) => pumpTwoHomes(
      tester,
      LinkSetupScreen(today: today),
      brightness: brightness,
      textScale: textScale,
      narrow: narrow,
      providers: [
        ChangeNotifierProvider(
          create: (_) => LinkSetupController(
            twoHomesDirectory: directory,
            inviteSharer: sharer,
            householdId: Fixtures.householdId,
            kids: kids ?? [Fixtures.kid],
            draft: ScheduleDraft(today: today),
          ),
        ),
      ],
    );

    testWidgets('names the home, tunes a custom fortnight and makes the code', (
      tester,
    ) async {
      await open(tester);
      await tester.enterText(
        field(TwoHomesSetupCopy.homeNameLabel),
        'Mum’s home',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      await reveal(
        tester,
        find.text(TwoHomesCopy.patternName(CustodyPattern.custom)),
      );
      await tester.tap(
        find.text(TwoHomesCopy.patternName(CustodyPattern.custom)),
      );
      await tester.pumpAndSettle();
      expect(find.text(TwoHomesCopy.customHint), findsOneWidget);
      // The draft changes homes on Friday, so the first Wednesday is the
      // other home's; a tap brings it to this one.
      final wednesday = find.bySemanticsLabel(
        RegExp(r'^Wed 30, with The other home$'),
      );
      await reveal(tester, wednesday);
      await tester.tap(wednesday);
      await tester.pump();

      await reveal(tester, find.text(TwoHomesSetupCopy.makeCode));
      await tester.tap(find.text(TwoHomesSetupCopy.makeCode));
      await tester.pumpAndSettle();

      final sent = directory.lastOf('createInvite');
      expect(sent['childMemberId'], Fixtures.kidMemberId);
      expect((sent['home']! as CoParentHome).name, 'Mum’s home');
      final schedule = sent['schedule']! as CustodySchedule;
      expect(schedule.pattern, CustodyPattern.custom);
      expect(schedule.cycle[2], CustodySide.a);
      expect(schedule.cycle[1], CustodySide.b);
      expect(find.text('ABCD2345'), findsOneWidget);
      expect(sharer.sent, hasLength(1));
      await reveal(tester, find.text(TwoHomesSetupCopy.done));
      await tester.tap(find.text(TwoHomesSetupCopy.done));
      await tester.pumpAndSettle();
      expect(find.text('landed on /households/h1/two-homes'), findsOneWidget);
    });

    testWidgets('the code can be shared again, and a missing sheet is said', (
      tester,
    ) async {
      sharer.outcome = InviteShareOutcome.unavailable;
      await open(tester);
      await tester.enterText(field(TwoHomesSetupCopy.homeNameLabel), 'Mum');
      await reveal(tester, find.text(TwoHomesSetupCopy.makeCode));
      await tester.tap(find.text(TwoHomesSetupCopy.makeCode));
      await tester.pumpAndSettle();
      expect(find.text(AccessCopy.inviteShareUnavailable), findsOneWidget);
      await reveal(tester, find.text(TwoHomesSetupCopy.shareCode));
      await tester.tap(find.text(TwoHomesSetupCopy.shareCode));
      await tester.pumpAndSettle();
      expect(sharer.sent, hasLength(2));
    });

    testWidgets('with no kid profile, says to add the child first', (
      tester,
    ) async {
      await open(tester, kids: const []);
      expect(find.text(TwoHomesSetupCopy.noKidsTitle), findsOneWidget);
      expect(find.text(TwoHomesSetupCopy.makeCode), findsNothing);
    });

    testWidgets('a refusal is said in words', (tester) async {
      directory.failWith = const CoParentFailure(
        CoParentProblem.childAlreadyLinked,
      );
      await open(tester);
      await tester.enterText(field(TwoHomesSetupCopy.homeNameLabel), 'Mum');
      await reveal(tester, find.text(TwoHomesSetupCopy.makeCode));
      await tester.tap(find.text(TwoHomesSetupCopy.makeCode));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(TwoHomesCopy.problem(CoParentProblem.childAlreadyLinked)),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text(TwoHomesCopy.problem(CoParentProblem.childAlreadyLinked)),
        findsOneWidget,
      );
    });

    testWidgets('holds at 360 wide, in dark, at 200% text', (tester) async {
      await open(
        tester,
        narrow: true,
        brightness: Brightness.dark,
        textScale: 2,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await reveal(tester, find.text(TwoHomesSetupCopy.makeCode));
      expect(tester.takeException(), isNull);
    });
  });

  group('accepting a code', () {
    Future<void> open(
      WidgetTester tester, {
      Brightness brightness = Brightness.light,
      double textScale = 1,
      bool narrow = false,
    }) => pumpTwoHomes(
      tester,
      const JoinLinkScreen(),
      brightness: brightness,
      textScale: textScale,
      narrow: narrow,
      providers: [
        ChangeNotifierProvider(
          create: (_) => JoinLinkController(
            twoHomesDirectory: directory,
            householdId: Fixtures.householdId,
            kids: [Fixtures.kid],
          ),
        ),
      ],
    );

    Future<void> checkACode(WidgetTester tester) async {
      await tester.enterText(field(TwoHomesSetupCopy.codeLabel), 'abcd2345');
      await tester.tap(find.text(TwoHomesSetupCopy.checkCode));
      await tester.pumpAndSettle();
    }

    testWidgets('shows what the code offers, then accepts and waits', (
      tester,
    ) async {
      await open(tester);
      await checkACode(tester);
      expect(
        find.text(TwoHomesSetupCopy.offerTitle('Mum’s home', 'Sam')),
        findsOneWidget,
      );
      expect(find.text(TwoHomesSetupCopy.sharedHeading), findsOneWidget);
      await tester.enterText(field(TwoHomesSetupCopy.homeNameLabel), 'Dad’s');
      // Done typing: a focused field pulls the list back to itself.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await reveal(tester, find.text(TwoHomesSetupCopy.acceptLink));
      await tester.tap(find.text(TwoHomesSetupCopy.acceptLink));
      await tester.pumpAndSettle();
      final sent = directory.lastOf('acceptInvite');
      expect(sent['code'], 'ABCD2345');
      expect(sent['newChildName'], 'Sam');
      expect(
        find.text(TwoHomesSetupCopy.acceptedTitle('Mum’s home')),
        findsOneWidget,
      );
    });

    testWidgets('a code that is not one is said, and the field stays', (
      tester,
    ) async {
      directory.failWith = const CoParentFailure(
        CoParentProblem.linkInviteNotFound,
      );
      await open(tester);
      await checkACode(tester);
      expect(
        find.text(TwoHomesCopy.problem(CoParentProblem.linkInviteNotFound)),
        findsOneWidget,
      );
      expect(find.text(TwoHomesSetupCopy.checkCode), findsOneWidget);
    });

    testWidgets('back from the offer returns to the code', (tester) async {
      await open(tester);
      await checkACode(tester);
      await reveal(tester, find.text(AppCopy.back));
      await tester.tap(find.text(AppCopy.back));
      await tester.pumpAndSettle();
      expect(find.text(TwoHomesSetupCopy.checkCode), findsOneWidget);
    });

    testWidgets('holds at 360 wide, in dark, at 200% text', (tester) async {
      await open(
        tester,
        narrow: true,
        brightness: Brightness.dark,
        textScale: 2,
      );
      await checkACode(tester);
      expect(tester.takeException(), isNull);
      await reveal(tester, find.text(TwoHomesSetupCopy.acceptLink));
      expect(tester.takeException(), isNull);
    });
  });

  group('the privacy boundary', () {
    testWidgets('lists what crosses and what stays, in plain words', (
      tester,
    ) async {
      await pumpTwoHomes(tester, const PrivacyScreen(), providers: const []);
      await tester.pumpAndSettle();
      expect(find.text(TwoHomesSetupCopy.sharedHeading), findsOneWidget);
      expect(find.text(TwoHomesSetupCopy.privateHeading), findsOneWidget);
      for (final item in TwoHomesSetupCopy.sharedItems.take(2)) {
        expect(find.text(item), findsOneWidget);
      }
    });

    testWidgets('holds at 360 wide, in dark, at 200% text', (tester) async {
      await pumpTwoHomes(
        tester,
        const PrivacyScreen(),
        providers: const [],
        narrow: true,
        brightness: Brightness.dark,
        textScale: 2,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('suggesting a new schedule', () {
    Future<void> open(
      WidgetTester tester, {
      Brightness brightness = Brightness.light,
      double textScale = 1,
      bool narrow = false,
    }) async {
      final repository = FakeTwoHomesRepository();
      addTearDown(repository.close);
      await pumpTwoHomes(
        tester,
        const ScheduleRequestScreen(),
        brightness: brightness,
        textScale: textScale,
        narrow: narrow,
        providers: [
          ChangeNotifierProvider(
            create: (_) => LinkController(
              twoHomesRepository: repository,
              twoHomesDirectory: directory,
              householdId: Fixtures.householdId,
              linkId: 'link-sam',
              today: today,
              access: TwoHomesAccess.of(Fixtures.view()),
            ),
          ),
        ],
      );
      repository.link.add(aLink());
      await tester.pumpAndSettle();
    }

    testWidgets('starts from the schedule as it is, and sends a new one', (
      tester,
    ) async {
      await open(tester);
      expect(find.text(TwoHomesCopy.scheduleRequestBody), findsOneWidget);
      await tester.tap(
        find.text(TwoHomesCopy.patternName(CustodyPattern.twoTwoThree)),
      );
      await tester.pump();
      await reveal(tester, find.text(TwoHomesCopy.send));
      await tester.tap(find.text(TwoHomesCopy.send));
      await tester.pumpAndSettle();
      final sent = directory.lastOf('proposeSchedule');
      expect(
        (sent['schedule']! as CustodySchedule).pattern,
        CustodyPattern.twoTwoThree,
      );
      // Opened straight here, so back is the link itself.
      expect(
        find.text('landed on /households/h1/two-homes/links/link-sam'),
        findsOneWidget,
      );
    });

    testWidgets('holds at 360 wide, in dark, at 200% text', (tester) async {
      await open(
        tester,
        narrow: true,
        brightness: Brightness.dark,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      await reveal(tester, find.text(TwoHomesCopy.send));
      expect(tester.takeException(), isNull);
    });
  });
}

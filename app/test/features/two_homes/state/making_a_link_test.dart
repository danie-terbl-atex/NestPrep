import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/household/data/invite_sharer.dart';
import 'package:nestprep/features/two_homes/model/co_parent_home.dart';
import 'package:nestprep/features/two_homes/model/custody_presets.dart';
import 'package:nestprep/features/two_homes/model/custody_schedule.dart';
import 'package:nestprep/features/two_homes/model/custody_side.dart';
import 'package:nestprep/features/two_homes/model/link_invite.dart';
import 'package:nestprep/features/two_homes/state/join_link_controller.dart';
import 'package:nestprep/features/two_homes/state/link_setup_controller.dart';
import 'package:nestprep/features/two_homes/state/schedule_draft.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/fake_invite_sharer.dart';
import '../../../support/fake_two_homes.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/two_homes_model_fixtures.dart';

/// Making a code and accepting one (household ADR-0004): the schedule draft
/// both use, what a code is made from, and what accepting sends.
void main() {
  final today = CalendarDate(2026, 9, 30);
  late FakeTwoHomesDirectory directory;

  setUp(() => directory = FakeTwoHomesDirectory());

  group('the schedule draft', () {
    test('starts on this week’s Monday, alternating weeks, complete', () {
      final draft = ScheduleDraft(today: today);
      expect(draft.startsOn, CalendarDate(2026, 9, 28));
      expect(draft.pattern, CustodyPattern.alternatingWeeks);
      expect(draft.schedule.isComplete, isTrue);
      draft.dispose();
    });

    test('every choice changes the schedule it makes', () {
      final draft = ScheduleDraft(today: today);
      var notified = 0;
      draft
        ..addListener(() => notified++)
        ..choosePattern(CustodyPattern.twoTwoThree)
        ..chooseFirst(CustodySide.b)
        ..chooseStart(CalendarDate(2026, 10, 8))
        ..chooseHandoverMinute(18 * 60);
      expect(draft.schedule.pattern, CustodyPattern.twoTwoThree);
      expect(draft.schedule.startsOn, CalendarDate(2026, 10, 5));
      expect(draft.schedule.cycle.first, CustodySide.b);
      expect(draft.schedule.handoverMinute, 18 * 60);
      expect(notified, 4);
      // Choosing what is already chosen is not a change.
      draft.choosePattern(CustodyPattern.twoTwoThree);
      expect(notified, 4);
      draft.dispose();
    });

    test('custom starts from what was showing, and a tap flips one day', () {
      final draft = ScheduleDraft(today: today)
        ..chooseSwitchWeekday(DateTime.monday);
      final before = draft.schedule.cycle;
      draft
        ..choosePattern(CustodyPattern.custom)
        ..flipDay(3);
      final after = draft.schedule.cycle;
      expect(after[3], before[3]!.other);
      expect([...after]..removeAt(3), [...before]..removeAt(3));
      expect(draft.schedule.isComplete, isTrue);
      draft
        ..flipDay(-1)
        ..flipDay(99)
        ..dispose();
    });

    test('from a live schedule, it is exactly that schedule', () {
      for (final live in [
        fixtureSchedule,
        CustodyPresets.twoTwoThree(
          startsOn: CalendarDate(2026, 9, 28),
          first: CustodySide.b,
        ),
        CustodyPresets.everyOtherWeekend(
          startsOn: CalendarDate(2026, 9, 28),
          primary: CustodySide.b,
          handoverMinute: 18 * 60,
        ),
      ]) {
        final draft = ScheduleDraft.from(live);
        expect(draft.schedule, live, reason: live.pattern.name);
        draft.dispose();
      }
    });

    test('a fortnight no preset makes opens as custom, days intact', () {
      final odd = CustodyPresets.fromCycle(
        pattern: CustodyPattern.custom,
        startsOn: CalendarDate(2026, 9, 28),
        days: [
          for (var day = 0; day < 14; day++)
            day.isEven ? CustodySide.a : CustodySide.b,
        ],
      );
      final draft = ScheduleDraft.from(odd);
      expect(draft.pattern, CustodyPattern.custom);
      expect(draft.schedule.cycle, odd.cycle);
      draft.dispose();
    });
  });

  group('making a code', () {
    LinkSetupController make(FakeInviteSharer sharer) => LinkSetupController(
      twoHomesDirectory: directory,
      inviteSharer: sharer,
      householdId: 'h1',
      kids: [Fixtures.kid],
      draft: ScheduleDraft(today: today),
    );

    test('needs a child, a home name and a complete schedule', () {
      final controller = make(FakeInviteSharer());
      // The only kid is chosen already.
      expect(controller.child, Fixtures.kid);
      expect(controller.canCreate, isFalse);
      controller.nameHome('  ');
      expect(controller.canCreate, isFalse);
      controller
        ..nameHome('Mum’s home')
        ..chooseColor(MemberColor.plum);
      expect(controller.canCreate, isTrue);
      controller.dispose();
    });

    test('makes the code from the choices, then shares it', () async {
      final sharer = FakeInviteSharer();
      final controller = make(sharer)
        ..nameHome(' Mum’s home ')
        ..chooseColor(MemberColor.plum);
      await controller.create();
      final sent = directory.lastOf('createInvite');
      expect(sent['childMemberId'], Fixtures.kidMemberId);
      expect(
        sent['home'],
        const CoParentHome(name: 'Mum’s home', color: MemberColor.plum),
      );
      expect((sent['schedule']! as CustodySchedule).isComplete, isTrue);
      expect(controller.invite?.code, 'ABCD2345');
      expect(sharer.sent.single.text, contains('ABCD2345'));
      // Only the first name leaves the house.
      expect(sharer.sent.single.text, contains('Kid'));
      expect(sharer.sent.single.text, isNot(contains('Parker')));
      expect(controller.shareOutcome, InviteShareOutcome.shared);
      controller.dispose();
    });

    test('a refusal is held and nothing is shared', () async {
      final sharer = FakeInviteSharer();
      directory.failWith = const CoParentFailure(
        CoParentProblem.childAlreadyLinked,
      );
      final controller = make(sharer)..nameHome('Mum’s home');
      await controller.create();
      expect(controller.invite, isNull);
      expect(controller.actionFailure, isA<CoParentFailure>());
      expect(sharer.sent, isEmpty);
      controller.dispose();
    });
  });

  group('accepting a code', () {
    JoinLinkController make() => JoinLinkController(
      twoHomesDirectory: directory,
      householdId: 'h2',
      kids: [Fixtures.kid.copyWith(displayName: 'Sam Mokoena')],
    );

    test(
      'checks the code, and guesses the profile by the child’s name',
      () async {
        final controller = make();
        await controller.check(' abcd2345 ');
        expect(directory.lastOf('previewInvite')['code'], 'abcd2345');
        expect(controller.preview?.childName, 'Sam');
        expect(controller.childId, Fixtures.kidMemberId);
        expect(controller.canAccept, isFalse);
        controller.nameHome('Dad’s home');
        expect(controller.canAccept, isTrue);
      },
    );

    test('never starts in the other home’s colour', () async {
      directory.preview = LinkInvitePreview(
        code: 'ABCD2345',
        childName: 'Sam',
        home: const CoParentHome(name: 'Mum’s home', color: MemberColor.sky),
        schedule: fixtureSchedule,
      );
      final controller = make();
      await controller.check('ABCD2345');
      expect(controller.color, isNot(MemberColor.sky));
    });

    test('accepts with the chosen profile, or makes a new one', () async {
      final controller = make();
      await controller.check('ABCD2345');
      controller.nameHome('Dad’s home');
      await controller.accept();
      expect(
        directory.lastOf('acceptInvite')['childMemberId'],
        Fixtures.kidMemberId,
      );
      expect(directory.lastOf('acceptInvite')['newChildName'], isNull);
      expect(controller.linkId, 'link-new');

      final another = make();
      await another.check('ABCD2345');
      another
        ..chooseChild(null)
        ..nameHome('Dad’s home');
      await another.accept();
      expect(directory.lastOf('acceptInvite')['newChildName'], 'Sam');
      expect(directory.lastOf('acceptInvite')['childMemberId'], isNull);
    });

    test(
      'a code that is not one is held, and starting over clears it',
      () async {
        directory.failWith = const CoParentFailure(
          CoParentProblem.linkInviteExpired,
        );
        final controller = make();
        await controller.check('ABCD2345');
        expect(controller.preview, isNull);
        expect(controller.actionFailure, isA<CoParentFailure>());
        controller.startOver();
        expect(controller.actionFailure, isNull);
        await controller.check('   ');
        expect(directory.calls, isEmpty);
      },
    );
  });
}

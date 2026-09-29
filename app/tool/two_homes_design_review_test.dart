import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/calendar/state/calendar_controller.dart';
import 'package:nestprep/features/calendar/ui/calendar_screen.dart';
import 'package:nestprep/features/two_homes/model/change_request.dart';
import 'package:nestprep/features/two_homes/model/co_parent_link.dart';
import 'package:nestprep/features/two_homes/model/custody_side.dart';
import 'package:nestprep/features/two_homes/model/handover_note.dart';
import 'package:nestprep/features/two_homes/model/two_homes_access.dart';
import 'package:nestprep/features/two_homes/state/custody_calendar.dart';
import 'package:nestprep/features/two_homes/state/handover_controller.dart';
import 'package:nestprep/features/two_homes/state/join_link_controller.dart';
import 'package:nestprep/features/two_homes/state/link_controller.dart';
import 'package:nestprep/features/two_homes/state/link_setup_controller.dart';
import 'package:nestprep/features/two_homes/state/schedule_draft.dart';
import 'package:nestprep/features/two_homes/state/two_homes_controller.dart';
import 'package:nestprep/features/two_homes/ui/handover_screen.dart';
import 'package:nestprep/features/two_homes/ui/join_link_screen.dart';
import 'package:nestprep/features/two_homes/ui/link_screen.dart';
import 'package:nestprep/features/two_homes/ui/link_setup_screen.dart';
import 'package:nestprep/features/two_homes/ui/privacy_screen.dart';
import 'package:nestprep/features/two_homes/ui/two_homes_screen.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/fake_calendar_repository.dart';
import '../test/support/fake_calendar_sync.dart';
import '../test/support/fake_invite_sharer.dart';
import '../test/support/fake_two_homes.dart';
import '../test/support/household_fixtures.dart';
import '../test/support/two_homes_model_fixtures.dart';
import 'review_press.dart';

/// Two homes in the design-review press (household ADR-0004): the list, a
/// link, a handover, making a code, accepting one, the privacy boundary, and
/// the week with a linked child's band — light and dark. Pictures to look at
/// rather than assertions: regenerate with
///
///     flutter test tool/two_homes_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  final today = CalendarDate(2026, 10, 1);
  final friday = CalendarDate(2026, 10, 2);

  ({FakeTwoHomesRepository repository, FakeTwoHomesDirectory directory})
  fakes() {
    final repository = FakeTwoHomesRepository();
    addTearDown(repository.close);
    return (repository: repository, directory: FakeTwoHomesDirectory());
  }

  final swap = ChangeRequest(
    id: 'swap-1',
    kind: ChangeKind.swap,
    from: CalendarDate(2026, 10, 9),
    to: CalendarDate(2026, 10, 11),
    toSide: CustodySide.b,
    note: 'Granny’s 80th on Saturday',
    proposedBySide: CustodySide.b,
    status: RequestStatus.pending,
  );
  final note = HandoverNote(
    id: friday.iso,
    date: friday,
    items: const [
      HandoverItem(text: 'School bag', packed: true),
      HandoverItem(text: 'Inhaler', packed: true),
      HandoverItem(text: 'PE kit', packed: false),
    ],
    medicine: 'Two puffs of the inhaler at 7',
    homework: 'Reading log, due Monday',
    updatedBySide: CustodySide.b,
  );

  for (final brightness in Brightness.values) {
    final suffix = brightness.name;

    testWidgets('two homes, $suffix', (tester) async {
      final (:repository, :directory) = fakes();
      await captureScreen(
        tester,
        'two-homes-$suffix',
        brightness: brightness,
        screen: const TwoHomesScreen(),
        providers: [
          ChangeNotifierProvider(
            create: (_) => TwoHomesController(
              twoHomesRepository: repository,
              twoHomesDirectory: directory,
              householdId: Fixtures.householdId,
              today: today,
            ),
          ),
        ],
        emit: () async => repository.links.add([
          aLink(),
          aLink(
            status: LinkStatus.pending,
            awaitingSide: CustodySide.a,
          ).copyWith(
            id: 'pending',
            childMemberId: 'm-other',
            childName: 'Lerato',
          ),
        ]),
      );
    });

    testWidgets('a link, $suffix', (tester) async {
      final (:repository, :directory) = fakes();
      await captureScreen(
        tester,
        'two-homes-link-$suffix',
        brightness: brightness,
        screen: const LinkScreen(),
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
        emit: () async {
          repository.link.add(aLink());
          repository.requests.add([swap]);
          repository.handovers.add([note]);
        },
      );
    });

    testWidgets('a handover, $suffix', (tester) async {
      final (:repository, :directory) = fakes();
      await captureScreen(
        tester,
        'two-homes-handover-$suffix',
        brightness: brightness,
        screen: HandoverScreen(today: today),
        providers: [
          ChangeNotifierProvider(
            create: (_) => HandoverController(
              twoHomesRepository: repository,
              twoHomesDirectory: directory,
              householdId: Fixtures.householdId,
              linkId: 'link-sam',
              date: friday,
            ),
          ),
        ],
        emit: () async {
          repository.link.add(aLink());
          repository.handover.add(note);
        },
      );
    });

    testWidgets('making a code, $suffix', (tester) async {
      final (:repository, :directory) = fakes();
      await captureScreen(
        tester,
        'two-homes-setup-$suffix',
        brightness: brightness,
        screen: LinkSetupScreen(today: today),
        providers: [
          ChangeNotifierProvider(
            create: (_) => LinkSetupController(
              twoHomesDirectory: directory,
              inviteSharer: FakeInviteSharer(),
              householdId: Fixtures.householdId,
              kids: [Fixtures.kid],
              draft: ScheduleDraft(today: today),
            )..nameHome('Mum’s home'),
          ),
        ],
        emit: () async => repository.links.add(const []),
      );
    });

    testWidgets('accepting a code, $suffix', (tester) async {
      final (:repository, :directory) = fakes();
      late JoinLinkController join;
      await captureScreen(
        tester,
        'two-homes-join-$suffix',
        brightness: brightness,
        screen: const JoinLinkScreen(),
        providers: [
          ChangeNotifierProvider(
            create: (_) => join = JoinLinkController(
              twoHomesDirectory: directory,
              householdId: Fixtures.householdId,
              kids: [Fixtures.kid],
            ),
          ),
        ],
        emit: () async {
          repository.links.add(const []);
          await join.check('ABCD2345');
          join.nameHome('Dad’s home');
        },
      );
    });

    testWidgets('the privacy boundary, $suffix', (tester) async {
      await captureScreen(
        tester,
        'two-homes-privacy-$suffix',
        brightness: brightness,
        screen: const PrivacyScreen(),
        providers: const [],
        emit: () async {},
      );
    });

    testWidgets('the week with a linked child, $suffix', (tester) async {
      final (:repository, directory: _) = fakes();
      final calendar = FakeCalendarRepository();
      addTearDown(calendar.close);
      final controller = CalendarController(
        calendarRepository: calendar,
        calendarSyncRepository: FakeCalendarSyncRepository(),
        householdClock: HouseholdClock(
          'Africa/Johannesburg',
          now: () => DateTime.utc(2026, 10, 2, 7),
        ),
        householdId: Fixtures.householdId,
        memberId: Fixtures.samMemberId,
        householdMembers: const [],
      );
      addTearDown(controller.dispose);
      await captureScreen(
        tester,
        'week-two-homes-$suffix',
        brightness: brightness,
        screen: CalendarScreen(onSelectTab: (_) {}),
        providers: [
          ChangeNotifierProvider<CalendarController>.value(value: controller),
          ChangeNotifierProvider(
            create: (_) => CustodyCalendar(
              twoHomesRepository: repository,
              householdId: Fixtures.householdId,
            ),
          ),
        ],
        emit: () async {
          calendar
            ..emitEvents(const [])
            ..emitExceptions(const []);
          repository.links.add([aLink()]);
        },
      );
    });
  }
}

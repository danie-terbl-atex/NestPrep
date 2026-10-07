import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/two_homes/data/two_homes_directory.dart';
import 'package:nestprep/features/two_homes/model/change_request.dart';
import 'package:nestprep/features/two_homes/model/co_parent_link.dart';
import 'package:nestprep/features/two_homes/model/custody_side.dart';
import 'package:nestprep/features/two_homes/model/two_homes_access.dart';
import 'package:nestprep/features/two_homes/state/link_controller.dart';
import 'package:nestprep/features/two_homes/ui/link_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_two_homes.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_two_homes.dart';
import '../../../support/two_homes_model_fixtures.dart';

/// One link (household ADR-0004): the fortnight ahead, the coming handovers,
/// and the requests between the homes — answered, withdrawn and asked — each
/// part only for somebody whose grant reaches it.
void main() {
  late FakeTwoHomesRepository repository;
  late FakeTwoHomesDirectory directory;
  final today = CalendarDate(2026, 10, 1);

  setUp(() {
    repository = FakeTwoHomesRepository();
    directory = FakeTwoHomesDirectory();
  });

  tearDown(() => repository.close());

  ChangeRequest swapFrom(CustodySide side, {String id = 'swap-1'}) =>
      ChangeRequest(
        id: id,
        kind: ChangeKind.swap,
        from: CalendarDate(2026, 10, 9),
        to: CalendarDate(2026, 10, 10),
        toSide: side,
        note: 'Granny’s birthday',
        proposedBySide: side,
        status: RequestStatus.pending,
      );

  /// Scrolls until [finder] is on screen, then until all of it is — a tap on
  /// the part below the fold lands somewhere else
  /// (`lessons/scroll-to-the-last-line-of-what-you-will-tap-not-the-first`).
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 300);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  Future<void> open(
    WidgetTester tester, {
    CoParentLink? link,
    List<ChangeRequest> requests = const [],
    HouseholdView? view,
    Brightness brightness = Brightness.light,
    double textScale = 1,
    bool narrow = false,
  }) async {
    final household = view ?? Fixtures.view();
    await pumpTwoHomes(
      tester,
      const LinkScreen(),
      view: household,
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
            access: TwoHomesAccess.of(household),
          ),
        ),
      ],
    );
    repository.link.add(link ?? aLink());
    repository.requests.add(requests);
    repository.handovers.add(const []);
    await tester.pumpAndSettle();
  }

  testWidgets('shows the fortnight and the coming handovers, by home', (
    tester,
  ) async {
    await open(tester);
    expect(find.text(TwoHomesCopy.nextTwoWeeks), findsOneWidget);
    expect(
      find.text(TwoHomesCopy.handoverRow('Kid Parker', 'Mum’s home')),
      findsWidgets,
    );
    expect(find.textContaining(TwoHomesCopy.handoverAt('17:00')), findsWidgets);
    await tester.tap(
      find.text(TwoHomesCopy.handoverRow('Kid Parker', 'Mum’s home')).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'landed on /households/h1/two-homes/links/link-sam/handovers/2026-10-02',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the other home’s request is answered from here', (tester) async {
    await open(tester, requests: [swapFrom(CustodySide.b)]);
    await reveal(tester, find.text(TwoHomesCopy.accept));
    expect(find.text('“Granny’s birthday”'), findsOneWidget);
    expect(find.text(TwoHomesCopy.askedBy('Dad’s home')), findsOneWidget);
    await tester.tap(find.text(TwoHomesCopy.accept));
    await tester.pumpAndSettle();
    expect(directory.lastOf('answerChange'), {
      'requestId': 'swap-1',
      'answer': ChangeAnswer.accept,
      'note': null,
    });
  });

  testWidgets('this home’s own request can only be withdrawn', (tester) async {
    await open(tester, requests: [swapFrom(CustodySide.a)]);
    await reveal(tester, find.text(TwoHomesCopy.withdraw));
    expect(find.text(TwoHomesCopy.accept), findsNothing);
    await tester.tap(find.text(TwoHomesCopy.withdraw));
    await tester.pumpAndSettle();
    expect(directory.lastOf('answerChange')['answer'], ChangeAnswer.withdraw);
  });

  testWidgets('answered requests are kept as history', (tester) async {
    await open(
      tester,
      requests: [
        swapFrom(CustodySide.b).copyWith(
          status: RequestStatus.declined,
          answeredBySide: CustodySide.a,
          answerNote: 'Not that weekend',
        ),
      ],
    );
    await reveal(tester, find.text(TwoHomesCopy.history));
    expect(
      find.text(TwoHomesCopy.answeredNote('Mum’s home', 'Not that weekend')),
      findsOneWidget,
    );
    expect(find.text(TwoHomesCopy.accept), findsNothing);
  });

  testWidgets('asks for a swap through the sheet', (tester) async {
    await open(tester);
    await reveal(tester, find.text(TwoHomesCopy.askForASwap));
    await tester.tap(find.text(TwoHomesCopy.askForASwap));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).last, 'Half term');
    await tester.ensureVisible(find.text(TwoHomesCopy.send));
    await tester.tap(find.text(TwoHomesCopy.send));
    await tester.pumpAndSettle();
    final sent = directory.lastOf('proposeSwap');
    expect(sent['from'], CalendarDate(2026, 10, 2));
    expect(sent['toSide'], CustodySide.a);
    expect(sent['note'], 'Half term');
  });

  testWidgets('suggesting a schedule opens its own screen', (tester) async {
    await open(tester);
    await reveal(tester, find.text(TwoHomesCopy.suggestSchedule));
    await tester.tap(find.text(TwoHomesCopy.suggestSchedule));
    await tester.pumpAndSettle();
    expect(
      find.text('landed on /households/h1/two-homes/links/link-sam/schedule'),
      findsOneWidget,
    );
  });

  testWidgets('an admin ends the link, after saying yes', (tester) async {
    await open(tester);
    await reveal(tester, find.text(TwoHomesCopy.endLink));
    await tester.tap(find.text(TwoHomesCopy.endLink));
    await tester.pumpAndSettle();
    expect(find.text(TwoHomesCopy.endQuestion('Dad’s home')), findsOneWidget);
    await tester.tap(find.text(TwoHomesCopy.endCancel));
    await tester.pumpAndSettle();
    expect(directory.calls, isEmpty);
    await tester.tap(find.text(TwoHomesCopy.endLink));
    await tester.pumpAndSettle();
    await tester.tap(find.text(TwoHomesCopy.endConfirm).last);
    await tester.pumpAndSettle();
    expect(directory.names, ['endLink']);
  });

  testWidgets('a helper who reads the calendar sees the schedule, no more', (
    tester,
  ) async {
    await open(
      tester,
      view: Fixtures.helperView(
        AccessGrant.uniform(
          AccessLevel.none,
        ).withLevel(HouseholdArea.calendar, AccessLevel.view),
      ),
    );
    expect(repository.readsOpened, ['link']);
    expect(find.text(TwoHomesCopy.nextTwoWeeks), findsOneWidget);
    await reveal(tester, find.text(TwoHomesCopy.scheduleOnly));
    expect(find.text(TwoHomesCopy.requests), findsNothing);
    expect(find.text(TwoHomesCopy.endLink), findsNothing);
    // The rows are there, but a handover is not theirs to open.
    await tester.tap(
      find.text(TwoHomesCopy.handoverRow('Kid Parker', 'Mum’s home')).first,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('landed on'), findsNothing);
  });

  testWidgets('an ended link says so and offers nothing to do', (tester) async {
    await open(tester, link: aLink(status: LinkStatus.ended));
    expect(find.text(TwoHomesCopy.endBody), findsOneWidget);
    expect(find.text(TwoHomesCopy.askForASwap), findsNothing);
    expect(find.text(TwoHomesCopy.nextTwoWeeks), findsNothing);
  });

  testWidgets('a link that is gone says so', (tester) async {
    await pumpTwoHomes(
      tester,
      const LinkScreen(),
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
    repository.link.add(null);
    await tester.pumpAndSettle();
    expect(find.text(TwoHomesCopy.linkGone), findsOneWidget);
  });

  testWidgets('holds at 360 wide, in dark, at 200% text', (tester) async {
    await open(
      tester,
      narrow: true,
      brightness: Brightness.dark,
      textScale: 2,
      requests: [
        swapFrom(CustodySide.b),
        swapFrom(CustodySide.a, id: 'swap-2'),
      ],
    );
    expect(tester.takeException(), isNull);
    await reveal(tester, find.text(TwoHomesCopy.endLink));
    expect(tester.takeException(), isNull);
    expect(find.text(AppCopy.retry), findsNothing);
  });
}

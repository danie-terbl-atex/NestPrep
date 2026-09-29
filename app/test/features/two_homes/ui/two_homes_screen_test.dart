import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/two_homes/model/co_parent_link.dart';
import 'package:nestprep/features/two_homes/model/custody_side.dart';
import 'package:nestprep/features/two_homes/state/two_homes_controller.dart';
import 'package:nestprep/features/two_homes/ui/two_homes_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_two_homes.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_two_homes.dart';
import '../../../support/two_homes_model_fixtures.dart';

/// The two-homes list (household ADR-0004): the ways in stay on screen with
/// or without a link, a pending link asks the right home the right question,
/// an active one says where the child is today, and the history is kept.
void main() {
  late FakeTwoHomesRepository repository;
  late FakeTwoHomesDirectory directory;
  // Thursday 1 October: the child is with Mum's home until Friday's change.
  final today = CalendarDate(2026, 10, 1);

  setUp(() {
    repository = FakeTwoHomesRepository();
    directory = FakeTwoHomesDirectory();
  });

  tearDown(() => repository.close());

  Future<void> open(
    WidgetTester tester, {
    List<CoParentLink> links = const [],
    bool emit = true,
    HouseholdView? view,
    Brightness brightness = Brightness.light,
    double textScale = 1,
    bool narrow = false,
  }) async {
    await pumpTwoHomes(
      tester,
      const TwoHomesScreen(),
      view: view ?? Fixtures.view(),
      brightness: brightness,
      textScale: textScale,
      narrow: narrow,
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
    );
    if (emit) {
      repository.links.add(links);
      await tester.pumpAndSettle();
    }
  }

  testWidgets('with no link, says what it is for and keeps both ways in', (
    tester,
  ) async {
    await open(tester);
    expect(find.text(TwoHomesCopy.emptyTitle), findsOneWidget);
    expect(find.text(TwoHomesCopy.linkAnotherHome), findsOneWidget);
    expect(find.text(TwoHomesCopy.haveACode), findsOneWidget);
    expect(find.text(TwoHomesSetupCopy.privacyOpen), findsOneWidget);

    await tester.tap(find.text(TwoHomesCopy.linkAnotherHome));
    await tester.pumpAndSettle();
    expect(find.text('landed on /households/h1/two-homes/new'), findsOneWidget);
  });

  testWidgets('I have a code, and the privacy boundary, each open', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text(TwoHomesCopy.haveACode));
    await tester.pumpAndSettle();
    expect(
      find.text('landed on /households/h1/two-homes/join'),
      findsOneWidget,
    );
  });

  testWidgets('while loading, then a failure the screen can retry', (
    tester,
  ) async {
    await open(tester, emit: false);
    repository.links.addError(const UnavailableFailure());
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.retry), findsOneWidget);
    await tester.tap(find.text(AppCopy.retry));
    // Retrying cancels the failed listener before it opens a new one.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    repository.links.add([]);
    await tester.pumpAndSettle();
    expect(find.text(TwoHomesCopy.emptyTitle), findsOneWidget);
  });

  testWidgets('the home that made the code is asked to confirm, and can', (
    tester,
  ) async {
    await open(
      tester,
      links: [aLink(status: LinkStatus.pending, awaitingSide: CustodySide.a)],
    );
    expect(
      find.text(TwoHomesCopy.confirmQuestion('Dad’s home', 'Kid Parker')),
      findsOneWidget,
    );
    await tester.tap(find.text(TwoHomesCopy.confirmYes));
    await tester.pumpAndSettle();
    expect(directory.lastOf('confirmLink'), {
      'linkId': 'link-sam',
      'accept': true,
    });
  });

  testWidgets('the home that accepted waits, and may withdraw', (tester) async {
    await open(
      tester,
      links: [
        aLink(
          status: LinkStatus.pending,
          ownSide: CustodySide.b,
          awaitingSide: CustodySide.a,
        ),
      ],
    );
    expect(find.text(TwoHomesCopy.waitingFor('Mum’s home')), findsOneWidget);
    expect(find.text(TwoHomesCopy.confirmYes), findsNothing);
    await tester.tap(find.text(TwoHomesCopy.withdraw));
    await tester.pumpAndSettle();
    expect(directory.names, ['endLink']);
  });

  testWidgets('an active link says where the child is and opens', (
    tester,
  ) async {
    await open(tester, links: [aLink()]);
    expect(
      find.text(TwoHomesCopy.withToday('Kid Parker', 'Dad’s home')),
      findsOneWidget,
    );
    expect(
      find.textContaining(TwoHomesCopy.nextHandover('Tomorrow', 'Mum’s home')),
      findsOneWidget,
    );
    await tester.tap(find.text('Kid Parker'));
    await tester.pumpAndSettle();
    expect(
      find.text('landed on /households/h1/two-homes/links/link-sam'),
      findsOneWidget,
    );
  });

  testWidgets('an ended link is kept as history', (tester) async {
    await open(tester, links: [aLink(status: LinkStatus.ended)]);
    await tester.scrollUntilVisible(find.text(TwoHomesCopy.statusEnded), 200);
    expect(find.text(TwoHomesCopy.pastLinks), findsOneWidget);
    expect(find.text(TwoHomesCopy.emptyTitle), findsOneWidget);
  });

  testWidgets('somebody who is not an admin is told who starts one', (
    tester,
  ) async {
    await open(
      tester,
      view: Fixtures.helperView(
        AccessGrant.uniform(AccessLevel.none)
            .withLevel(HouseholdArea.calendar, AccessLevel.edit),
      ),
    );
    expect(find.text(TwoHomesCopy.adminStartsNote), findsOneWidget);
    expect(find.text(TwoHomesCopy.linkAnotherHome), findsNothing);
  });

  testWidgets('a refused answer is said, in words', (tester) async {
    directory.failWith = const CoParentFailure(CoParentProblem.notYourTurn);
    await open(
      tester,
      links: [aLink(status: LinkStatus.pending, awaitingSide: CustodySide.a)],
    );
    await tester.tap(find.text(TwoHomesCopy.confirmNo));
    await tester.pumpAndSettle();
    expect(
      find.text(TwoHomesCopy.problem(CoParentProblem.notYourTurn)),
      findsOneWidget,
    );
  });

  testWidgets('holds at 360 wide, in dark, at 200% text', (tester) async {
    await open(
      tester,
      narrow: true,
      brightness: Brightness.dark,
      textScale: 2,
      links: [
        aLink(
          status: LinkStatus.pending,
          awaitingSide: CustodySide.a,
        ).copyWith(id: 'pending'),
        aLink(),
        aLink(status: LinkStatus.ended).copyWith(id: 'ended'),
      ],
    );
    expect(tester.takeException(), isNull);
  });
}

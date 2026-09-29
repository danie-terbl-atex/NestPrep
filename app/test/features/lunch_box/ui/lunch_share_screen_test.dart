import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/family_profiles/model/family_roster.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/lunch_box/data/lunch_card_sharer.dart';
import 'package:nestprep/features/lunch_box/model/lunch_card_naming.dart';
import 'package:nestprep/features/lunch_box/model/lunch_plan.dart';
import 'package:nestprep/features/lunch_box/state/lunch_board_controller.dart';
import 'package:nestprep/features/lunch_box/state/lunch_share_controller.dart';
import 'package:nestprep/features/lunch_box/ui/share/lunch_card_preview.dart';
import 'package:nestprep/features/lunch_box/ui/share/lunch_share_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_lunch_share.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/lunch_card_fixtures.dart';
import '../../../support/lunch_fixtures.dart';
import '../../../support/lunch_harness.dart';
import '../../../support/pump_screen.dart';

void main() {
  late LunchHarness harness;
  late FakeLunchCardRenderer renderer;
  late FakeLunchCardSharer sharer;
  late FakeLunchPlannerComposer planner;
  late LunchShareController share;

  setUp(() {
    harness = LunchHarness();
    renderer = FakeLunchCardRenderer();
    sharer = FakeLunchCardSharer();
    planner = FakeLunchPlannerComposer();
    share = LunchShareController(
      cardRenderer: renderer,
      cardSharer: sharer,
      plannerComposer: planner,
      initialChildId: LunchFixtures.lwaziId,
    );
  });
  tearDown(() async {
    share.dispose();
    await harness.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
    bool viewOnly = false,
    Size size = const Size(420, 2400),
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpScreen(
      tester,
      const LunchShareScreen(),
      providers: [
        ChangeNotifierProvider<LunchBoardController>.value(
          value: harness.controller,
        ),
        ChangeNotifierProvider<LunchShareController>.value(value: share),
      ],
      view: viewOnly
          ? Fixtures.helperView(
              AccessGrant({
                HouseholdArea.lunch: AccessLevel.view,
                HouseholdArea.familyProfiles: AccessLevel.view,
              }),
            )
          : null,
      brightness: brightness,
      textScale: scale,
    );
  }

  Future<void> arrive(
    WidgetTester tester, {
    List<LunchPlan>? plans,
    FamilyRoster? roster,
  }) async {
    harness.emit(
      roster: roster,
      items: LunchCardFixtures.library,
      plans:
          plans ?? [LunchCardFixtures.lwaziWeek, LunchCardFixtures.ayandaWeek],
    );
    await tester.pumpAndSettle();
  }

  Finder onTheCard(String text) => find.descendant(
    of: find.byType(LunchCardPreview),
    matching: find.textContaining(text),
  );

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  testWidgets('holds the layout while the week loads', (tester) async {
    await pump(tester);
    expect(find.byType(NestLoadingView), findsOneWidget);
    expect(find.text(LunchShareCopy.shareImage), findsNothing);
  });

  testWidgets('with no children yet, says where they are added', (
    tester,
  ) async {
    await pump(tester);
    await arrive(
      tester,
      roster: FamilyRoster(
        members: const [],
        profiles: const [],
        schools: const [],
      ),
    );
    expect(find.text(LunchCopy.noChildrenTitle), findsOneWidget);
    expect(find.text(LunchCopy.openFamily), findsOneWidget);
  });

  testWidgets('a read that fails shows copy and a retry', (tester) async {
    await pump(tester);
    harness.repository.failItemsWith(const UnknownFailure('boom'));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.retry), findsOneWidget);
    expect(find.textContaining('boom'), findsNothing);
  });

  testWidgets('somebody who may only look finds the door shut', (tester) async {
    await pump(tester, viewOnly: true);
    await arrive(tester);
    expect(find.text(LunchShareCopy.onlyPlanners), findsOneWidget);
    expect(find.text(LunchShareCopy.shareImage), findsNothing);
  });

  testWidgets('by default the card names nobody and says nothing about '
      'allergies or school', (tester) async {
    await pump(tester);
    await arrive(tester);
    expect(find.byType(LunchCardPreview), findsOneWidget);
    expect(onTheCard('Cheese rolls'), findsWidgets);
    expect(onTheCard('Lwazi'), findsNothing);
    expect(onTheCard('Peanut'), findsNothing);
    expect(onTheCard('Oakwood'), findsNothing);
    expect(onTheCard('nut'), findsNothing);
  });

  testWidgets('a first name goes on only when chosen', (tester) async {
    await pump(tester);
    await arrive(tester);
    await tapText(
      tester,
      LunchShareCopy.namingName(LunchCardNaming.firstNames),
    );
    expect(onTheCard('Lwazi'), findsOneWidget);
  });

  testWidgets('share image draws the card and opens the share sheet', (
    tester,
  ) async {
    await pump(tester);
    await arrive(tester);
    await tapText(tester, LunchShareCopy.everyone);
    await tapText(tester, LunchShareCopy.shareImage);
    expect(renderer.requests.single.$1.isFamily, isTrue);
    expect(sharer.shared.single.mimeType, LunchSharedFile.png);
  });

  testWidgets('a share that fails is said in copy, never as a code', (
    tester,
  ) async {
    sharer.failWith = const LunchFailure(LunchProblem.shareUnavailable);
    await pump(tester);
    await arrive(tester);
    await tapText(tester, LunchShareCopy.shareImage);
    expect(
      find.text(LunchCopy.problem(LunchProblem.shareUnavailable)),
      findsOneWidget,
    );
  });

  testWidgets('a week with nothing packed cannot be shared, and points at '
      'the blank planner', (tester) async {
    await pump(tester);
    await arrive(tester, plans: const []);
    expect(find.text(LunchShareCopy.nothingToShare), findsOneWidget);
    await tapText(tester, LunchShareCopy.shareImage);
    expect(renderer.requests, isEmpty);
    await tapText(tester, LunchShareCopy.plannerBlank);
    await tapText(tester, LunchShareCopy.print);
    expect(planner.requests.single.$1, isNull);
    expect(sharer.printed.single, LunchShareCopy.plannerFileName(null));
  });

  testWidgets('the planner is sent as a PDF', (tester) async {
    await pump(tester);
    await arrive(tester);
    await tapText(tester, LunchShareCopy.sendPdf);
    expect(planner.requests.single.$1?.children.single.label, 'L');
    expect(sharer.shared.single.mimeType, LunchSharedFile.pdf);
  });

  testWidgets('renders in dark and at 200% text on a narrow phone without '
      'overflowing', (tester) async {
    await pump(
      tester,
      brightness: Brightness.dark,
      scale: 2,
      size: const Size(360, 800),
    );
    await arrive(tester);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

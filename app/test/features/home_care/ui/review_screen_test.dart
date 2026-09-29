import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/home_care_route.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/home_care_fixtures.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_home_care.dart';

/// The parent's review (home-care ADR-0001): before and after side by side,
/// approve, or send back with a note the helper will read.
void main() {
  late HomeCareHarness harness;
  final review = HomeCareRoute.reviewPathFor(Fixtures.householdId, 'oven');

  setUp(() {
    harness = HomeCareHarness();
    harness.photos.stored['oven/before'] = HomeCareFixtures.photoBytes;
    harness.photos.stored['oven/after-2'] = HomeCareFixtures.photoBytes;
  });
  tearDown(() => harness.close());

  Future<void> open(WidgetTester tester) async {
    HomeCareHarness.makeRoom(tester);
    await harness.pump(tester, location: review);
    await harness.emit(tester, jobList: [HomeCareFixtures.handedIn()]);
  }

  testWidgets('shows the spot before and after, each labelled in words', (
    tester,
  ) async {
    await open(tester);
    expect(find.text(HomeCareCopy.handedInBy('Thandi Helper')), findsOneWidget);
    expect(find.text(HomeCareCopy.before), findsOneWidget);
    expect(find.text(HomeCareCopy.after), findsOneWidget);
    expect(find.bySemanticsLabel(HomeCareCopy.beforePhoto), findsOneWidget);
    expect(find.bySemanticsLabel(HomeCareCopy.afterPhoto), findsOneWidget);
  });

  testWidgets('approving writes the approval and goes back', (tester) async {
    await open(tester);
    await tester.tap(find.text(HomeCareCopy.approve));
    await tester.pumpAndSettle();
    expect(harness.jobs.methods, ['approve']);
    expect(find.text(HomeCareCopy.reviewTitle), findsNothing);
  });

  testWidgets('sending back needs a note, and sends the note', (tester) async {
    await open(tester);
    await tester.tap(find.text(HomeCareCopy.sendBack));
    await tester.pumpAndSettle();

    // The sheet's own button stays off until there is something to say.
    NestButton sheetButton() => tester.widget<NestButton>(
      find.widgetWithText(NestButton, HomeCareCopy.sendBack).last,
    );
    expect(sheetButton().onPressed, isNull);
    await tester.enterText(
      find.byType(EditableText),
      'The tap is still marked',
    );
    await tester.pumpAndSettle();
    expect(sheetButton().onPressed, isNotNull);
    await tester.tap(find.text(HomeCareCopy.sendBack).last);
    await tester.pumpAndSettle();

    final (method, arguments) = harness.jobs.writes.single;
    expect(method, 'sendBack');
    expect(arguments['note'], 'The tap is still marked');
  });

  testWidgets('a refused review is said in words, and the job stays', (
    tester,
  ) async {
    await open(tester);
    harness.jobs.failWritesWith = const PermissionDeniedFailure();
    await tester.tap(find.text(HomeCareCopy.approve));
    await tester.pumpAndSettle();
    expect(
      find.text(AppCopy.failure(const PermissionDeniedFailure())),
      findsOneWidget,
    );
    expect(find.text(HomeCareCopy.reviewTitle), findsOneWidget);
  });

  testWidgets('a helper who finds the review has nothing to press', (
    tester,
  ) async {
    HomeCareHarness.makeRoom(tester);
    await harness.pump(
      tester,
      location: review,
      view: HomeCareFixtures.helperView(),
    );
    await harness.emit(tester, jobList: [HomeCareFixtures.handedIn()]);
    expect(find.text(HomeCareCopy.approve), findsNothing);
    expect(find.text(HomeCareCopy.nothingToReview), findsOneWidget);
  });
}

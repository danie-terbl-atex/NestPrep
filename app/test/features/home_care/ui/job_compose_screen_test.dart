import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/home_care_route.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/home_care/model/job_details.dart';
import 'package:nestprep/features/home_care/model/job_photo.dart';
import 'package:nestprep/features/home_care/model/spot_mark.dart';
import 'package:nestprep/shared/copy/app_copy.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/pump_home_care.dart';

/// A parent turning a photo of a spot into a job (home-care ADR-0001): the
/// photo, the circle, where, who, when, with what and how — and the safety
/// the helper will see, before it is sent.
void main() {
  late HomeCareHarness harness;

  setUp(() => harness = HomeCareHarness());
  tearDown(() => harness.close());

  Future<void> open(WidgetTester tester) async {
    HomeCareHarness.makeRoom(tester);
    await harness.pump(
      tester,
      location: HomeCareRoute.newJobPathFor(Fixtures.householdId),
    );
    await harness.emit(tester);
  }

  /// The text box under a kit field's label.
  Finder fieldLabelled(String label) => find.descendant(
    of: find.ancestor(
      of: find.text(label).first,
      matching: find.byType(NestTextField),
    ),
    matching: find.byType(EditableText),
  );

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).first);
    await tester.tap(find.text(text).first);
    await tester.pumpAndSettle();
  }

  testWidgets('assigning too early says what is missing, where it is missing', (
    tester,
  ) async {
    await open(tester);
    await tapText(tester, HomeCareCopy.assign);

    expect(find.text(HomeCareCopy.photoMissing), findsOneWidget);
    for (final problem in JobDetailsProblem.values) {
      expect(find.text(HomeCareCopy.missing(problem)), findsOneWidget);
    }
    expect(harness.photos.writes, isEmpty);
    expect(harness.jobs.writes, isEmpty);
  });

  testWidgets('a photo, a circle, the details — and the job is assigned', (
    tester,
  ) async {
    await open(tester);

    await tapText(tester, HomeCareCopy.takePhoto);
    expect(find.text(HomeCareCopy.markSpot), findsOneWidget);

    await tapText(tester, HomeCareCopy.markSpot);
    final surface = find.bySemanticsLabel(HomeCareCopy.markSurface(0));
    final centre = tester.getCenter(surface);
    final gesture = await tester.startGesture(centre);
    for (var i = 0; i < 8; i++) {
      await gesture.moveBy(const Offset(12, 6));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(HomeCareCopy.markSurface(1)), findsOneWidget);
    await tapText(tester, HomeCareCopy.markDone);
    expect(find.text(HomeCareCopy.markAgain), findsOneWidget);

    await tester.enterText(
      fieldLabelled(HomeCareCopy.jobTitle),
      'Grease on the oven door',
    );
    await tapText(tester, 'Kitchen');
    await tapText(tester, 'Thandi Helper');
    await tapText(tester, 'Jik');
    await tapText(tester, 'Put on gloves');
    await tapText(tester, HomeCareCopy.assign);

    final upload = harness.photos.writes.single.$2;
    expect(upload['photoId'], JobPhoto.beforeId);
    final (method, job) = harness.jobs.writes.single;
    expect(method, 'createJob');
    final details = job['details']! as JobDetails;
    expect(details.cleanTitle, 'Grease on the oven door');
    expect(details.roomId, 'kitchen');
    expect(details.helperId, Fixtures.thandiMemberId);
    expect(details.productIds, ['jik']);
    expect(details.steps.single.text, 'Put on gloves');
    expect(job['marks'], hasLength(1));
    expect((job['marks']! as List<SpotMark>).single.points, isNotEmpty);
  });

  testWidgets('choosing two products that must never meet warns first', (
    tester,
  ) async {
    await open(tester);
    await tapText(tester, 'Jik');
    await tapText(tester, 'Window spray');

    expect(find.text(HomeCareSafetyCopy.composerWarning), findsOneWidget);
    expect(
      find.text(HomeCareSafetyCopy.neverTogether('Jik', 'Window spray')),
      findsOneWidget,
    );
  });

  testWidgets('backing out of the circles keeps the ones there were', (
    tester,
  ) async {
    await open(tester);
    await tapText(tester, HomeCareCopy.takePhoto);
    await tapText(tester, HomeCareCopy.markSpot);
    await tester.tap(find.bySemanticsLabel(HomeCareCopy.markCancel));
    await tester.pumpAndSettle();
    expect(find.text(HomeCareCopy.markSpot), findsOneWidget);
  });

  testWidgets('a step can be written, and taken away again', (tester) async {
    await open(tester);
    final field = fieldLabelled(HomeCareCopy.addStep);
    await tester.ensureVisible(field);
    await tester.enterText(field, 'Rinse the tray');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Rinse the tray'), findsOneWidget);

    await tester.tap(
      find.bySemanticsLabel(HomeCareCopy.removeStep('Rinse the tray')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Rinse the tray'), findsNothing);
  });
}

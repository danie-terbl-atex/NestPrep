import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/home_care/model/job_event.dart';
import 'package:nestprep/features/home_care/model/job_status.dart';
import 'package:nestprep/features/home_care/model/safety/mixing_danger.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/home_care_fixtures.dart';
import '../../../support/pump_home_care.dart';

void main() {
  late HomeCareHarness harness;

  setUp(() {
    harness = HomeCareHarness();
    harness.photos.stored['oven/before'] = HomeCareFixtures.photoBytes;
  });
  tearDown(() => harness.close());

  Future<void> scrollTo(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(finder, 300);

  testWidgets('shows the spot, the facts, the safety first and the steps', (
    tester,
  ) async {
    HomeCareHarness.makeRoom(tester);
    await harness.pump(tester, location: HomeCareHarness.jobPath());
    await harness.emit(
      tester,
      jobList: [
        HomeCareFixtures.job(productIds: const ['jik', 'windolene']),
      ],
    );

    expect(find.text('Grease on the oven door'), findsOneWidget);
    expect(find.text('Kitchen'), findsOneWidget);
    expect(find.text('Thandi Helper'), findsOneWidget);
    expect(find.bySemanticsLabel(HomeCareCopy.beforePhoto), findsOneWidget);

    await scrollTo(
      tester,
      find.text(HomeCareSafetyCopy.neverTogether('Jik', 'Window spray')),
    );
    expect(
      find.text(HomeCareSafetyCopy.hazard(MixingHazard.chloramine)),
      findsOneWidget,
    );
    await scrollTo(tester, find.text('Wipe clean'));
    expect(find.text('Under the sink'), findsNothing);
    expect(find.textContaining('Under the sink'), findsOneWidget);
  });

  testWidgets('a parent can change a job still with the helper, or delete it', (
    tester,
  ) async {
    HomeCareHarness.makeRoom(tester);
    await harness.pump(tester, location: HomeCareHarness.jobPath());
    await harness.emit(tester);
    expect(find.text(HomeCareCopy.editJob), findsOneWidget);
    expect(find.text(HomeCareCopy.deleteJob), findsOneWidget);
    expect(find.text(HomeCareCopy.review), findsNothing);
  });

  testWidgets('deleting asks first, then removes the photo and the job', (
    tester,
  ) async {
    HomeCareHarness.makeRoom(tester);
    await harness.pump(tester, location: HomeCareHarness.jobPath());
    await harness.emit(tester);
    await tester.tap(find.text(HomeCareCopy.deleteJob));
    await tester.pumpAndSettle();
    await tester.tap(find.text(HomeCareCopy.deleteJob).last);
    await tester.pumpAndSettle();
    expect(harness.photos.methods, ['remove']);
    expect(harness.jobs.methods, ['deleteJob']);
  });

  testWidgets('a job handed in offers the parent a review', (tester) async {
    HomeCareHarness.makeRoom(tester);
    await harness.pump(tester, location: HomeCareHarness.jobPath());
    await harness.emit(tester, jobList: [HomeCareFixtures.handedIn()]);
    expect(find.text(HomeCareCopy.review), findsOneWidget);
    expect(find.text(HomeCareCopy.editJob), findsNothing);
    await tester.tap(find.text(HomeCareCopy.review));
    await tester.pumpAndSettle();
    expect(find.text(HomeCareCopy.reviewTitle), findsOneWidget);
  });

  testWidgets('the helper is offered her job to start, and nothing else', (
    tester,
  ) async {
    HomeCareHarness.makeRoom(tester);
    await harness.pump(
      tester,
      location: HomeCareHarness.jobPath(),
      view: HomeCareFixtures.helperView(),
    );
    await harness.emit(tester);
    expect(find.text(HomeCareCopy.start), findsOneWidget);
    expect(find.text(HomeCareCopy.editJob), findsNothing);
    expect(find.text(HomeCareCopy.deleteJob), findsNothing);
  });

  testWidgets('a job sent back shows the helper the note', (tester) async {
    HomeCareHarness.makeRoom(tester);
    await harness.pump(
      tester,
      location: HomeCareHarness.jobPath(),
      view: HomeCareFixtures.helperView(),
    );
    await harness.emit(
      tester,
      jobList: [
        HomeCareFixtures.job(
          status: JobStatus.sentBack,
          reviewNote: 'The corner is still greasy',
          revision: 3,
        ),
      ],
    );
    expect(
      find.text(HomeCareCopy.sentBackWith('The corner is still greasy')),
      findsOneWidget,
    );
    expect(find.text(HomeCareCopy.tryAgain), findsOneWidget);
  });

  testWidgets('once handed in, the helper is told it is waiting', (
    tester,
  ) async {
    HomeCareHarness.makeRoom(tester);
    await harness.pump(
      tester,
      location: HomeCareHarness.jobPath(),
      view: HomeCareFixtures.helperView(),
    );
    await harness.emit(tester, jobList: [HomeCareFixtures.handedIn()]);
    expect(find.text(HomeCareCopy.waitingForReview), findsOneWidget);
    expect(find.text(HomeCareCopy.start), findsNothing);
  });

  testWidgets('the history says who did what, with the send-back note', (
    tester,
  ) async {
    HomeCareHarness.makeRoom(tester);
    await harness.pump(tester, location: HomeCareHarness.jobPath());
    await harness.emit(tester);
    harness.jobs.emitEvents(const [
      JobEvent(id: '0', status: JobStatus.assigned, by: 'm-sam'),
      JobEvent(
        id: '1',
        status: JobStatus.sentBack,
        by: 'm-sam',
        note: 'Missed a bit',
      ),
    ]);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text(HomeCareCopy.quoted('Missed a bit')));
    expect(find.text(HomeCareCopy.byWhom('Sam Parent')), findsNWidgets(2));
  });

  testWidgets('a photo that will not load says so, and tries again', (
    tester,
  ) async {
    HomeCareHarness.makeRoom(tester);
    harness.photos.failReads['before'] = const UnavailableFailure();
    await harness.pump(tester, location: HomeCareHarness.jobPath());
    await harness.emit(tester);
    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    harness.photos.failReads.clear();
    harness.photos.stored['oven/before'] = Uint8List.fromList(
      HomeCareFixtures.photoBytes,
    );
    await tester.tap(find.text(AppCopy.retry));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(HomeCareCopy.beforePhoto), findsOneWidget);
  });

  testWidgets('a job deleted while it is open says so', (tester) async {
    HomeCareHarness.makeRoom(tester);
    await harness.pump(tester, location: HomeCareHarness.jobPath('gone'));
    await harness.emit(tester);
    expect(find.text(HomeCareCopy.jobGoneTitle), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/home_care/model/job_status.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/home_care_fixtures.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_home_care.dart';

void main() {
  late HomeCareHarness harness;

  setUp(() => harness = HomeCareHarness());
  tearDown(() => harness.close());

  testWidgets('holds the layout while it loads', (tester) async {
    await harness.pump(tester);
    await tester.pump();
    expect(find.text(HomeCareCopy.title), findsOneWidget);
    expect(find.text('Grease on the oven door'), findsNothing);
  });

  testWidgets(
    'a parent sees the piles, the jobs in them, and a way to start one',
    (tester) async {
      await harness.pump(tester);
      await harness.emit(
        tester,
        jobList: [
          HomeCareFixtures.job(),
          HomeCareFixtures.handedIn().copyWith(id: 'bath', title: 'Bath ring'),
        ],
      );

      expect(find.text('To do · 1'), findsOneWidget);
      expect(find.text('To review · 1'), findsOneWidget);
      expect(find.text('Done · 0'), findsOneWidget);
      expect(find.text('Grease on the oven door'), findsOneWidget);
      expect(find.text('Kitchen · Thandi Helper'), findsOneWidget);
      expect(
        find.text(HomeCareCopy.status(JobStatus.assigned)),
        findsOneWidget,
      );
      expect(find.text(HomeCareCopy.newJob), findsOneWidget);
      // The pile on show is the to-do pile; the handed-in job waits in its own.
      expect(find.text('Bath ring'), findsNothing);
    },
  );

  testWidgets('another pile is one tap, and the piles stay when it is empty', (
    tester,
  ) async {
    await harness.pump(tester);
    await harness.emit(tester);

    await tester.tap(find.text('Done · 0'));
    await tester.pumpAndSettle();
    expect(
      find.text(HomeCareCopy.emptyTitle(.done, isHelper: false)),
      findsOneWidget,
    );
    expect(find.text('To do · 1'), findsOneWidget);
  });

  testWidgets('an empty household says how to start, under the piles', (
    tester,
  ) async {
    await harness.pump(tester);
    await harness.emit(tester, jobList: const []);
    expect(
      find.text(HomeCareCopy.emptyBody(.toDo, isHelper: false)),
      findsOneWidget,
    );
    expect(find.text('To do · 0'), findsOneWidget);
  });

  testWidgets('a job opens on tap', (tester) async {
    await harness.pump(tester);
    await harness.emit(tester);
    await tester.tap(find.text('Grease on the oven door'));
    await tester.pumpAndSettle();
    expect(find.text(HomeCareCopy.jobTitleScreen), findsOneWidget);
  });

  testWidgets('a helper sees her own jobs, and no way to make one', (
    tester,
  ) async {
    await harness.pump(tester, view: HomeCareFixtures.helperView());
    await harness.emit(tester);

    expect(find.text(HomeCareCopy.yourJobs), findsOneWidget);
    expect(find.text(HomeCareCopy.newJob), findsNothing);
    expect(harness.jobs.jobsAskedFor.last, Fixtures.thandiMemberId);
  });

  testWidgets('says what went wrong in words, with a retry', (tester) async {
    await harness.pump(tester);
    harness.jobs.failJobsWith(const UnavailableFailure());
    await tester.pumpAndSettle();
    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    await tester.tap(find.text(AppCopy.retry));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await harness.emit(tester);
    expect(find.text('Grease on the oven door'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/home_care_route.dart';
import 'package:nestprep/features/home_care/model/job_photo.dart';
import 'package:nestprep/features/home_care/model/job_status.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/home_care_fixtures.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_home_care.dart';

/// The helper's step-through (home-care ADR-0001): the safety before the
/// first step, big tiles she ticks, and the after photo and hand-in once
/// every step is done.
void main() {
  late HomeCareHarness harness;
  final steps = HomeCareRoute.stepsPathFor(Fixtures.householdId, 'oven');

  setUp(() {
    harness = HomeCareHarness();
    harness.photos.stored['oven/before'] = HomeCareFixtures.photoBytes;
  });
  tearDown(() => harness.close());

  Future<void> open(WidgetTester tester, {List<String> done = const []}) async {
    HomeCareHarness.makeRoom(tester);
    await harness.pump(
      tester,
      location: steps,
      view: HomeCareFixtures.helperView(),
    );
    await harness.emit(
      tester,
      jobList: [
        HomeCareFixtures.job(
          productIds: const ['jik', 'windolene'],
          doneStepIds: done,
          status: done.isEmpty ? JobStatus.assigned : JobStatus.inProgress,
          revision: done.isEmpty ? 0 : 1,
        ),
      ],
    );
  }

  testWidgets('a job not yet started opens on its safety, loudest first', (
    tester,
  ) async {
    await open(tester);
    expect(find.text(HomeCareSafetyCopy.beforeYouStart), findsOneWidget);
    expect(
      find.text(HomeCareSafetyCopy.neverTogether('Jik', 'Window spray')),
      findsOneWidget,
    );
    expect(find.text('Wipe clean'), findsNothing);

    await tester.tap(find.text(HomeCareSafetyCopy.readIt));
    await tester.pumpAndSettle();
    expect(find.text('Wipe clean'), findsOneWidget);
  });

  testWidgets('a job already started opens on its steps', (tester) async {
    await open(tester, done: const ['s1']);
    expect(find.text(HomeCareSafetyCopy.beforeYouStart), findsNothing);
    expect(find.text(HomeCareCopy.stepsDone(1, 3)), findsOneWidget);
  });

  testWidgets('each step is one big tap, and says whether it is done', (
    tester,
  ) async {
    await open(tester, done: const ['s1']);
    expect(
      find.bySemanticsLabel(
        HomeCareCopy.stepForReader(1, 'Open a window', isDone: true),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Wipe clean'));
    await tester.pump();
    final (method, arguments) = harness.jobs.writes.single;
    expect(method, 'setDoneSteps');
    expect(arguments['doneStepIds'], ['s1', 's3']);
    expect(arguments['by'], Fixtures.thandiMemberId);
  });

  testWidgets('with a step left, it says to tick them all first', (
    tester,
  ) async {
    await open(tester, done: const ['s1']);
    expect(find.text(HomeCareCopy.tickEveryStep), findsOneWidget);
    expect(find.text(HomeCareCopy.handIn), findsNothing);
  });

  testWidgets('every step done: take the after photo, then hand it in', (
    tester,
  ) async {
    await open(tester, done: const ['s1', 's2', 's3']);
    expect(find.text(HomeCareCopy.afterPrompt), findsOneWidget);

    await tester.tap(find.text(HomeCareCopy.takePhoto));
    await tester.pumpAndSettle();
    await tester.tap(find.text(HomeCareCopy.handIn));
    await tester.pumpAndSettle();

    expect(harness.photos.writes.single.$2['photoId'], 'after-2');
    final (method, arguments) = harness.jobs.writes.single;
    expect(method, 'handIn');
    expect((arguments['afterPhoto']! as JobPhoto).photoId, 'after-2');
  });

  testWidgets('a refused camera is said in words', (tester) async {
    harness.camera.failWith = const HomeCareFailure(
      HomeCareProblem.cameraRefused,
    );
    await open(tester, done: const ['s1', 's2', 's3']);
    await tester.tap(find.text(HomeCareCopy.takePhoto));
    await tester.pumpAndSettle();
    expect(
      find.text(HomeCareCopy.problem(HomeCareProblem.cameraRefused)),
      findsOneWidget,
    );
  });
}

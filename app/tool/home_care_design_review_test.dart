import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nestprep/features/home_care/model/cleaning_job.dart';
import 'package:nestprep/features/home_care/model/home_care_board.dart';
import 'package:nestprep/features/home_care/model/job_event.dart';
import 'package:nestprep/features/home_care/model/job_photo.dart';
import 'package:nestprep/features/home_care/model/job_status.dart';
import 'package:nestprep/features/home_care/model/language/helper_language.dart';
import 'package:nestprep/features/home_care/state/home_care_controller.dart';
import 'package:nestprep/features/home_care/state/job_actions.dart';
import 'package:nestprep/features/home_care/state/job_controller.dart';
import 'package:nestprep/features/home_care/ui/home_care_screen.dart';
import 'package:nestprep/features/home_care/ui/job_screen.dart';
import 'package:nestprep/features/home_care/ui/review_screen.dart';
import 'package:nestprep/features/home_care/ui/step_through_screen.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/fake_home_care.dart';
import '../test/support/home_care_fixtures.dart';
import '../test/support/household_fixtures.dart';
import 'home_care_v2_press.dart';
import 'review_press.dart';

/// Home care in the design-review press: the job list, one job, the
/// helper's step-through and the parent's review, in both themes. Pictures
/// to look at rather than assertions:
///
///     flutter test tool/home_care_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  /// A worktop with a stain on it, and the same worktop clean — drawn, so
  /// the press needs no photo of anybody's kitchen.
  Uint8List worktop({required bool isStained, bool isPortrait = false}) {
    final width = isPortrait ? 600 : 800;
    final height = isPortrait ? 800 : 600;
    final image = img.Image(width: width, height: height);
    for (final pixel in image) {
      final grain = ((pixel.x ~/ 60) + (pixel.y ~/ 60)).isEven ? 8 : 0;
      pixel
        ..r = 214 + grain
        ..g = 204 + grain
        ..b = 188 + grain;
    }
    if (isStained) {
      img.fillCircle(
        image,
        x: width * 3 ~/ 5,
        y: height * 2 ~/ 5,
        radius: 70,
        color: img.ColorRgb8(138, 98, 58),
      );
      img.fillCircle(
        image,
        x: width * 3 ~/ 5 + 60,
        y: height * 2 ~/ 5 + 40,
        radius: 36,
        color: img.ColorRgb8(120, 84, 48),
      );
    }
    return Uint8List.fromList(img.encodeJpg(image));
  }

  final jobs = [
    HomeCareFixtures.job(
      status: JobStatus.inProgress,
      productIds: const ['jik', 'windolene'],
      doneStepIds: const ['s1'],
      revision: 1,
    ),
    HomeCareFixtures.job(
      id: 'bath',
      title: 'Ring round the bath',
      productIds: const ['sunlight'],
    ).copyWith(roomId: 'bathroom'),
    HomeCareFixtures.handedIn().copyWith(
      id: 'windows',
      title: 'Lounge windows',
    ),
  ];

  Future<void> press(
    WidgetTester tester,
    String name, {
    required Widget screen,
    required Brightness brightness,
    required CleaningJob job,
    HouseholdView? view,
    HelperLanguage language = HelperLanguage.english,
  }) async {
    final jobRepository = FakeCleaningJobRepository();
    final library = FakeHomeCareLibraryRepository();
    final photos = FakeJobPhotoStore()
      ..stored['${job.id}/before'] = worktop(isStained: true)
      ..stored['${job.id}/after-2'] = worktop(
        isStained: false,
        isPortrait: true,
      );
    addTearDown(jobRepository.close);
    addTearDown(library.close);
    final householdView = view ?? Fixtures.view();
    final home = HomeCareController(
      jobRepository: jobRepository,
      libraryRepository: library,
      householdId: Fixtures.householdId,
      household: householdView,
    );
    addTearDown(home.dispose);
    final one = JobController(
      jobRepository: jobRepository,
      photoStore: photos,
      householdId: Fixtures.householdId,
      jobId: job.id,
      actions: (controller) => JobActions(
        controller: controller,
        jobRepository: jobRepository,
        photoStore: photos,
        photoIntake: fakePhotoIntake(FakePhotoSource()),
        memberId: Fixtures.samMemberId,
        viewerUid: Fixtures.samUid,
      ),
    );
    addTearDown(one.dispose);
    final v2 = HomeCareV2Press(home);
    addTearDown(v2.close);

    await captureScreen(
      tester,
      name,
      screen: screen,
      providers: [
        ChangeNotifierProvider<HomeCareController>.value(value: home),
        ChangeNotifierProvider<JobController>.value(value: one),
        ...v2.providers,
      ],
      brightness: brightness,
      view: householdView,
      emit: () async {
        jobRepository.emitJobs([
          for (final each in jobs) each.id == job.id ? job : each,
        ]);
        library.emitRooms([
          HomeCareFixtures.kitchen,
          HomeCareFixtures.bathroom,
        ]);
        library.emitProducts(const [
          HomeCareFixtures.bleach,
          HomeCareFixtures.glassCleaner,
          HomeCareFixtures.soap,
        ]);
        jobRepository.emitEvents(const [
          JobEvent(id: '0', status: JobStatus.assigned, by: 'm-sam'),
          JobEvent(id: '1', status: JobStatus.inProgress, by: 'm-thandi'),
        ]);
        v2.speak(language);
        await tester.pump();
        v2.listen();
        one.followBoard(home.board);
        // The photos decode off the test's clock.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
      },
    );
  }

  for (final brightness in Brightness.values) {
    testWidgets('home care — ${brightness.name}', (tester) async {
      await press(
        tester,
        'home-care-${brightness.name}',
        screen: const HomeCareScreen(pile: JobPile.toDo),
        brightness: brightness,
        job: jobs.first,
      );
    });

    testWidgets('a cleaning job — ${brightness.name}', (tester) async {
      await press(
        tester,
        'home-care-job-${brightness.name}',
        screen: const JobScreen(),
        brightness: brightness,
        job: jobs.first,
      );
    });

    testWidgets('the helper’s steps — ${brightness.name}', (tester) async {
      await press(
        tester,
        'home-care-steps-${brightness.name}',
        screen: const StepThroughScreen(),
        brightness: brightness,
        job: jobs.first,
        view: HomeCareFixtures.helperView(),
        language: HelperLanguage.isiZulu,
      );
    });

    testWidgets('the review — ${brightness.name}', (tester) async {
      await press(
        tester,
        'home-care-review-${brightness.name}',
        screen: const ReviewScreen(),
        brightness: brightness,
        job: HomeCareFixtures.handedIn().copyWith(
          afterPhoto: const JobPhoto(
            photoId: 'after-2',
            width: 600,
            height: 800,
          ),
        ),
      );
    });
  }
}

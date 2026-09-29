import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/home_care/data/photo_source.dart';
import 'package:nestprep/features/home_care/model/cleaning_job.dart';
import 'package:nestprep/features/home_care/model/home_care_board.dart';
import 'package:nestprep/features/home_care/model/job_details.dart';
import 'package:nestprep/features/home_care/model/job_event.dart';
import 'package:nestprep/features/home_care/model/job_photo.dart';
import 'package:nestprep/features/home_care/model/job_status.dart';
import 'package:nestprep/features/home_care/state/job_actions.dart';
import 'package:nestprep/features/home_care/state/job_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_home_care.dart';
import '../../../support/home_care_fixtures.dart';
import '../../../support/household_fixtures.dart';

void main() {
  late FakeCleaningJobRepository jobs;
  late FakeJobPhotoStore photos;
  late FakePhotoSource camera;
  late JobController controller;

  setUp(() {
    jobs = FakeCleaningJobRepository();
    photos = FakeJobPhotoStore()
      ..stored['oven/before'] = Uint8List.fromList([1, 2, 3]);
    camera = FakePhotoSource()..next = HomeCareFixtures.photoBytes;
    controller = JobController(
      jobRepository: jobs,
      photoStore: photos,
      householdId: Fixtures.householdId,
      jobId: 'oven',
      actions: (controller) => JobActions(
        controller: controller,
        jobRepository: jobs,
        photoStore: photos,
        photoIntake: fakePhotoIntake(camera),
        memberId: Fixtures.thandiMemberId,
        viewerUid: Fixtures.thandiUid,
      ),
    );
  });

  tearDown(() async {
    controller.dispose();
    await jobs.close();
  });

  AsyncState<HomeCareBoard> boardWith(CleaningJob job) => AsyncData(
    HomeCareBoard(
      jobs: [job],
      rooms: [HomeCareFixtures.kitchen],
      products: const [HomeCareFixtures.bleach],
      members: Fixtures.view().members,
    ),
  );

  Future<void> follow(CleaningJob job) async {
    controller.followBoard(boardWith(job));
    await pumpEventQueue();
  }

  group('reading', () {
    test(
      'reads the before photo once the job is known, and only once',
      () async {
        expect(controller.photo('before'), isA<AsyncLoading<Uint8List>>());
        await follow(HomeCareFixtures.job());
        await follow(HomeCareFixtures.job(doneStepIds: const ['s1']));
        expect((controller.photo('before') as AsyncData<Uint8List>).value, [
          1,
          2,
          3,
        ]);
      },
    );

    test('reads the after photo when a hand-in names one', () async {
      photos.stored['oven/after-2'] = Uint8List.fromList([9]);
      await follow(HomeCareFixtures.handedIn());
      expect(controller.photo('after-2'), isA<AsyncData<Uint8List>>());
    });

    test(
      'a photo that will not load says so, and can be tried again',
      () async {
        photos.failReads['before'] = const UnavailableFailure();
        await follow(HomeCareFixtures.job());
        expect(controller.photo('before'), isA<AsyncFailure<Uint8List>>());
        photos.failReads.clear();
        await controller.retryPhoto('before');
        expect(controller.photo('before'), isA<AsyncData<Uint8List>>());
      },
    );

    test(
      'the history arrives oldest first as the repository sends it',
      () async {
        jobs.emitEvents(const [
          JobEvent(id: '0', status: JobStatus.assigned, by: 'm-sam'),
          JobEvent(id: '1', status: JobStatus.inProgress, by: 'm-thandi'),
        ]);
        await pumpEventQueue();
        final events = (controller.events as AsyncData<List<JobEvent>>).value;
        expect(events.map((event) => event.revision), [0, 1]);
      },
    );

    test('a history that fails can be read again', () async {
      jobs.failEventsWith(const UnavailableFailure());
      await pumpEventQueue();
      expect(controller.events, isA<AsyncFailure<List<JobEvent>>>());
      await controller.retryHistory();
      expect(controller.events, isA<AsyncLoading<List<JobEvent>>>());
    });

    test('knows no job before the board has loaded', () {
      expect(controller.currentJob, isNull);
    });
  });

  group('the helper', () {
    test('ticks a step, and unticks it', () async {
      await follow(HomeCareFixtures.job(doneStepIds: const ['s1']));
      await controller.actions.toggleStep('s2');
      await controller.actions.toggleStep('s1');
      expect(
        [for (final write in jobs.writes) write.$2['doneStepIds']],
        [
          ['s1', 's2'],
          <String>[],
        ],
      );
      expect(jobs.writes.first.$2['by'], Fixtures.thandiMemberId);
    });

    test('cannot tick a job once it is handed in', () async {
      await follow(HomeCareFixtures.handedIn());
      await controller.actions.toggleStep('s1');
      expect(jobs.writes, isEmpty);
    });

    test(
      'hands in: the after photo under the next revision, then the job',
      () async {
        await follow(
          HomeCareFixtures.job(
            status: JobStatus.inProgress,
            revision: 1,
            doneStepIds: const ['s1', 's2', 's3'],
          ),
        );
        await controller.actions.takeAfterPhoto(PhotoOrigin.camera);
        expect(controller.actions.afterPhoto, isNotNull);
        expect(await controller.actions.handIn(), isTrue);

        expect(photos.writes.single.$2['photoId'], 'after-2');
        expect(photos.writes.single.$2['uploaderUid'], Fixtures.thandiUid);
        final handIn = jobs.writes.single;
        expect(handIn.$1, 'handIn');
        expect((handIn.$2['afterPhoto']! as JobPhoto).photoId, 'after-2');
        expect(controller.actions.afterPhoto, isNull);
      },
    );

    test('will not hand in with a step left, and says why', () async {
      await follow(HomeCareFixtures.job(doneStepIds: const ['s1']));
      await controller.actions.takeAfterPhoto(PhotoOrigin.camera);
      expect(await controller.actions.handIn(), isFalse);
      expect(
        controller.actionFailure,
        const TypeMatcher<HomeCareFailure>().having(
          (failure) => failure.problem,
          'problem',
          HomeCareProblem.stepsNotDone,
        ),
      );
      expect(photos.writes, isEmpty);
    });

    test('will not hand in without an after photo', () async {
      await follow(HomeCareFixtures.job(doneStepIds: const ['s1', 's2', 's3']));
      expect(await controller.actions.handIn(), isFalse);
      expect(jobs.writes, isEmpty);
    });
  });

  group('the parent', () {
    test('approves a job that was handed in', () async {
      await follow(HomeCareFixtures.handedIn());
      expect(await controller.actions.approve(), isTrue);
      expect(jobs.methods, ['approve']);
    });

    test('sends it back with the note trimmed', () async {
      await follow(HomeCareFixtures.handedIn());
      expect(await controller.actions.sendBack('  The corner  '), isTrue);
      expect(jobs.writes.single.$2['note'], 'The corner');
    });

    test('cannot review a job nobody has handed in', () async {
      await follow(HomeCareFixtures.job());
      expect(await controller.actions.approve(), isFalse);
      expect(jobs.writes, isEmpty);
    });

    test('changes the details, but only complete ones', () async {
      await follow(HomeCareFixtures.job());
      final details = JobDetails.of(HomeCareFixtures.job());
      expect(await controller.actions.updateDetails(details), isTrue);
      expect(
        await controller.actions.updateDetails(details.copyWith(title: ' ')),
        isFalse,
      );
      expect(jobs.methods, ['updateDetails']);
    });

    test('deletes every photo the job ever had, then the job', () async {
      jobs.emitEvents(const [
        JobEvent(id: '0', status: JobStatus.assigned, by: 'm-sam'),
        JobEvent(id: '2', status: JobStatus.submitted, by: 'm-thandi'),
        JobEvent(id: '3', status: JobStatus.sentBack, by: 'm-sam'),
        JobEvent(id: '5', status: JobStatus.submitted, by: 'm-thandi'),
      ]);
      await follow(
        HomeCareFixtures.job(
          status: JobStatus.submitted,
          revision: 5,
          afterPhoto: const JobPhoto(photoId: 'after-5', width: 1, height: 1),
        ),
      );
      photos.failRemoves['after-2'] = const NotFoundFailure();
      expect(await controller.actions.delete(), isTrue);
      expect(
        [for (final write in photos.writes) write.$2['photoId']],
        ['before', 'after-5'],
      );
      expect(jobs.methods, ['deleteJob']);
    });

    test('a photo that will not delete stops the job being deleted', () async {
      await follow(HomeCareFixtures.job());
      photos.failRemoves['before'] = const PermissionDeniedFailure();
      expect(await controller.actions.delete(), isFalse);
      expect(controller.actionFailure, isA<PermissionDeniedFailure>());
      expect(jobs.writes, isEmpty);
      expect(controller.actions.isBusy, isFalse);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/home_care/data/photo_source.dart';
import 'package:nestprep/features/home_care/model/job_details.dart';
import 'package:nestprep/features/home_care/model/job_photo.dart';
import 'package:nestprep/features/home_care/model/spot_mark.dart';
import 'package:nestprep/features/home_care/state/job_composer_controller.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/fake_home_care.dart';
import '../../../support/home_care_fixtures.dart';
import '../../../support/household_fixtures.dart';

void main() {
  late FakeCleaningJobRepository jobs;
  late FakeJobPhotoStore photos;
  late FakePhotoSource camera;
  late JobComposerController composer;
  final today = CalendarDate(2026, 10, 1);

  setUp(() {
    jobs = FakeCleaningJobRepository();
    photos = FakeJobPhotoStore();
    camera = FakePhotoSource()..next = HomeCareFixtures.photoBytes;
    composer = JobComposerController(
      jobRepository: jobs,
      photoStore: photos,
      photoIntake: fakePhotoIntake(camera),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      viewerUid: Fixtures.samUid,
      today: today,
    );
  });

  tearDown(() async {
    composer.dispose();
    await jobs.close();
  });

  JobDetails complete() => JobDetails(
    dueDate: today,
    title: 'Oven door',
    roomId: 'kitchen',
    helperId: Fixtures.thandiMemberId,
  ).withStepAdded('Wipe');

  test('starts due today, with nothing to complain about yet', () {
    expect(composer.details.dueDate, today);
    expect(composer.shownProblems, isEmpty);
    expect(composer.isMissingPhoto, isFalse);
  });

  test('takes a photo, and a new photo loses the old circles', () async {
    await composer.takePhoto(PhotoOrigin.camera);
    expect(composer.photo, isNotNull);
    composer.setMarks(const [
      SpotMark(points: [0.1, 0.1]),
    ]);
    await composer.takePhoto(PhotoOrigin.gallery);
    expect(composer.marks, isEmpty);
    expect(camera.asked, [PhotoOrigin.camera, PhotoOrigin.gallery]);
  });

  test('backing out of the camera keeps the photo there was', () async {
    await composer.takePhoto(PhotoOrigin.camera);
    camera.next = null;
    await composer.takePhoto(PhotoOrigin.camera);
    expect(composer.photo, isNotNull);
  });

  test('a refused camera is said in words', () async {
    camera.failWith = const HomeCareFailure(HomeCareProblem.cameraRefused);
    await composer.takePhoto(PhotoOrigin.camera);
    expect(composer.actionFailure, isA<HomeCareFailure>());
    expect(composer.isTakingPhoto, isFalse);
  });

  test('keeps no more circles than the rules do', () {
    composer.setMarks([
      for (var i = 0; i < 30; i++) const SpotMark(points: [0.5, 0.5]),
    ]);
    expect(composer.marks, hasLength(SpotMark.limit));
  });

  test('will not assign without a photo, and says what is missing', () async {
    composer.updateDetails((_) => JobDetails(dueDate: today));
    expect(await composer.assign(), isFalse);
    expect(composer.isMissingPhoto, isTrue);
    expect(composer.shownProblems, JobDetailsProblem.values);
    expect(photos.writes, isEmpty);
    expect(jobs.writes, isEmpty);
  });

  test('stores the photo first, then the job that names it', () async {
    await composer.takePhoto(PhotoOrigin.camera);
    composer
      ..updateDetails((_) => complete())
      ..setMarks(const [
        SpotMark(points: [0.2, 0.3]),
      ]);
    expect(await composer.assign(), isTrue);

    final upload = photos.writes.single.$2;
    expect(upload['photoId'], JobPhoto.beforeId);
    expect(upload['uploaderUid'], Fixtures.samUid);
    final (method, job) = jobs.writes.single;
    expect(method, 'createJob');
    expect(job['jobId'], upload['jobId']);
    expect(job['createdBy'], Fixtures.samMemberId);
    expect((job['beforePhoto']! as JobPhoto).photoId, 'before');
    expect(job['marks'], hasLength(1));
  });

  test('a refused job takes its orphaned photo back out', () async {
    await composer.takePhoto(PhotoOrigin.camera);
    composer.updateDetails((_) => complete());
    jobs.failWritesWith = const PermissionDeniedFailure();
    expect(await composer.assign(), isFalse);
    expect(composer.actionFailure, isA<PermissionDeniedFailure>());
    expect(photos.methods, ['upload', 'remove']);
    expect(composer.isSaving, isFalse);
  });

  test('a refused photo never becomes a job', () async {
    await composer.takePhoto(PhotoOrigin.camera);
    composer.updateDetails((_) => complete());
    photos.failWritesWith = const PermissionDeniedFailure();
    expect(await composer.assign(), isFalse);
    expect(jobs.writes, isEmpty);
  });
}

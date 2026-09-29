import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/home_care/model/job_details.dart';
import 'package:nestprep/features/home_care/model/job_status.dart';
import 'package:nestprep/features/home_care/model/job_step.dart';
import 'package:nestprep/features/home_care/model/spot_mark.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/home_care_fixtures.dart';

void main() {
  group('a job’s checklist', () {
    test('counts only ticks for steps the job still has', () {
      final job = HomeCareFixtures.job(doneStepIds: const ['s1', 'gone']);
      expect(job.doneCount, 1);
      expect(job.areAllStepsDone, isFalse);
      expect(job.progress, closeTo(1 / 3, 0.001));
    });

    test('is done when every step is ticked', () {
      final job = HomeCareFixtures.job(doneStepIds: const ['s1', 's2', 's3']);
      expect(job.areAllStepsDone, isTrue);
      expect(job.progress, 1);
    });

    test('names the next hand-in’s photo for the revision it will make', () {
      expect(HomeCareFixtures.job(revision: 4).nextAfterPhotoId, 'after-5');
    });

    test('is late only while it is still with the helper', () {
      final today = CalendarDate(2026, 10, 3);
      final due = CalendarDate(2026, 10, 2);
      expect(HomeCareFixtures.job(dueDate: due).isOverdue(today), isTrue);
      expect(
        HomeCareFixtures.job(
          dueDate: due,
          status: JobStatus.submitted,
        ).isOverdue(today),
        isFalse,
      );
      expect(HomeCareFixtures.job(dueDate: due).isOverdue(due), isFalse);
    });
  });

  group('the statuses', () {
    test('with the helper, waiting, and done are three separate piles', () {
      expect(
        [
          for (final s in JobStatus.values)
            if (s.isWithHelper) s,
        ],
        [JobStatus.assigned, JobStatus.inProgress, JobStatus.sentBack],
      );
      expect(JobStatus.submitted.isWaitingForReview, isTrue);
      expect(JobStatus.approved.isDone, isTrue);
    });
  });

  group('what a parent writes', () {
    final today = CalendarDate(2026, 10, 1);

    test('says everything that is missing, and nothing once it is there', () {
      final empty = JobDetails(dueDate: today);
      expect(empty.problems, JobDetailsProblem.values);
      final full = empty
          .copyWith(title: ' Oven ', roomId: 'kitchen', helperId: 'm2')
          .withStepAdded('Wipe');
      expect(full.problems, isEmpty);
      expect(full.cleanTitle, 'Oven');
    });

    test('a blank title is no title', () {
      expect(
        JobDetails(dueDate: today, title: '   ').problems,
        contains(JobDetailsProblem.noTitle),
      );
    });

    test('gives every new step an id no other step has', () {
      final details = JobDetails(
        dueDate: today,
        steps: const [JobStep(id: 's2', text: 'Already here')],
      ).withStepAdded('One').withStepAdded('Two');
      final ids = details.steps.map((step) => step.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(details.steps.last.text, 'Two');
    });

    test('ignores a blank step, and removes one by its id', () {
      final details = JobDetails(dueDate: today).withStepAdded('  ');
      expect(details.steps, isEmpty);
      final one = details.withStepAdded('Wipe');
      expect(one.withoutStep(one.steps.single.id).steps, isEmpty);
    });

    test('toggles a product in and out', () {
      final details = JobDetails(dueDate: today).withProductToggled('jik');
      expect(details.productIds, ['jik']);
      expect(details.withProductToggled('jik').productIds, isEmpty);
    });

    test('an empty note is no note', () {
      expect(JobDetails(dueDate: today, note: '  ').cleanNote, isNull);
      expect(JobDetails(dueDate: today, note: ' Seal ').cleanNote, 'Seal');
    });
  });

  group('a circle round the spot', () {
    test('is kept as a share of the photo, inside it', () {
      final mark = SpotMark.fromOffsets(const [
        Offset(50, 25),
        Offset(-10, 400),
      ], const Size(100, 100));
      expect(mark.points, [0.5, 0.25, 0.0, 1.0]);
    });

    test('lands in the same place at any size', () {
      const mark = SpotMark(points: [0.5, 0.25]);
      expect(mark.offsetsIn(const Size(200, 400)), [const Offset(100, 100)]);
    });

    test('is thinned to a few hundred points however long the scribble', () {
      final mark = SpotMark.fromOffsets([
        for (var i = 0; i < 5000; i++) Offset(i / 50, i / 50),
      ], const Size(100, 100));
      expect(mark.points.length ~/ 2, lessThanOrEqualTo(SpotMark.pointLimit));
    });
  });
}

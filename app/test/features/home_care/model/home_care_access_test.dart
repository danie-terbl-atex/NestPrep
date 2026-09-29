import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/home_care/model/home_care_access.dart';
import 'package:nestprep/features/home_care/model/home_care_board.dart';
import 'package:nestprep/features/home_care/model/job_status.dart';

import '../../../support/home_care_fixtures.dart';
import '../../../support/home_care_routine_fixtures.dart';
import '../../../support/household_fixtures.dart';

/// The client's mirror of `home_care.rules` (home-care ADR-0001). It decides
/// nothing — the rules tests prove the refusals — but a button it shows is
/// a button the rules will honour.
void main() {
  group('family', () {
    final access = HomeCareAccess.of(Fixtures.view());

    test('manages everything and reads every job', () {
      expect(access.canManage, isTrue);
      expect(access.jobScope, isNull);
    });

    test('ticks anybody’s routine and sets anybody’s language', () {
      expect(
        access.canTickRoutine(RoutineFixtures.everyDay(helperId: 'm-gogo')),
        isTrue,
      );
      expect(access.canSetLanguageOf(Fixtures.thandiMemberId), isTrue);
    });

    test('reviews what was handed in, and changes what was not', () {
      expect(access.canReview(HomeCareFixtures.handedIn()), isTrue);
      expect(access.canChangeDetails(HomeCareFixtures.job()), isTrue);
      expect(access.canChangeDetails(HomeCareFixtures.handedIn()), isFalse);
    });
  });

  group('a helper on her defaults (`own`)', () {
    final access = HomeCareAccess.of(HomeCareFixtures.helperView());

    test('ticks her own room routines and sets her own language only', () {
      expect(access.canTickRoutine(RoutineFixtures.everyDay()), isTrue);
      expect(
        access.canTickRoutine(RoutineFixtures.everyDay(helperId: 'm-gogo')),
        isFalse,
      );
      expect(access.canSetLanguageOf(Fixtures.thandiMemberId), isTrue);
      expect(access.canSetLanguageOf(Fixtures.samMemberId), isFalse);
    });

    test('asks for exactly her own jobs, because a rule is not a filter', () {
      expect(access.jobScope, Fixtures.thandiMemberId);
      expect(access.canManage, isFalse);
    });

    test('works her own job, and not somebody else’s', () {
      expect(access.canWork(HomeCareFixtures.job()), isTrue);
      expect(
        access.canWork(HomeCareFixtures.job(helperId: Fixtures.samMemberId)),
        isFalse,
      );
    });

    test('cannot work a job once it is handed in, nor review it', () {
      final handedIn = HomeCareFixtures.handedIn();
      expect(access.canWork(handedIn), isFalse);
      expect(access.canReview(handedIn), isFalse);
    });
  });

  test('a helper who may look reads every job and works only her own', () {
    final access = HomeCareAccess.of(HomeCareFixtures.lookingHelperView());
    expect(access.jobScope, isNull);
    expect(access.canWork(HomeCareFixtures.job()), isTrue);
    expect(
      access.canWork(HomeCareFixtures.job(helperId: Fixtures.samMemberId)),
      isFalse,
    );
  });

  test('a helper with no home care does not see it at all', () {
    final access = HomeCareAccess.of(HomeCareFixtures.noCleaningView());
    expect(access.isVisible, isFalse);
    expect(access.canWork(HomeCareFixtures.job()), isFalse);
  });

  test('a job can be given to helpers first, then family, never a kid', () {
    final helpers = HomeCareAccess.helpersIn(Fixtures.view());
    expect(helpers.map((member) => member.id), [
      Fixtures.thandiMemberId,
      Fixtures.samMemberId,
    ]);
  });

  group('the board', () {
    final board = HomeCareBoard(
      jobs: [
        HomeCareFixtures.job(id: 'late', status: JobStatus.inProgress),
        HomeCareFixtures.handedIn(),
        HomeCareFixtures.job(id: 'done', status: JobStatus.approved),
        HomeCareFixtures.job(id: 'back', status: JobStatus.sentBack),
      ],
      rooms: [HomeCareFixtures.kitchen],
      products: const [HomeCareFixtures.bleach],
      members: Fixtures.view().members,
    );

    test('sorts jobs into three piles', () {
      expect(board.countIn(JobPile.toDo), 2);
      expect(board.countIn(JobPile.toReview), 1);
      expect(board.countIn(JobPile.done), 1);
      expect(board.jobsIn(JobPile.done).single.id, 'done');
    });

    test('leaves out a product that has left the library', () {
      final job = HomeCareFixtures.job(productIds: const ['jik', 'gone']);
      expect(board.productsOf(job).map((p) => p.id), ['jik']);
    });

    test('counts the open jobs in a room', () {
      expect(board.openJobsIn(HomeCareFixtures.kitchen.id), 3);
      expect(board.roomById('nowhere'), isNull);
    });
  });
}

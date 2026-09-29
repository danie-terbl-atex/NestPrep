import 'package:nestprep/features/home_care/model/cleaning_job.dart';
import 'package:nestprep/features/home_care/model/home_care_product.dart';
import 'package:nestprep/features/home_care/model/home_care_room.dart';
import 'package:nestprep/features/home_care/model/job_event.dart';
import 'package:nestprep/features/home_care/model/job_photo.dart';
import 'package:nestprep/features/home_care/model/job_status.dart';
import 'package:nestprep/features/home_care/model/job_step.dart';
import 'package:nestprep/features/home_care/model/language/helper_language.dart';
import 'package:nestprep/features/home_care/model/language/helper_profile.dart';
import 'package:nestprep/features/home_care/model/product_kind.dart';
import 'package:nestprep/features/home_care/model/room_kind.dart';
import 'package:nestprep/features/home_care/model/routine/room_routine.dart';
import 'package:nestprep/features/home_care/model/routine/routine_cadence.dart';
import 'package:nestprep/features/home_care/model/routine/routine_tick.dart';
import 'package:nestprep/features/home_care/model/spot_mark.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import 'model_fixtures.dart';

/// Home care's seven stored models (four from phase 1, three from V2), each with every field filled — spread
/// into `modelFixtures()` so the round-trip and encodability tests reach
/// them (home-care ADR-0001). The job nests steps, photos and marks, which is
/// exactly what the nested-model lesson is about.
List<ModelFixture> homeCareModelFixtures() {
  final at = fixtureInstant;
  final room = HomeCareRoom(
    id: 'kitchen',
    name: 'Kitchen',
    kind: RoomKind.kitchen,
    createdBy: 'm1',
    createdAt: at,
  );
  final product = HomeCareProduct(
    id: 'jik',
    name: 'Jik',
    kind: ProductKind.bleach,
    whereKept: 'Under the sink',
    note: 'The big bottle',
    keepFromChildren: true,
    keepFromPets: true,
    createdBy: 'm1',
    createdAt: at,
  );
  final job = CleaningJob(
    id: 'oven',
    title: 'Oven door',
    roomId: 'kitchen',
    helperId: 'm2',
    dueDate: CalendarDate(2026, 10, 2),
    note: 'Mind the seal',
    productIds: const ['jik'],
    steps: const [
      JobStep(id: 's1', text: 'Open a window'),
      JobStep(id: 's2', text: 'Wipe'),
    ],
    doneStepIds: const ['s1'],
    beforePhoto: const JobPhoto(photoId: 'before', width: 1600, height: 1200),
    marks: const [
      SpotMark(points: [0.1, 0.2, 0.3, 0.4]),
    ],
    afterPhoto: const JobPhoto(photoId: 'after-2', width: 1200, height: 1600),
    status: JobStatus.sentBack,
    reviewNote: 'The corner',
    revision: 3,
    createdBy: 'm1',
    createdAt: at,
    updatedAt: at,
  );
  final event = JobEvent(
    id: '3',
    status: JobStatus.sentBack,
    by: 'm1',
    note: 'The corner',
    at: at,
  );
  final routine = RoomRoutine(
    id: 'kitchen-daily',
    name: 'Kitchen, every weekday',
    roomId: 'kitchen',
    cadence: RoutineCadence.daily,
    items: const [JobStep(id: 'i1', text: 'Wipe the counters')],
    helperId: 'm2',
    firstDate: CalendarDate(2026, 9, 28),
    recurrence: RoutineCadence.daily.ruleFrom(CalendarDate(2026, 9, 28)),
    createdBy: 'm1',
    createdAt: at,
  );
  final tick = RoutineTick(
    id: RoutineTick.idFor('kitchen-daily', CalendarDate(2026, 9, 29)),
    routineId: 'kitchen-daily',
    occurrenceDate: CalendarDate(2026, 9, 29),
    helperId: 'm2',
    doneItemIds: const ['i1'],
    updatedBy: 'm2',
    updatedAt: at,
  );
  final profile = HelperProfile(
    id: 'm2',
    language: HelperLanguage.isiZulu,
    updatedBy: 'm2',
    updatedAt: at,
  );
  return [
    ModelFixture(
      label: 'RoomRoutine',
      id: routine.id,
      value: routine,
      toJson: routine.toJson,
      fromJson: RoomRoutine.fromJson,
      keys: const {
        'name',
        'roomId',
        'cadence',
        'items',
        'helperId',
        'firstDate',
        'recurrence',
        'createdBy',
        'createdAt',
      },
      note:
          'exactly what `home_care_routines.rules` lets a routine be made '
          'with; the items and the rule are nested maps (home-care ADR-0004).',
    ),
    ModelFixture(
      label: 'RoutineTick',
      id: tick.id,
      value: tick,
      toJson: tick.toJson,
      fromJson: RoutineTick.fromJson,
      keys: const {
        'routineId',
        'occurrenceDate',
        'helperId',
        'doneItemIds',
        'updatedBy',
        'updatedAt',
      },
      note: 'the id is `{routineId}_{date}`, which the rules compare.',
    ),
    ModelFixture(
      label: 'HelperProfile',
      id: profile.id,
      value: profile,
      toJson: profile.toJson,
      fromJson: HelperProfile.fromJson,
      keys: const {'language', 'updatedBy', 'updatedAt'},
      note: 'the language is stored by its code, which the rules list.',
    ),
    ModelFixture(
      label: 'HomeCareRoom',
      id: room.id,
      value: room,
      toJson: room.toJson,
      fromJson: HomeCareRoom.fromJson,
      keys: const {'name', 'kind', 'createdBy', 'createdAt'},
    ),
    ModelFixture(
      label: 'HomeCareProduct',
      id: product.id,
      value: product,
      toJson: product.toJson,
      fromJson: HomeCareProduct.fromJson,
      keys: const {
        'name',
        'kind',
        'whereKept',
        'note',
        'keepFromChildren',
        'keepFromPets',
        'createdBy',
        'createdAt',
      },
      note: 'the kind is what the safety catalogue reads (home-care ADR-0002).',
    ),
    ModelFixture(
      label: 'CleaningJob',
      id: job.id,
      value: job,
      toJson: job.toJson,
      fromJson: CleaningJob.fromJson,
      keys: const {
        'title',
        'roomId',
        'helperId',
        'dueDate',
        'note',
        'productIds',
        'steps',
        'doneStepIds',
        'beforePhoto',
        'marks',
        'afterPhoto',
        'status',
        'reviewNote',
        'revision',
        'createdBy',
        'createdAt',
        'updatedAt',
      },
      note:
          'exactly the keys `home_care.rules` lets a job be created with; the '
          'steps, photos and marks are nested maps, never models.',
    ),
    ModelFixture(
      label: 'JobEvent',
      id: event.id,
      value: event,
      toJson: event.toJson,
      fromJson: JobEvent.fromJson,
      keys: const {'status', 'by', 'note', 'at'},
      note: 'the revision is the document id, which the rules compare.',
    ),
  ];
}

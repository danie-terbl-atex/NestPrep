import 'package:nestprep/features/nanny_hub/model/care_routine.dart';
import 'package:nestprep/features/nanny_hub/model/checklist_item.dart';
import 'package:nestprep/features/nanny_hub/model/checklist_progress.dart';
import 'package:nestprep/features/nanny_hub/model/child_card.dart';
import 'package:nestprep/features/nanny_hub/model/contact_kind.dart';
import 'package:nestprep/features/nanny_hub/model/emergency_contact.dart';
import 'package:nestprep/features/nanny_hub/model/guide_spot.dart';
import 'package:nestprep/features/nanny_hub/model/handover_entry.dart';
import 'package:nestprep/features/nanny_hub/model/handover_kind.dart';
import 'package:nestprep/features/nanny_hub/model/handover_mood.dart';
import 'package:nestprep/features/nanny_hub/model/home_sheet.dart';
import 'package:nestprep/features/nanny_hub/model/house_rule.dart';
import 'package:nestprep/features/nanny_hub/model/shift.dart';
import 'package:nestprep/features/nanny_hub/model/shift_checklist.dart';
import 'package:nestprep/features/nanny_hub/model/shift_summary.dart';
import 'package:nestprep/features/nanny_hub/model/summary_moment.dart';

import 'model_fixtures.dart';
import 'nanny_access_fixtures.dart';
import 'nanny_pickup_fixtures.dart';

/// The nanny hub's stored models, every field filled (nanny-hub ADR-0003),
/// in a file of its own that `modelFixtures()` spreads — so a parallel
/// feature adding its own does not edit the same lines.
List<ModelFixture> nannyModelFixtures() {
  final at = fixtureInstant;

  final card = ChildCard(
    id: 'm-kid',
    routines: const [
      CareRoutine(label: 'Bath', minuteOfDay: 1080, note: 'Warm'),
    ],
    comfortItems: const ['Blue bunny'],
    settling: 'Two songs',
    goodToKnow: 'Scared of the dark',
    photoId: 'photo-kid-01',
    updatedBy: 'm-sam',
    updatedAt: at,
  );
  final contact = EmergencyContact(
    id: 'c1',
    name: 'Gogo',
    kind: ContactKind.backup,
    phone: '082 555 0199',
    note: 'Two streets away',
    createdBy: 'm-sam',
    createdAt: at,
  );
  final sheet = HomeSheet(
    address: '12 Acacia Lane',
    medicalAidScheme: 'Discovery',
    medicalAidPlan: 'Classic',
    medicalAidNumber: '123',
    updatedBy: 'm-sam',
    updatedAt: at,
  );
  final spot = GuideSpot(
    id: 'g1',
    title: 'Nappies',
    note: 'Top shelf',
    photoId: 'photo-shelf-01',
    createdBy: 'm-sam',
    createdAt: at,
  );
  final rule = HouseRule(
    id: 'r1',
    text: 'No screens after six',
    createdBy: 'm-sam',
    createdAt: at,
  );
  final checklist = ShiftChecklist(
    id: 'bedtime',
    items: const [ChecklistItem(id: 'teeth', text: 'Brush teeth')],
    updatedBy: 'm-sam',
    updatedAt: at,
  );
  final shift = Shift(
    id: 's1',
    carerMemberId: 'm-nomsa',
    startedBy: 'm-nomsa',
    startedAt: at,
    endedAt: at,
    endedBy: 'm-nomsa',
    status: Shift.ended,
    ticks: const {'bedtime:teeth': true},
  );
  final entry = HandoverEntry(
    id: 'e1',
    kind: HandoverKind.mood,
    note: 'Sleepy after swimming',
    mood: HandoverMood.tired,
    childIds: const ['m-kid'],
    photoId: 'photo-e1-001',
    at: at,
    byMemberId: 'm-nomsa',
    createdAt: at,
  );
  final summary = ShiftSummary(
    id: 's1',
    carerMemberId: 'm-nomsa',
    startedAt: at,
    endedAt: at,
    endedBy: 'm-nomsa',
    counts: const {'meal': 2},
    moments: [
      SummaryMoment(
        kind: HandoverKind.meal,
        at: at,
        note: 'Pasta',
        mood: HandoverMood.happy,
        childIds: const ['m-kid'],
        hasPhoto: true,
      ),
    ],
    isTrimmed: true,
    entryCount: 2,
    photoCount: 1,
    childIds: const ['m-kid'],
    checklist: const ChecklistProgress(ticked: 1, total: 2),
    closingNote: 'Asleep by eight',
  );

  return [
    ModelFixture(
      label: 'ChildCard',
      id: 'm-kid',
      value: card,
      toJson: card.toJson,
      fromJson: ChildCard.fromJson,
      keys: const {
        'routines',
        'comfortItems',
        'settling',
        'goodToKnow',
        'photoId',
        'updatedBy',
        'updatedAt',
      },
      note: 'the child’s member id is the document id (nanny-hub ADR-0003).',
    ),
    ModelFixture(
      label: 'EmergencyContact',
      id: 'c1',
      value: contact,
      toJson: contact.toJson,
      fromJson: EmergencyContact.fromJson,
      keys: const {'name', 'kind', 'phone', 'note', 'createdBy', 'createdAt'},
    ),
    ModelFixture(
      label: 'HomeSheet',
      id: HomeSheet.documentId,
      value: sheet,
      toJson: sheet.toJson,
      fromJson: HomeSheet.fromJson,
      keys: const {
        'address',
        'medicalAidScheme',
        'medicalAidPlan',
        'medicalAidNumber',
        'updatedBy',
        'updatedAt',
      },
    ),
    ModelFixture(
      label: 'GuideSpot',
      id: 'g1',
      value: spot,
      toJson: spot.toJson,
      fromJson: GuideSpot.fromJson,
      keys: const {'title', 'note', 'photoId', 'createdBy', 'createdAt'},
    ),
    ModelFixture(
      label: 'HouseRule',
      id: 'r1',
      value: rule,
      toJson: rule.toJson,
      fromJson: HouseRule.fromJson,
      keys: const {'text', 'createdBy', 'createdAt'},
    ),
    ModelFixture(
      label: 'ShiftChecklist',
      id: 'bedtime',
      value: checklist,
      toJson: checklist.toJson,
      fromJson: ShiftChecklist.fromJson,
      keys: const {'items', 'updatedBy', 'updatedAt'},
      note: 'the moment is the document id (nanny-hub ADR-0001).',
    ),
    ModelFixture(
      label: 'Shift',
      id: 's1',
      value: shift,
      toJson: shift.toJson,
      fromJson: Shift.fromJson,
      keys: const {
        'carerMemberId',
        'startedBy',
        'startedAt',
        'endedAt',
        'endedBy',
        'status',
        'ticks',
      },
    ),
    ModelFixture(
      label: 'HandoverEntry',
      id: 'e1',
      value: entry,
      toJson: entry.toJson,
      fromJson: HandoverEntry.fromJson,
      keys: const {
        'kind',
        'note',
        'mood',
        'childIds',
        'photoId',
        'at',
        'byMemberId',
        'createdAt',
      },
    ),
    ModelFixture(
      label: 'ShiftSummary',
      id: 's1',
      value: summary,
      toJson: summary.toJson,
      fromJson: ShiftSummary.fromJson,
      keys: const {
        'carerMemberId',
        'startedAt',
        'endedAt',
        'endedBy',
        'counts',
        'moments',
        'isTrimmed',
        'entryCount',
        'photoCount',
        'childIds',
        'checklist',
        'closingNote',
      },
      note:
          'written only by endNannyShift; the app reads it and never writes '
          'it (nanny-hub ADR-0002).',
    ),
    // pickups (nanny-hub ADR-0005)
    ...pickupModelFixtures(),
    // photo updates and shift-only access (nanny-hub ADR-0004, ADR-0006)
    ...accessModelFixtures(),
  ];
}

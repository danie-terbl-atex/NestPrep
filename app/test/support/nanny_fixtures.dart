import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/household/model/access_defaults.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/household/model/member.dart';
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
import 'package:nestprep/features/nanny_hub/model/shift_moment.dart';
import 'package:nestprep/features/nanny_hub/model/shift_summary.dart';
import 'package:nestprep/features/nanny_hub/model/summary_moment.dart';

import 'household_fixtures.dart';

/// The household every nanny-hub test renders against: Sam the admin, Nomsa
/// the carer on the carer defaults (the hub at `edit`, profiles and
/// medication at `view`), Thandi a helper, and Kid a child — with a card, a
/// sheet, a guide, rules, a checklist, a shift and its summary.
abstract final class NannyFixtures {
  static const nomsaUid = 'uid-nomsa';
  static const nomsaMemberId = 'm-nomsa';

  static Member get nomsa => const Member(
    id: nomsaMemberId,
    displayName: 'Nomsa Carer',
    color: MemberColor.coral,
    roleName: 'carer',
    claimedBy: nomsaUid,
  );

  static List<Member> get members => [
    Fixtures.sam,
    nomsa,
    Fixtures.thandi,
    Fixtures.kid,
  ];

  /// Sam, the admin — family, who sees and writes everything.
  static HouseholdView parentView() => Fixtures.view(members: members);

  /// Nomsa, holding [grant] — the carer defaults unless a test says otherwise.
  static HouseholdView carerView([AccessGrant? grant]) => HouseholdView(
    household: Fixtures.household().copyWith(
      members: const {
        Fixtures.samUid: 'admin',
        Fixtures.thandiUid: 'helper',
        nomsaUid: 'carer',
      },
      access: {nomsaUid: grant ?? AccessDefaults.carer},
      profiles: const {nomsaUid: nomsaMemberId},
    ),
    members: members,
    viewerUid: nomsaUid,
  );

  /// A carer a parent narrowed: the hub to read only.
  static HouseholdView lookOnlyCarerView() => carerView(
    AccessDefaults.carer.withLevel(HouseholdArea.nannyHub, AccessLevel.view),
  );

  /// A carer whose grant keeps the children's profiles and medication from
  /// them — the hub still opens, and says what it cannot show.
  static HouseholdView carerWithoutProfilesView() => carerView(
    AccessDefaults.carer
        .withLevel(HouseholdArea.familyProfiles, AccessLevel.none)
        .withLevel(HouseholdArea.medical, AccessLevel.none),
  );

  static final startedAt = DateTime.utc(2026, 9, 29, 12, 5);

  static ChildCard get kidCard => const ChildCard(
    id: Fixtures.kidMemberId,
    routines: [
      CareRoutine(label: 'Bath', minuteOfDay: 1080, note: 'Warm, not hot'),
      CareRoutine(label: 'Story before sleep'),
      CareRoutine(label: 'Snack', minuteOfDay: 900),
    ],
    comfortItems: ['Blue bunny'],
    settling: 'Two songs and the night light.',
    goodToKnow: 'Scared of the dark.',
  );

  static EmergencyContact get gogo => const EmergencyContact(
    id: 'c-gogo',
    name: 'Gogo',
    kind: ContactKind.backup,
    phone: '082 555 0199',
    note: 'Two streets away',
    createdBy: Fixtures.samMemberId,
  );

  static EmergencyContact get doctor => const EmergencyContact(
    id: 'c-doctor',
    name: 'Dr Naidoo',
    kind: ContactKind.doctor,
    phone: '+27 11 555 0101',
    createdBy: Fixtures.samMemberId,
  );

  static HomeSheet get home => const HomeSheet(
    address: '12 Acacia Lane, Parkhurst',
    medicalAidScheme: 'Discovery',
    medicalAidNumber: '123456789',
  );

  static GuideSpot get nappies => const GuideSpot(
    id: 'g-nappies',
    title: 'Spare nappies',
    note: 'Top shelf of the linen cupboard',
    createdBy: Fixtures.samMemberId,
  );

  static HouseRule get screens => const HouseRule(
    id: 'r-screens',
    text: 'No screens after six',
    createdBy: Fixtures.samMemberId,
  );

  static ShiftChecklist get bedtime => const ShiftChecklist(
    id: 'bedtime',
    items: [
      ChecklistItem(id: 'teeth', text: 'Brush teeth'),
      ChecklistItem(id: 'story', text: 'One story'),
    ],
  );

  static Shift get openShift => Shift(
    id: 'shift-1',
    carerMemberId: nomsaMemberId,
    startedBy: nomsaMemberId,
    startedAt: startedAt,
    ticks: {ShiftChecklist.tickKey(ShiftMoment.bedtime, 'teeth'): true},
  );

  static HandoverEntry get tea => HandoverEntry(
    id: 'e-tea',
    kind: HandoverKind.meal,
    note: 'Ate all the pasta',
    childIds: const [Fixtures.kidMemberId],
    at: startedAt.add(const Duration(hours: 1)),
    byMemberId: nomsaMemberId,
  );

  static ShiftSummary get summary => ShiftSummary(
    id: 'shift-0',
    carerMemberId: nomsaMemberId,
    startedAt: startedAt.subtract(const Duration(days: 1)),
    endedAt: startedAt.subtract(const Duration(hours: 18)),
    counts: const {'meal': 2, 'incident': 1},
    moments: [
      SummaryMoment(
        kind: HandoverKind.incident,
        at: startedAt.subtract(const Duration(hours: 20)),
        note: 'Bumped her knee',
        childIds: const [Fixtures.kidMemberId],
      ),
      SummaryMoment(
        kind: HandoverKind.mood,
        at: startedAt.subtract(const Duration(hours: 19)),
        mood: HandoverMood.happy,
        hasPhoto: true,
      ),
    ],
    entryCount: 3,
    photoCount: 1,
    childIds: const [Fixtures.kidMemberId],
    checklist: const ChecklistProgress(ticked: 1, total: 2),
    closingNote: 'Asleep by eight.',
  );
}

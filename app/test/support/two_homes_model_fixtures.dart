import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/two_homes/model/change_request.dart';
import 'package:nestprep/features/two_homes/model/co_parent_home.dart';
import 'package:nestprep/features/two_homes/model/co_parent_link.dart';
import 'package:nestprep/features/two_homes/model/custody_presets.dart';
import 'package:nestprep/features/two_homes/model/custody_side.dart';
import 'package:nestprep/features/two_homes/model/handover_note.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import 'model_fixtures.dart';

/// Mum's home and Dad's home, as a link's two sides.
const mumsHome = CoParentHome(name: 'Mum’s home', color: MemberColor.coral);
const dadsHome = CoParentHome(name: 'Dad’s home', color: MemberColor.sky);

/// Alternating weeks from Monday 28 September 2026, changing on Friday at
/// five — a schedule with every field filled.
final fixtureSchedule = CustodyPresets.alternatingWeeks(
  startsOn: CalendarDate(2026, 9, 28),
  first: CustodySide.a,
  switchWeekday: DateTime.friday,
  handoverMinute: 17 * 60,
);

/// An active link from Mum's home's side, Sam's profile being `m-kid` —
/// the household fixtures' kid.
CoParentLink aLink({
  LinkStatus status = LinkStatus.active,
  CustodySide ownSide = CustodySide.a,
  CustodySide? awaitingSide,
  Map<String, String> overrides = const {},
}) => CoParentLink(
  id: 'link-sam',
  status: status,
  ownSide: ownSide,
  childMemberId: 'm-kid',
  childName: 'Sam',
  homes: const CoParentHomes(a: mumsHome, b: dadsHome),
  schedule: fixtureSchedule,
  overrides: overrides,
  awaitingSide: awaitingSide,
);

/// Two homes' stored models, every field filled (household ADR-0004), in a
/// file of its own that `modelFixtures()` spreads, so a parallel feature
/// adding its own does not edit the same lines. None is ever written by the
/// app — the co-parenting Functions write both homes' copies — but each is
/// read through its converters, which is what these prove.
List<ModelFixture> twoHomesModelFixtures() {
  final at = fixtureInstant;

  final link = CoParentLink(
    id: 'link-sam',
    status: LinkStatus.active,
    ownSide: CustodySide.a,
    childMemberId: 'm-sam',
    childName: 'Sam',
    homes: const CoParentHomes(a: mumsHome, b: dadsHome),
    schedule: fixtureSchedule,
    overrides: const {'2026-10-09': 'b'},
    awaitingSide: CustodySide.b,
    endedBySide: CustodySide.a,
    createdAt: at,
    updatedAt: at,
  );
  final handover = HandoverNote(
    id: '2026-10-02',
    date: CalendarDate(2026, 10, 2),
    items: const [HandoverItem(text: 'School bag', packed: true)],
    medicine: 'Inhaler at seven',
    homework: 'Reading log',
    clothes: 'Raincoat',
    note: 'Tired after swimming',
    updatedBySide: CustodySide.a,
    updatedAt: at,
  );
  final request = ChangeRequest(
    id: 'swap-1',
    kind: ChangeKind.swap,
    from: CalendarDate(2026, 10, 9),
    to: CalendarDate(2026, 10, 11),
    toSide: CustodySide.b,
    schedule: fixtureSchedule,
    note: 'Granny’s birthday',
    proposedBySide: CustodySide.b,
    status: RequestStatus.accepted,
    createdAt: at,
    answeredAt: at,
    answeredBySide: CustodySide.a,
    answerNote: 'Of course',
  );

  return [
    ModelFixture(
      label: 'CoParentLink',
      id: 'link-sam',
      value: link,
      toJson: link.toJson,
      fromJson: CoParentLink.fromJson,
      keys: const {
        'status',
        'ownSide',
        'childMemberId',
        'childName',
        'homes',
        'schedule',
        'overrides',
        'awaitingSide',
        'endedBySide',
        'createdAt',
        'updatedAt',
      },
      note:
          'each household’s own copy of a link, written only by the '
          'co-parenting Functions (household ADR-0004).',
    ),
    ModelFixture(
      label: 'HandoverNote',
      id: '2026-10-02',
      value: handover,
      toJson: handover.toJson,
      fromJson: HandoverNote.fromJson,
      keys: const {
        'date',
        'items',
        'medicine',
        'homework',
        'clothes',
        'note',
        'updatedBySide',
        'updatedAt',
      },
      note: 'the handover’s day is its document id and its date field.',
    ),
    ModelFixture(
      label: 'ChangeRequest',
      id: 'swap-1',
      value: request,
      toJson: request.toJson,
      fromJson: ChangeRequest.fromJson,
      keys: const {
        'kind',
        'from',
        'to',
        'toSide',
        'schedule',
        'note',
        'proposedBySide',
        'status',
        'createdAt',
        'answeredAt',
        'answeredBySide',
        'answerNote',
      },
    ),
  ];
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/family_profile.dart';
import 'package:nestprep/features/nanny_hub/model/care_routine.dart';
import 'package:nestprep/features/nanny_hub/model/checklist_item.dart';
import 'package:nestprep/features/nanny_hub/model/child_card.dart';
import 'package:nestprep/features/nanny_hub/model/child_in_care.dart';
import 'package:nestprep/features/nanny_hub/model/contact_kind.dart';
import 'package:nestprep/features/nanny_hub/model/emergency_contact.dart';
import 'package:nestprep/features/nanny_hub/model/emergency_number.dart';
import 'package:nestprep/features/nanny_hub/model/handover_draft.dart';
import 'package:nestprep/features/nanny_hub/model/handover_kind.dart';
import 'package:nestprep/features/nanny_hub/model/home_sheet.dart';
import 'package:nestprep/features/nanny_hub/model/nanny_hub.dart';
import 'package:nestprep/features/nanny_hub/model/shift.dart';
import 'package:nestprep/features/nanny_hub/model/shift_checklist.dart';
import 'package:nestprep/features/nanny_hub/model/shift_moment.dart';
import 'package:nestprep/features/nanny_hub/model/shift_summary.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_family_profiles.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/nanny_fixtures.dart';

NannyHub hubWith({
  List<ChildCard> cards = const [],
  List<EmergencyContact> contacts = const [],
  List<ShiftChecklist> checklists = const [],
  List<Shift> openShifts = const [],
  List<ShiftSummary> summaries = const [],
}) => NannyHub(
  cards: cards,
  contacts: contacts,
  sheet: HomeSheet.empty,
  guide: const [],
  rules: const [],
  checklists: checklists,
  openShifts: openShifts,
  summaries: summaries,
);

void main() {
  group('a routine', () {
    test(
      'reads in the order of the day, untimed steps last, ties as written',
      () {
        final ordered = CareRoutine.inOrderOfTheDay(const [
          CareRoutine(label: 'Story'),
          CareRoutine(label: 'Bath', minuteOfDay: 1080),
          CareRoutine(label: 'Teeth', minuteOfDay: 1080),
          CareRoutine(label: 'Snack', minuteOfDay: 900),
          CareRoutine(label: 'Cuddle'),
        ]);
        expect(ordered.map((it) => it.label), [
          'Snack',
          'Bath',
          'Teeth',
          'Story',
          'Cuddle',
        ]);
      },
    );

    test('a card with nothing in it says so', () {
      expect(ChildCard.empty('m').isEmpty, isTrue);
      expect(NannyFixtures.kidCard.isEmpty, isFalse);
    });
  });

  group('an emergency number', () {
    test('dials the digits only, whatever was typed to read it', () {
      expect(NannyFixtures.doctor.dialLink, Uri.parse('tel:+27115550101'));
      expect(EmergencyContact.dialable('(082) 555-0199'), '0825550199');
    });

    test(
      'South Africa’s public numbers are the three the sheet leads with',
      () {
        expect(EmergencyNumber.values.map((number) => number.digits), [
          '10111',
          '10177',
          '112',
        ]);
        expect(EmergencyNumber.mobile.dialLink, Uri.parse('tel:112'));
      },
    );

    test('the sheet puts parents first and the hospital last', () {
      final hub = hubWith(
        contacts: [
          NannyFixtures.doctor,
          NannyFixtures.gogo,
          NannyFixtures.gogo.copyWith(
            id: 'c-mom',
            name: 'Mom',
            kind: ContactKind.parent,
          ),
        ],
      );
      expect(hub.contacts.map((contact) => contact.name), [
        'Mom',
        'Gogo',
        'Dr Naidoo',
      ]);
    });
  });

  group('the hub', () {
    test('has a checklist for every part of a shift, empty until written', () {
      final hub = hubWith(
        checklists: [
          NannyFixtures.bedtime,
          // Written by a newer build, under a moment this one does not know.
          const ShiftChecklist(
            id: 'midnight',
            items: [ChecklistItem(id: 'x', text: 'Feed the cat')],
          ),
        ],
      );
      expect(hub.checklists.map((list) => list.moment), ShiftMoment.values);
      expect(hub.checklistFor(ShiftMoment.bedtime).items, hasLength(2));
      expect(hub.checklistFor(ShiftMoment.arrival).items, isEmpty);
      expect(hub.checklistItemCount, 2);
    });

    test('finds the viewer’s own open shift, and nobody else’s', () {
      final hub = hubWith(openShifts: [NannyFixtures.openShift]);
      expect(hub.openShiftOf(NannyFixtures.nomsaMemberId)?.id, 'shift-1');
      expect(hub.openShiftOf(Fixtures.samMemberId), isNull);
      expect(hub.openShiftOf(null), isNull);
    });

    test(
      'keeps summaries newest first, one still being written first of all',
      () {
        final older = NannyFixtures.summary.copyWith(
          id: 'older',
          endedAt: DateTime.utc(2026, 9, 2),
        );
        const pending = ShiftSummary(
          id: 'pending',
          carerMemberId: NannyFixtures.nomsaMemberId,
        );
        final hub = hubWith(summaries: [older, NannyFixtures.summary, pending]);
        expect(hub.summaries.map((summary) => summary.id), [
          'pending',
          'shift-0',
          'older',
        ]);
        expect(hub.latestSummary?.id, 'pending');
        expect(hub.summaryOf('older'), same(hub.summaries.last));
      },
    );

    test('an unwritten card is an empty card, not a missing child', () {
      expect(hubWith().cardFor('m-kid'), ChildCard.empty('m-kid'));
    });
  });

  group('a summary', () {
    test('lists the kinds that happened, in the order of the buttons', () {
      expect(NannyFixtures.summary.kindsLogged, [
        HandoverKind.meal,
        HandoverKind.incident,
      ]);
      expect(NannyFixtures.summary.hadIncident, isTrue);
      expect(NannyFixtures.summary.countOf(HandoverKind.nap), 0);
    });
  });

  group('a shift', () {
    test('is open until the Function says it ended, and knows its ticks', () {
      final shift = NannyFixtures.openShift;
      expect(shift.isOpen, isTrue);
      expect(shift.isTicked('bedtime:teeth'), isTrue);
      expect(shift.isTicked('bedtime:story'), isFalse);
      expect(shift.copyWith(status: Shift.ended).isOpen, isFalse);
      expect(
        ShiftChecklist.tickKey(ShiftMoment.afterSchool, 'bags'),
        'afterSchool:bags',
      );
    });

    test('an entry says something only with a note, a mood or a photo', () {
      final bare = HandoverDraft(
        kind: HandoverKind.note,
        at: DateTime.utc(2026),
      );
      expect(bare.saysSomething, isFalse);
      expect(bare.withPhoto('photo-1').saysSomething, isTrue);
      expect(bare.withPhoto('photo-1').kind, HandoverKind.note);
    });
  });

  group('who the hub has a card for', () {
    final members = NannyFixtures.members;

    List<ChildInCare> gather({
      AsyncState<FamilyFood>? family,
      Map<String, ChildCard> cards = const {},
      bool canSee = true,
    }) => ChildInCare.gather(
      members: members,
      cards: cards,
      family: family,
      canSeeAllergiesOf: (_) => canSee,
    );

    AsyncState<FamilyFood> food(List<FamilyProfile> profiles) =>
        AsyncData((profiles: profiles, schools: [FamilyFixtures.oakwood]));

    test('every kid profile, even with no card and no profile yet', () {
      final children = gather(family: food(const []));
      expect(children.map((child) => child.memberId), [Fixtures.kidMemberId]);
      expect(children.single.card, ChildCard.empty(Fixtures.kidMemberId));
    });

    test(
      'and a grown-up profile a parent marked as a child, or gave a card',
      () {
        final children = gather(
          family: food([
            const FamilyProfile(id: Fixtures.thandiMemberId, isChild: true),
          ]),
          cards: {
            Fixtures.samMemberId: const ChildCard(id: Fixtures.samMemberId),
          },
        );
        expect(children.map((child) => child.member.displayName), [
          'Kid Parker',
          'Sam Parent',
          'Thandi Helper',
        ]);
      },
    );

    test('reads allergies from the family profile, with the school’s rule', () {
      final kid = gather(family: food([FamilyFixtures.kid])).single;
      final rules = switch (kid.food) {
        AsyncData(:final value) => value,
        _ => fail('the profile was readable'),
      };
      expect(rules.hasSevereAllergy, isTrue);
      expect(rules.isNutFree, isTrue);
    });

    test('is honest about what it cannot show: hidden, loading or failed', () {
      expect(gather(family: food(const []), canSee: false).single.food, isNull);
      expect(gather().single.food, isNull);
      expect(
        gather(family: const AsyncLoading()).single.food,
        isA<AsyncLoading<Object?>>(),
      );
      expect(
        gather(family: const AsyncFailure(UnavailableFailure())).single.food,
        isA<AsyncFailure<Object?>>(),
      );
    });
  });
}

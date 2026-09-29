import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/family_profiles/model/allergy_detail.dart';
import 'package:nestprep/features/family_profiles/model/allergy_severity.dart';
import 'package:nestprep/features/family_profiles/model/dietary_flag.dart';
import 'package:nestprep/features/family_profiles/model/family_entry.dart';
import 'package:nestprep/features/family_profiles/model/family_profile.dart';
import 'package:nestprep/features/family_profiles/model/family_roster.dart';
import 'package:nestprep/features/family_profiles/model/school.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/features/lunch_box/model/lunch_feedback.dart';
import 'package:nestprep/features/lunch_box/model/lunch_item.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_plan.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/model/lunch_week.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import 'household_fixtures.dart';

/// Two children and a small library, for the lunch-box tests. Today in the
/// household is Tuesday 29 September 2026, in ISO week 2026-W40.
///
/// Lwazi (`Fixtures.kidMemberId`) has a severe peanut allergy and goes to a
/// nut-free school; Ayanda has no allergies and does not like tomatoes.
abstract final class LunchFixtures {
  static final nowUtc = DateTime.utc(2026, 9, 29, 7);
  static final today = CalendarDate(2026, 9, 29);
  static final week = LunchWeek.of(today);

  static const lwaziId = Fixtures.kidMemberId;
  static const ayandaId = 'm-ayanda';

  static const oakwood = School(id: 'oakwood', name: 'Oakwood', nutFree: true);

  static Member get lwazi => const Member(
    id: lwaziId,
    displayName: 'Lwazi',
    color: MemberColor.sky,
    roleName: 'kid',
  );

  static Member get ayanda => const Member(
    id: ayandaId,
    displayName: 'Ayanda',
    color: MemberColor.coral,
    roleName: 'kid',
  );

  static FamilyProfile get lwaziProfile => const FamilyProfile(
    id: lwaziId,
    isChild: true,
    allergies: {
      Allergen.peanut: AllergyDetail(severity: AllergySeverity.severe),
    },
    schoolId: 'oakwood',
  );

  static FamilyProfile get ayandaProfile => const FamilyProfile(
    id: ayandaId,
    isChild: true,
    dislikes: ['Tomatoes'],
    likes: ['Grapes'],
  );

  static FamilyEntry get lwaziEntry =>
      FamilyEntry(member: lwazi, profile: lwaziProfile, school: oakwood);

  static FamilyEntry get ayandaEntry =>
      FamilyEntry(member: ayanda, profile: ayandaProfile);

  /// A child with only [diet], for the nut-free-by-family-rule case.
  static FamilyEntry childOnDiet(Set<DietaryFlag> diet) => FamilyEntry(
    member: ayanda,
    profile: FamilyProfile(id: ayandaId, isChild: true, diet: diet),
  );

  static FamilyRoster roster({List<Member>? extra}) => FamilyRoster(
    members: [Fixtures.sam, lwazi, ayanda, ...?extra],
    profiles: [lwaziProfile, ayandaProfile],
    schools: const [oakwood],
  );

  static LunchItem item(
    String id,
    String name,
    LunchSlot slot, {
    Set<Allergen> allergens = const {},
    bool prepAhead = false,
    String? prepNote,
    bool archived = false,
  }) => LunchItem.named(
    id: id,
    name: name,
    slot: slot,
    allergens: allergens,
    addedBy: Fixtures.samMemberId,
    prepAhead: prepAhead,
    prepNote: prepNote,
  ).copyWith(archived: archived);

  static final cheese = item(
    'cheese',
    'Cheese and tomato sandwich',
    LunchSlot.main,
    allergens: {Allergen.wheat, Allergen.milk},
  );
  static final peanutButter = item(
    'pb',
    'Peanut butter sandwich',
    LunchSlot.main,
    allergens: {Allergen.peanut, Allergen.wheat},
  );
  static final wrap = item(
    'wrap',
    'Chicken wrap',
    LunchSlot.main,
    allergens: {Allergen.wheat},
  );
  static final apple = item('apple', 'Apple slices', LunchSlot.fruit);
  static final grapes = item('grapes', 'Grapes', LunchSlot.fruit);
  static final carrots = item(
    'carrots',
    'Carrot sticks',
    LunchSlot.veg,
    prepAhead: true,
    prepNote: 'Cut on Sunday',
  );
  static final biltong = item('biltong', 'Biltong', LunchSlot.snack);
  static final trailMix = item(
    'trail',
    'Trail mix',
    LunchSlot.snack,
    allergens: {Allergen.treeNut},
  );
  static final muffin = item(
    'muffin',
    'Banana muffin',
    LunchSlot.treat,
    allergens: {Allergen.wheat, Allergen.egg},
    prepAhead: true,
  );

  static List<LunchItem> get library => [
    cheese,
    peanutButter,
    wrap,
    apple,
    grapes,
    carrots,
    biltong,
    trailMix,
    muffin,
  ];

  static LunchPlan plan(
    String childId, {
    LunchWeek? week,
    Map<String, LunchPick> slots = const {},
    Map<String, LunchFeedback> feedback = const {},
  }) => LunchPlan.empty(
    childId: childId,
    week: week ?? LunchFixtures.week,
  ).copyWith(slots: slots, feedback: feedback);

  static String key(int day, LunchSlot slot) => LunchPlan.slotKey(day, slot);

  static LunchFeedback feedback(
    LunchVerdict box, {
    Map<LunchSlot, LunchVerdict> items = const {},
  }) => LunchFeedback.of(box: box, items: items, by: Fixtures.samMemberId);
}

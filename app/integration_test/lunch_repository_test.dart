import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nestprep/app/firebase_bootstrap.dart';
import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/family_profiles/data/callable_child_profile_directory.dart';
import 'package:nestprep/features/family_profiles/data/firestore_family_profile_repository.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/family_profiles/model/allergy_draft.dart';
import 'package:nestprep/features/family_profiles/model/allergy_severity.dart';
import 'package:nestprep/features/household/model/member_role.dart';
import 'package:nestprep/features/lunch_box/data/firestore_lunch_repository.dart';
import 'package:nestprep/features/lunch_box/model/lunch_feedback.dart';
import 'package:nestprep/features/lunch_box/model/lunch_item.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_plan.dart';
import 'package:nestprep/features/lunch_box/model/lunch_seed_catalogue.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/model/lunch_week.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import 'household_fixture.dart';

/// Lunch boxes' repository against the real Firestore in the emulator suite
/// (foundation ADR-0010) — the writes a fake cannot vouch for:
///
/// 1. `setPicks` creates a plan on its first pick and afterwards moves only
///    the slots it names, clearing one with a delete sentinel inside a
///    `mergeFields` write;
/// 2. the rules refuse a pick with a child's allergen, as the app expects to
///    hear it — `PermissionDeniedFailure`;
/// 3. the starter library seeds, and a mark nests a server timestamp.
///
/// Run it with the suite up:
///
///     firebase emulators:start --project nestprep-643b7
///     flutter test integration_test/lunch_repository_test.dart -d <device>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late TestHousehold home;
  late FirestoreLunchRepository lunches;
  late String childId;
  final week = LunchWeek.of(CalendarDate(2026, 9, 29));

  setUpAll(() async {
    home = await signInAndCreateAHousehold();
    lunches = FirestoreLunchRepository(home.firestore);
  });

  setUp(() async {
    home = await home.freshHousehold();
    childId = await home.households.addMember(
      householdId: home.id,
      displayName: 'Lwazi',
      color: MemberColor.sky,
      role: MemberRole.kid,
    );
    // Who is a child is the `setChildProfile` callable's alone: the free
    // tier counts it (subscriptions ADR-0001), so the rules refuse a client
    // write of it. The same regional instance `bootstrapFirebase` pointed at
    // the emulator.
    await CallableChildProfileDirectory(
      FirebaseFunctions.instanceFor(region: functionsRegion),
    ).setIsChild(householdId: home.id, memberId: childId, isChild: true);
    final family = FirestoreFamilyProfileRepository(home.firestore);
    await family.saveAllergy(
      householdId: home.id,
      memberId: childId,
      draft: const AllergyDraft.known(
        allergen: Allergen.peanut,
        severity: AllergySeverity.severe,
      ),
    );
  });

  tearDownAll(() async => home.signOut());

  LunchPick pick(String id, String name, [List<String> allergens = const []]) =>
      LunchPick(itemId: id, name: name, allergens: allergens);

  test(
    'the first pick makes the plan, and later picks keep the others',
    () async {
      await lunches.setPicks(
        householdId: home.id,
        childId: childId,
        week: week,
        picks: {
          '1_main': pick('wrap', 'Chicken wrap', ['wheat']),
        },
      );
      await lunches.setPicks(
        householdId: home.id,
        childId: childId,
        week: week,
        picks: {'2_fruit': pick('apple', 'Apple')},
      );
      final plan = await lunches
          .watchPlan(home.id, childId: childId, week: week)
          .first;
      expect(plan.id, '${childId}_${week.key}');
      expect(plan.pickAt(1, LunchSlot.main)?.name, 'Chicken wrap');
      expect(plan.pickAt(2, LunchSlot.fruit)?.itemId, 'apple');

      await lunches.setPicks(
        householdId: home.id,
        childId: childId,
        week: week,
        picks: {'1_main': null},
      );
      final cleared = await lunches
          .watchPlan(home.id, childId: childId, week: week)
          .first;
      expect(cleared.pickAt(1, LunchSlot.main), isNull);
      expect(cleared.pickAt(2, LunchSlot.fruit), isNotNull);
    },
  );

  test(
    'the rules refuse the child’s allergen, as a permission failure',
    () async {
      await expectLater(
        lunches.setPicks(
          householdId: home.id,
          childId: childId,
          week: week,
          picks: {
            '1_main': pick('pb', 'Peanut butter', ['peanut']),
          },
        ),
        throwsA(isA<PermissionDeniedFailure>()),
      );
    },
  );

  test('a whole week fills, a day per write (lunch-box ADR-0010)', () async {
    await lunches.setPicks(
      householdId: home.id,
      childId: childId,
      week: week,
      picks: {
        for (final key in LunchPlan.allSlotKeys) key: pick('apple', 'Apple'),
      },
    );
    final plan = await lunches
        .watchPlan(home.id, childId: childId, week: week)
        .firstWhere(
          (plan) => plan.slots.length == LunchPlan.allSlotKeys.length,
        );
    expect(plan.slots, hasLength(25));
  });

  test(
    'the starter library seeds, and a free household marks nothing eaten',
    () async {
      await lunches.seedItems(
        home.id,
        LunchSeedCatalogue.itemsFor(home.memberId),
      );
      final List<LunchItem> items = await lunches.watchItems(home.id).first;
      expect(items, hasLength(LunchSeedCatalogue.seeds.length));

      await lunches.setPicks(
        householdId: home.id,
        childId: childId,
        week: week,
        picks: {
          '3_main': pick('wrap', 'Chicken wrap', ['wheat']),
        },
      );
      // Learning from what came home is premium, and a household made here
      // is free (lunch-box ADR-0009): only a Function can grant premium, so
      // the device proves the refusal; the rules suite proves the rest.
      await expectLater(
        lunches.setFeedback(
          householdId: home.id,
          childId: childId,
          week: week,
          isoWeekday: 3,
          feedback: LunchFeedback.of(
            box: LunchVerdict.ate,
            items: const {},
            by: home.memberId,
          ),
        ),
        throwsA(isA<PermissionDeniedFailure>()),
      );
    },
  );

  test('a free household ticks no prep list (lunch-box ADR-0009)', () async {
    await expectLater(
      lunches.setPrepDone(
        householdId: home.id,
        week: week,
        itemId: 'carrots',
        done: true,
      ),
      throwsA(isA<PermissionDeniedFailure>()),
    );
  });
}

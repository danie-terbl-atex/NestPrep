import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/family_profiles/model/allergy_detail.dart';
import 'package:nestprep/features/family_profiles/model/allergy_severity.dart';
import 'package:nestprep/features/family_profiles/model/dietary_flag.dart';
import 'package:nestprep/features/family_profiles/model/family_profile.dart';
import 'package:nestprep/features/family_profiles/model/member_health.dart';
import 'package:nestprep/features/family_profiles/model/school.dart';
import 'package:nestprep/features/family_profiles/state/family_controller.dart';
import 'package:nestprep/features/family_profiles/state/member_health_controller.dart';
import 'package:nestprep/features/family_profiles/ui/family_member_screen.dart';
import 'package:nestprep/features/family_profiles/ui/family_screen.dart';
import 'package:nestprep/features/household/model/birthday.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/fake_family_profiles.dart';
import '../test/support/household_fixtures.dart';
import 'design_review_press.dart';

/// Family profiles in the design-review press — the list, a child's profile,
/// and that profile at 200% text. Like `design_review_test.dart`, pictures to
/// look at rather than assertions: regenerate with
///
///     flutter test tool/family_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  // ------------------------------------------------------- family profiles

  /// Two children — one with a severe allergy at a nut-free school, one with
  /// a medicine and a dislike list — so both warning treatments are in frame.
  final lily = Member(
    id: 'm-lily',
    displayName: 'Lily Parker',
    color: MemberColor.coral,
    roleName: 'member',
    birthday: Birthday(year: 2019, month: 3, day: 7),
  );
  final kid = Fixtures.kid.copyWith(
    displayName: 'Noah Parker',
    birthday: Birthday(year: 2016, month: 11, day: 2),
  );
  HouseholdView familyView() =>
      Fixtures.view(members: [lily, kid, Fixtures.sam, Fixtures.thandi]);
  const lilyProfile = FamilyProfile(
    id: 'm-lily',
    isChild: true,
    likes: ['Cucumber', 'Yoghurt', 'Rice cakes'],
    dislikes: ['Tomatoes'],
    diet: {DietaryFlag.vegetarian},
    allergies: {
      Allergen.egg: AllergyDetail(severity: AllergySeverity.moderate),
    },
    schoolId: 'greenfields',
    grade: 'Grade R',
    clothingSize: 'Age 6–7',
    shoeSize: 'UK 11',
  );
  const schools = [
    FamilyFixtures.oakwood,
    School(id: 'greenfields', name: 'Greenfields Pre-Primary'),
  ];

  Future<void> familyList(WidgetTester tester, Brightness brightness) async {
    final repository = FakeFamilyProfileRepository();
    addTearDown(repository.close);
    final controller = FamilyController(
      familyProfileRepository: repository,
      householdId: Fixtures.householdId,
      household: familyView(),
    );
    addTearDown(controller.dispose);
    await capturePicture(
      tester,
      'family-${brightness.name}',
      screen: const FamilyScreen(),
      providers: [
        ChangeNotifierProvider<FamilyController>.value(value: controller),
      ],
      brightness: brightness,
      view: familyView(),
      emit: () async {
        repository.emitProfiles([FamilyFixtures.kid, lilyProfile]);
        repository.emitSchools(schools);
      },
    );
  }

  Future<void> familyProfile(
    WidgetTester tester,
    Brightness brightness, {
    double textScale = 1,
    String? name,
  }) async {
    final repository = FakeFamilyProfileRepository();
    addTearDown(repository.close);
    final controller = FamilyController(
      familyProfileRepository: repository,
      householdId: Fixtures.householdId,
      household: familyView(),
    );
    addTearDown(controller.dispose);
    final health = MemberHealthController(
      familyProfileRepository: repository,
      householdId: Fixtures.householdId,
      memberId: Fixtures.kidMemberId,
      isVisible: true,
    );
    addTearDown(health.dispose);
    await capturePicture(
      tester,
      name ?? 'family-profile-${brightness.name}',
      screen: const FamilyMemberScreen(memberId: Fixtures.kidMemberId),
      providers: [
        ChangeNotifierProvider<FamilyController>.value(value: controller),
        ChangeNotifierProvider<MemberHealthController>.value(value: health),
      ],
      brightness: brightness,
      textScale: textScale,
      view: familyView(),
      emit: () async {
        repository.emitProfiles([FamilyFixtures.kid, lilyProfile]);
        repository.emitSchools(schools);
        repository.emitHealth(
          const MemberHealth(
            id: Fixtures.kidMemberId,
            medications: {'a': FamilyFixtures.inhaler},
          ),
        );
      },
    );
  }

  for (final brightness in Brightness.values) {
    testWidgets('family — ${brightness.name}', (tester) async {
      await familyList(tester, brightness);
    });

    testWidgets('a family profile — ${brightness.name}', (tester) async {
      await familyProfile(tester, brightness);
    });
  }

  testWidgets('a family profile in dark at 200% text', (tester) async {
    await familyProfile(
      tester,
      Brightness.dark,
      textScale: 2,
      name: 'family-profile-dark-200-percent-text',
    );
  });
}

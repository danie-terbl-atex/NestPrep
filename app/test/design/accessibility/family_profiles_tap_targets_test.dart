import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/member_health.dart';
import 'package:nestprep/features/family_profiles/state/family_controller.dart';
import 'package:nestprep/features/family_profiles/state/member_health_controller.dart';
import 'package:nestprep/features/family_profiles/ui/family_member_screen.dart';
import 'package:nestprep/features/family_profiles/ui/family_screen.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../support/accessibility_audit.dart';
import '../../support/fake_family_profiles.dart';
import '../../support/household_fixtures.dart';
import '../../support/pump_screen.dart';

/// Family profiles through the same audit as every other screen: labelled
/// controls, 44×44 targets — as an admin sees them, with every edit control on.
void main() {
  setUpAll(tz_data.initializeTimeZones);

  testWidgets('family profiles', (tester) async {
    phone(tester);
    final repository = FakeFamilyProfileRepository();
    addTearDown(repository.close);
    final family = FamilyController(
      familyProfileRepository: repository,
      householdId: Fixtures.householdId,
      household: Fixtures.view(),
    );
    addTearDown(family.dispose);

    await pumpScreen(
      tester,
      const FamilyScreen(),
      providers: [
        ChangeNotifierProvider<FamilyController>.value(value: family),
      ],
    );
    repository.emitProfiles([FamilyFixtures.kid]);
    repository.emitSchools([FamilyFixtures.oakwood]);
    await expectAccessible(tester, 'the family');
  });

  testWidgets('a family profile', (tester) async {
    phone(tester);
    final repository = FakeFamilyProfileRepository();
    addTearDown(repository.close);
    final family = FamilyController(
      familyProfileRepository: repository,
      householdId: Fixtures.householdId,
      household: Fixtures.view(),
    );
    addTearDown(family.dispose);
    final health = MemberHealthController(
      familyProfileRepository: repository,
      householdId: Fixtures.householdId,
      memberId: Fixtures.kidMemberId,
      isVisible: true,
    );
    addTearDown(health.dispose);

    await pumpScreen(
      tester,
      const FamilyMemberScreen(memberId: Fixtures.kidMemberId),
      providers: [
        ChangeNotifierProvider<FamilyController>.value(value: family),
        ChangeNotifierProvider<MemberHealthController>.value(value: health),
      ],
    );
    repository.emitProfiles([FamilyFixtures.kid]);
    repository.emitSchools([FamilyFixtures.oakwood]);
    repository.emitHealth(
      const MemberHealth(
        id: Fixtures.kidMemberId,
        medications: {'a': FamilyFixtures.inhaler},
      ),
    );
    await expectAccessible(tester, 'a family profile');

    // The profile is longer than a phone; the controls below the fold are
    // audited too.
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await expectAccessible(tester, 'a family profile, scrolled to its end');
  });
}

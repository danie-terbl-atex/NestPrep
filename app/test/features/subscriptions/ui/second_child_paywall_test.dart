import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/member_health.dart';
import 'package:nestprep/features/family_profiles/state/family_controller.dart';
import 'package:nestprep/features/family_profiles/state/member_health_controller.dart';
import 'package:nestprep/features/family_profiles/ui/family_member_screen.dart';
import 'package:nestprep/features/legal/model/legal_versions.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_family_profiles.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';

/// A free household marks every child it has (subscriptions ADR-0008): the
/// second is marked like the first, and no paywall stands in the way.
void main() {
  testWidgets('a second child on the free plan is simply marked', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final premium = SubscriptionHarness();
    final repository = FakeFamilyProfileRepository();
    final family = FamilyController(
      familyProfileRepository: repository,
      childProfileDirectory: repository,
      householdId: Fixtures.householdId,
      household: Fixtures.view(),
    );
    final health = MemberHealthController(
      familyProfileRepository: repository,
      householdId: Fixtures.householdId,
      memberId: Fixtures.kidMemberId,
      isVisible: true,
    );
    addTearDown(() async {
      family.dispose();
      health.dispose();
      await repository.close();
    });
    await pumpScreen(
      tester,
      const FamilyMemberScreen(memberId: Fixtures.kidMemberId),
      providers: [
        ChangeNotifierProvider<FamilyController>.value(value: family),
        ChangeNotifierProvider<MemberHealthController>.value(value: health),
        ...premium.providers,
      ],
    );
    repository.emitProfiles([
      FamilyFixtures.kid.copyWith(isChild: false),
      FamilyFixtures.kid.copyWith(id: Fixtures.thandiMemberId, isChild: true),
    ]);
    repository.emitSchools([FamilyFixtures.oakwood]);
    repository.emitHealth(const MemberHealth(id: Fixtures.kidMemberId));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel(FamilyCopy.markAsChild));
    await tester.pumpAndSettle();
    // A parent's consent is still asked first (accounts ADR-0005).
    await tester.tap(find.text(LegalCopy.guardianConsentConfirm));
    await tester.pumpAndSettle();

    final (method, arguments) = repository.writes.single;
    expect(method, 'setIsChild');
    expect(arguments, {
      'memberId': Fixtures.kidMemberId,
      'isChild': true,
      'guardianConsentVersion': LegalVersions.privacy,
    });
    for (final feature in [
      PremiumFeature.additionalChild,
      PremiumFeature.householdSize,
    ]) {
      expect(find.text(SubscriptionCopy.headline(feature)), findsNothing);
    }
    expect(premium.server.verified, isEmpty);
  });
}

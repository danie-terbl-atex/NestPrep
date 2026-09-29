import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/member_health.dart';
import 'package:nestprep/features/family_profiles/state/family_controller.dart';
import 'package:nestprep/features/family_profiles/state/member_health_controller.dart';
import 'package:nestprep/features/family_profiles/ui/family_member_screen.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_family_profiles.dart';
import '../../../support/fake_subscriptions.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';

/// The free tier's limit, met where a parent meets it: marking a second
/// child (subscriptions ADR-0001). The server refuses it; the answer on
/// screen is the paywall opened on that very thing — and once premium is
/// bought, the child is marked after all.
void main() {
  late SubscriptionHarness premium;
  late FakeFamilyProfileRepository repository;

  Future<void> openProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    premium = SubscriptionHarness();
    repository = FakeFamilyProfileRepository();
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
    // Not a child yet: the household already has its one free child.
    repository.emitProfiles([FamilyFixtures.kid.copyWith(isChild: false)]);
    repository.emitSchools([FamilyFixtures.oakwood]);
    repository.emitHealth(const MemberHealth(id: Fixtures.kidMemberId));
    await tester.pumpAndSettle();

    repository.failWritesWith = const PremiumRequiredFailure(
      PremiumFeature.additionalChild,
    );
    await tester.tap(find.bySemanticsLabel(FamilyCopy.markAsChild));
    await tester.pumpAndSettle();
  }

  testWidgets('opens premium on it, and marks the child once it is bought', (
    tester,
  ) async {
    await openProfile(tester);
    expect(
      find.text(SubscriptionCopy.headline(PremiumFeature.additionalChild)),
      findsOneWidget,
    );
    // The refusal is answered, not apologised for.
    expect(
      find.text(
        AppCopy.failure(
          const PremiumRequiredFailure(PremiumFeature.additionalChild),
        ),
      ),
      findsNothing,
    );

    await tester.tap(find.text(SubscriptionCopy.subscribe));
    await tester.pump();
    premium.store.report([purchased()]);
    await tester.pumpAndSettle();
    expect(
      premium.server.verified.single.trigger,
      PremiumFeature.additionalChild,
    );
    await tester.tap(find.text(SubscriptionCopy.done));
    await tester.pumpAndSettle();

    final (method, arguments) = repository.writes.single;
    expect(method, 'setIsChild');
    expect(arguments, {'memberId': Fixtures.kidMemberId, 'isChild': true});
  });

  testWidgets('closing premium leaves the profile as it was', (tester) async {
    await openProfile(tester);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(repository.writes, isEmpty);
    expect(
      find.text(SubscriptionCopy.headline(PremiumFeature.additionalChild)),
      findsNothing,
    );
  });
}

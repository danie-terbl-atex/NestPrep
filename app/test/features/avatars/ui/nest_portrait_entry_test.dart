import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/avatars/model/avatar_creation.dart';
import 'package:nestprep/features/avatars/ui/nest_portrait_entry.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';
import 'package:nestprep/shared/flags/feature_flag.dart';

import '../../../support/fake_feature_flag_source.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    HouseholdView? view,
    Entitlement entitlement = Entitlement.free,
    Set<FeatureFlag> off = const {},
  }) async {
    final flags = FakeFeatureFlagSource();
    addTearDown(flags.close);
    await pumpScreen(
      tester,
      const Scaffold(body: SingleChildScrollView(child: NestPortraitEntry())),
      providers: [
        ...SubscriptionHarness(entitlement: entitlement).providers,
        featureFlagsProvider(source: flags),
      ],
      view: view,
    );
    if (off.isNotEmpty) {
      flags.emit({for (final flag in off) flag.field: false});
    }
  }

  final title = AvatarCreationCopy.recipeTitle(CreationRecipe.portrait);

  testWidgets('family in a premium household are offered the portrait', (
    tester,
  ) async {
    await pump(tester, entitlement: Entitlement(premiumUntil: DateTime(2100)));
    await tester.pumpAndSettle();
    expect(find.text(title), findsOneWidget);
    expect(find.text(SubscriptionCopy.premium), findsNothing);
  });

  testWidgets('a free household sees it marked premium', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();
    expect(find.text(title), findsOneWidget);
    expect(find.text(SubscriptionCopy.premium), findsOneWidget);
  });

  testWidgets('a helper is never offered it', (tester) async {
    await pump(
      tester,
      view: Fixtures.helperView(AccessGrant.uniform(AccessLevel.edit)),
    );
    await tester.pumpAndSettle();
    expect(find.text(title), findsNothing);
  });

  testWidgets('nor anybody, with creations switched off', (tester) async {
    await pump(
      tester,
      view: HouseholdView(
        household: Fixtures.household().copyWith(avatarCreationsOn: false),
        members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
        viewerUid: Fixtures.samUid,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(title), findsNothing);
  });

  for (final flag in [FeatureFlag.avatars, FeatureFlag.avatarCreations]) {
    testWidgets('nor with ${flag.field} off', (tester) async {
      await pump(tester, off: {flag});
      await tester.pumpAndSettle();
      expect(find.text(title), findsNothing);
    });
  }
}

import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/model/entitlement_status.dart';
import 'package:nestprep/features/subscriptions/state/household_entitlement.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'fake_subscriptions.dart';
import 'household_fixtures.dart';

/// A household whose Premium renews in a month, in place of the free one
/// `pumpRouter` provides.
SingleChildWidget premiumEntitlementProvider({Entitlement? entitlement}) =>
    ChangeNotifierProvider<HouseholdEntitlement>(
      create: (_) => HouseholdEntitlement(
        entitlementRepository: FakeEntitlementRepository(
          initial:
              entitlement ??
              Entitlement(
                premiumUntil: DateTime.now().add(const Duration(days: 30)),
                status: EntitlementStatus.active,
                willRenew: true,
              ),
        ),
        householdId: Fixtures.householdId,
      ),
    );

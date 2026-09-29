import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../data/entitlement_repository.dart';
import '../state/household_entitlement.dart';
import '../state/purchase_coordinator.dart';

/// Gives everything under the household shell one listener on the
/// household's entitlement (subscriptions ADR-0001), and tells the app-wide
/// [PurchaseCoordinator] which household a purchase is for — so a purchase
/// the store redelivers is verified as soon as a household is open, and only
/// for somebody who may buy.
class EntitlementScope extends StatefulWidget {
  const EntitlementScope({
    required this.householdId,
    required this.canBuy,
    required this.child,
    super.key,
  });

  final String householdId;
  final bool canBuy;
  final Widget child;

  @override
  State<EntitlementScope> createState() => _EntitlementScopeState();
}

class _EntitlementScopeState extends State<EntitlementScope> {
  @override
  void initState() {
    super.initState();
    _attach();
  }

  @override
  void didUpdateWidget(EntitlementScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.householdId != widget.householdId ||
        oldWidget.canBuy != widget.canBuy) {
      _attach();
    }
  }

  /// Off the frame: a purchase it releases notifies listeners, and a build
  /// is not where that belongs (`FE-05`).
  void _attach() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PurchaseCoordinator>().attach(
        householdId: widget.householdId,
        canBuy: widget.canBuy,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Keyed by household: switching household drops the old listener.
      key: ValueKey(widget.householdId),
      create: (context) => HouseholdEntitlement(
        entitlementRepository: context.read<EntitlementRepository>(),
        householdId: widget.householdId,
      ),
      child: widget.child,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/copy/app_copy.dart';
import '../../subscriptions/state/household_entitlement.dart';
import '../state/two_homes_controller.dart';
import 'locked_two_homes_screen.dart';
import 'two_homes_premium_area.dart';
import 'two_homes_screen.dart';

/// The way into two homes. With Premium it is the list; without, the place
/// is locked but still lists the open links, because ending one is never
/// refused on the server and must stay within reach (subscriptions ADR-0008).
/// An entitlement not yet known is left to [TwoHomesPremiumArea].
class TwoHomesEntryArea extends StatelessWidget {
  const TwoHomesEntryArea({required this.create, super.key});

  final TwoHomesController Function(BuildContext context) create;

  @override
  Widget build(BuildContext context) {
    final entitlement = context.watch<HouseholdEntitlement>();
    if (entitlement.isKnown && !entitlement.isPremium) {
      return ChangeNotifierProvider(
        create: create,
        child: const LockedTwoHomesScreen(),
      );
    }
    return TwoHomesPremiumArea(
      TwoHomesCopy.title,
      ChangeNotifierProvider(create: create, child: const TwoHomesScreen()),
    );
  }
}

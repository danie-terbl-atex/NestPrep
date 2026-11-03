import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/household/model/household_view.dart';
import 'household_route.dart';
import 'household_shell.dart';

/// Moves between the tabs of one household. A place that lives under More
/// rather than in the bar is pushed instead, so it carries the way back to
/// where it was opened from (`FE-17`).
void goToTab(BuildContext context, GoRouterState state, HouseholdTab tab) {
  final permissions = context.read<HouseholdView>().permissions;
  final path = HouseholdRoute.pathFor(
    HouseholdRoute.idFrom(state),
    tab.landingFor(permissions),
  );
  if (tab != HouseholdTab.more && tab.barTab == HouseholdTab.more) {
    context.push(path);
  } else {
    context.go(path);
  }
}

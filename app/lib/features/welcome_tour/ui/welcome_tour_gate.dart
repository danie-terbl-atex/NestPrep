import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../app/household_route.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../accounts/model/session.dart';
import '../../accounts/state/session_controller.dart';
import '../../household/model/household_view.dart';
import '../../subscriptions/state/household_entitlement.dart';
import '../model/welcome_tour_trigger.dart';
import '../state/tour_controller.dart';
import 'start_welcome_tour.dart';

/// Asks [WelcomeTourTrigger] whenever what it reads changes, and starts the
/// tour when the answer is yes (welcome-tour ADR-0001, ADR-0002) — off the
/// frame, because a build is not where a start belongs (`FE-05`).
///
/// It sits under the household shell's entitlement, which is the one thing
/// the shell itself cannot see.
class WelcomeTourGate extends StatelessWidget {
  const WelcomeTourGate({
    required this.location,
    required this.child,
    super.key,
  });

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tour = context.read<TourController>();
    final householdId = context.watch<HouseholdView>().household.id;
    final account = switch (context.watch<SessionController>().session) {
      AsyncData(value: SignedIn(:final account)) => account,
      _ => null,
    };
    final shouldOpen = WelcomeTourTrigger.shouldOpen(
      isOnToday: location == HouseholdRoute.homeFor(householdId),
      account: account,
      entitlement: context.watch<HouseholdEntitlement>().entitlement,
      flagsHaveSettled: context.watch<FeatureFlagsController>().hasSettled,
      hasOpened: tour.hasAutoStarted,
    );
    if (shouldOpen) {
      tour.markAutoStarted();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) startWelcomeTour(context);
      });
    }
    return child;
  }
}

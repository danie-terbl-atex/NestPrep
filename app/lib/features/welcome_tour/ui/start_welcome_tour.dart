import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../shared/flags/feature_flags_controller.dart';
import '../../household/model/household_view.dart';
import '../../subscriptions/state/household_entitlement.dart';
import '../model/tour_place.dart';
import '../model/welcome_tour_plan.dart';
import '../state/tour_controller.dart';

/// Starts the welcome tour for whoever is looking, as the household stands
/// (welcome-tour ADR-0002) — from the shell the first time, from the account
/// menu after. Outside a household it does nothing.
void startWelcomeTour(BuildContext context) {
  final tour = context.read<TourController?>();
  final view = context.read<HouseholdView?>();
  if (tour == null || view == null) return;
  final plan = WelcomeTourPlan(
    view: view,
    flags: context.read<FeatureFlagsController>().flags,
    isPremium: context.read<HouseholdEntitlement>().isPremium,
  );
  tour.start(
    plan.stops,
    finishOn: plan.endsOnLunch ? TourPlace.lunch : TourPlace.today,
  );
}

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../subscriptions/state/household_entitlement.dart';
import '../model/lunch_item.dart';
import '../model/lunch_pantry_bias.dart';
import '../model/lunch_suggestions.dart';
import '../state/lunch_budget_controller.dart';
import '../state/lunch_pantry_controller.dart';

/// What the V2 tools add to the one-tap picker (lunch-box ADR-0006,
/// ADR-0007): planning from the pantry puts what is in the house first and
/// says so, and budget mode says what a box's share costs. Each only when
/// its switch is on — and the price only for a premium household. With
/// neither, the picker is exactly ADR-0003's.
@immutable
final class LunchPickerLens {
  const LunchPickerLens._({this.bias, this.budget});

  /// Read from the screen's context. Every controller is looked up as
  /// optional: a screen without the V2 tools above it gets the plain picker.
  factory LunchPickerLens.of(BuildContext context) {
    final flags = context.read<FeatureFlagsController?>();
    final pantry = flags?.isOn(FeatureFlag.lunchPantry) ?? false
        ? context.read<LunchPantryController?>()
        : null;
    final isPremium = context.read<HouseholdEntitlement?>()?.isPremium ?? false;
    final budget = (flags?.isOn(FeatureFlag.lunchBudget) ?? false) && isPremium
        ? context.read<LunchBudgetController?>()
        : null;
    return LunchPickerLens._(bias: pantry?.bias, budget: budget);
  }

  final LunchPantryBias? bias;
  final LunchBudgetController? budget;

  RankedLunchItems order(RankedLunchItems ranked) =>
      bias?.order(ranked) ?? ranked;

  /// What is said about [item] beyond its taste.
  List<String> notesFor(LunchItem item) {
    final bias = this.bias;
    final price = switch (budget?.week) {
      AsyncData(:final value) => value.priceOf(item.id),
      _ => null,
    };
    return [
      if (bias != null)
        bias.hasLeft(item.id)
            ? LunchPantryCopy.inPantry(bias.availableOf(item.id))
            : LunchPantryCopy.notInPantry,
      if (price != null) LunchBudgetCopy.perBox(price.perBox.money.display),
    ];
  }
}

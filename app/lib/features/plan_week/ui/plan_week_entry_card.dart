import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/plan_week_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../add_to_checkers/model/retailer_switch.dart';
import '../../add_to_checkers/ui/retailer_logo.dart';
import '../../groceries/model/product_match.dart';
import '../../household/model/household_view.dart';
import '../../lunch_box/model/lunch_board.dart';
import '../../lunch_box/state/lunch_board_controller.dart';
import '../state/lunch_shop_choice.dart';

/// Whether *Plan the week* offers Twig, and at which shop (lunch-box
/// ADR-0012, ADR-0019, ADR-0026, ADR-0033): while its switch and a shop's
/// are on, on a week that has not gone.
abstract final class PlanWeekEntry {
  static ProductRetailer? shopFor(BuildContext context, LunchBoard board) {
    final flags = context.watch<FeatureFlagsController?>();
    final hasGone = board.today.isAfter(board.week.monday.addDays(6));
    if (flags == null || !flags.isOn(FeatureFlag.planMyWeek) || hasGone) {
      return null;
    }
    final shops = shopsOn(flags.isOn);
    return context.watch<LunchShopChoice?>()?.shopFor(shops) ??
        shops.firstOrNull;
  }

  static Future<void> open(BuildContext context) => context.push<void>(
    PlanWeekRoute.pathFor(context.read<HouseholdView>().household.id),
  );

  /// From a week whose school days have all gone: the board moves on a week
  /// and the flow starts again there, in this one's place.
  static void openNextWeek(BuildContext context) {
    context.read<LunchBoardController>().goToNextWeek();
    context.pushReplacement(
      PlanWeekRoute.pathFor(context.read<HouseholdView>().household.id),
    );
  }
}

/// Twig's way in *Plan the week*'s chooser, led by the chosen shop's logo
/// (ADR-0024, ADR-0026) and naming Twig in words (design-system ADR-0014).
class PlanWeekEntryCard extends StatelessWidget {
  const PlanWeekEntryCard({required this.shop, required this.onTap, super.key});

  final ProductRetailer shop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NestCard(
      variant: NestCardVariant.tinted,
      padding: EdgeInsets.zero,
      child: NestListRow(
        key: const ValueKey('plan-week-open'),
        title: PlanWeekCopy.entryTitle,
        subtitle: PlanWeekCopy.entryBody(shop),
        leading: RetailerLogo.decorative(
          retailer: shop,
          size: NestSize.logoMedium,
        ),
        trailing: const Icon(LucideIcons.chevronRight),
        onTap: onTap,
      ),
    );
  }
}

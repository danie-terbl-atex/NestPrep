import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/plan_week_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../add_to_checkers/ui/retailer_logo.dart';
import '../../groceries/model/product_match.dart';
import '../../household/model/household_view.dart';
import '../../lunch_box/model/lunch_board.dart';
import '../../lunch_box/ui/lunch_week_name.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/state/household_entitlement.dart';
import '../../subscriptions/ui/premium_gate.dart';
import '../state/lunch_shop_choice.dart';

/// *Plan my week* inside the lunch board's week planner
/// (lunch-box ADR-0012, ADR-0022): the one way in, for somebody who may
/// change lunches, while its switch is on (foundation ADR-0014), on a week
/// that has not gone, saying which week it will plan — the board's, by the
/// week bar's name for it (ADR-0019). One tinted row led by the chosen
/// shop's logo (ADR-0024, ADR-0026) and titled *Let Twig plan …* in words (design-system ADR-0014),
/// a quieter option beside *Fill the week* rather than a second hero. Premium says so on the row and opens the paywall first; the server
/// checks premium again (`FE-04`).
class PlanWeekEntryCard extends StatelessWidget {
  const PlanWeekEntryCard({
    required this.board,
    required this.canEdit,
    super.key,
  });

  final LunchBoard board;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final flags = context.watch<FeatureFlagsController?>();
    final isOn = flags?.isOn(FeatureFlag.planMyWeek) ?? false;
    final hasGone = board.today.isAfter(board.week.monday.addDays(6));
    if (!isOn || !canEdit || hasGone) return const SizedBox.shrink();
    final isPremium = context.watch<HouseholdEntitlement>().isPremium;
    final shop =
        context.watch<LunchShopChoice?>()?.shopFor(
          isPnpOn: flags?.isOn(FeatureFlag.addToPnp) ?? false,
        ) ??
        ProductRetailer.checkers;
    return Padding(
      padding: const EdgeInsets.only(top: NestSpace.md),
      child: NestCard(
        variant: NestCardVariant.tinted,
        padding: EdgeInsets.zero,
        child: NestListRow(
          key: const ValueKey('plan-week-open'),
          title: PlanWeekCopy.entryTitle(
            LunchWeekName.ofBoard(board).inSentence,
          ),
          subtitle: PlanWeekCopy.entryBody(shop),
          // The body already names the shop, and the row is the tap.
          leading: RetailerLogo.decorative(
            retailer: shop,
            size: NestSize.logoMedium,
          ),
          footer: isPremium
              ? null
              : const NestTag(
                  label: PlanWeekCopy.premiumTag,
                  tone: NestTagTone.accent,
                  icon: LucideIcons.award,
                ),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: () => _open(context),
        ),
      ),
    );
  }

  static Future<void> _open(BuildContext context) async {
    final router = GoRouter.of(context);
    final householdId = context.read<HouseholdView>().household.id;
    if (!await ensurePremium(context, feature: PremiumFeature.aiPlanning)) {
      return;
    }
    await router.push<void>(PlanWeekRoute.pathFor(householdId));
  }
}

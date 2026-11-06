import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../groceries/model/product_match.dart';
import '../../plan_week/ui/plan_week_entry_card.dart';
import '../model/lunch_plan_way.dart';

/// *Plan the week*'s chooser (lunch-box ADR-0033): one card per way, in the
/// order [LunchPlanWay.offered] gives. It only answers which way; the board
/// does the planning, because the sheet sits above the board's providers.
Future<LunchPlanWay?> showLunchPlanWeekSheet({
  required BuildContext context,
  required String week,
  required List<LunchPlanWay> ways,
  required ProductRetailer? shop,
  required bool isPremium,
}) => showNestSheet<LunchPlanWay>(
  context: context,
  title: LunchCopy.planWeekSheetTitle(week),
  builder: (context) => _Ways(ways: ways, shop: shop, isPremium: isPremium),
);

class _Ways extends StatelessWidget {
  const _Ways({
    required this.ways,
    required this.shop,
    required this.isPremium,
  });

  final List<LunchPlanWay> ways;
  final ProductRetailer? shop;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    void choose(LunchPlanWay way) => Navigator.of(context).pop(way);
    return ListView(
      shrinkWrap: true,
      children: [
        Text(LunchCopy.planWeekSheetBody, style: nest.text.bodySecondary),
        for (final way in ways) ...[
          const SizedBox(height: NestSpace.md),
          switch ((way, shop)) {
            (LunchPlanWay.twig, final ProductRetailer shop) =>
              PlanWeekEntryCard(
                shop: shop,
                isPremium: isPremium,
                onTap: () => choose(way),
              ),
            (LunchPlanWay.twig, null) => const SizedBox.shrink(),
            (LunchPlanWay.boxes, _) => _Way(
              key: const ValueKey('plan-week-boxes'),
              title: LunchCopy.planWithBoxes,
              body: LunchCopy.planWithBoxesBody,
              icon: LucideIcons.sandwich,
              tint: NestTileTint.butter,
              onTap: () => choose(way),
            ),
            (LunchPlanWay.pantry, _) => _Way(
              key: const ValueKey('plan-week-pantry'),
              title: LunchPantryCopy.fillFromPantry,
              body: LunchPantryCopy.fillFromPantryBody,
              icon: LucideIcons.refrigerator,
              tint: NestTileTint.basil,
              onTap: () => choose(way),
            ),
          },
        ],
      ],
    );
  }
}

class _Way extends StatelessWidget {
  const _Way({
    required this.title,
    required this.body,
    required this.icon,
    required this.tint,
    required this.onTap,
    super.key,
  });

  final String title;
  final String body;
  final IconData icon;
  final NestTileTint tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NestCard(
      variant: NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: NestListRow(
        title: title,
        subtitle: body,
        leading: NestIconTile(
          icon: icon,
          tint: tint,
          size: NestSize.logoMedium,
          iconSize: NestSize.iconMedium,
        ),
        trailing: const Icon(LucideIcons.chevronRight),
        onTap: onTap,
      ),
    );
  }
}

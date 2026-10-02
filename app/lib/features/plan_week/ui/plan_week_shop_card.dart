import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../add_to_checkers/ui/checkers_area_sheet.dart';
import '../state/plan_week_controller.dart';

/// The shop in the brief: Checkers Sixty60, where the search will look, and
/// a way to choose the area — the same area the grocery list's matches use,
/// kept on this phone (add-to-checkers ADR-0003).
class PlanWeekShopCard extends StatelessWidget {
  const PlanWeekShopCard({super.key});

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<PlanWeekController>();
    final place = controller.place;
    final where = switch (place) {
      null => PlanWeekCopy.shopFinding,
      _ when place.isDevice => PlanWeekCopy.shopNearYou,
      _ => PlanWeekCopy.shopNear(place.area!.label),
    };
    return NestCard(
      variant: NestCardVariant.flat,
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(PlanWeekCopy.shopHeader, style: nest.text.caption),
          const SizedBox(height: NestSpace.xs),
          Text(where, style: nest.text.title),
          Text(PlanWeekCopy.shopOnly, style: nest.text.bodySecondary),
          const SizedBox(height: NestSpace.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: NestButton(
              label: PlanWeekCopy.changeArea,
              icon: LucideIcons.mapPin,
              variant: NestButtonVariant.ghost,
              size: NestButtonSize.small,
              isExpanded: false,
              onPressed: () => showCheckersAreaSheet(
                context: context,
                current: place?.area,
                onChoose: controller.chooseArea,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

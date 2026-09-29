import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/lunch_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../../lunch_box/state/lunch_pantry_controller.dart';
import '../state/plan_week_controller.dart';

/// The week is in (lunch-box ADR-0011): a moment's celebration, what was
/// written, anything left out and why, then the shopping list — the new
/// dinners' ingredients, and the pantry's shortfall when planning from it —
/// each a tap, never automatic, and only for somebody the `groceries` grant
/// lets add to the list.
class PlanWeekDonePanel extends StatefulWidget {
  const PlanWeekDonePanel({super.key});

  @override
  State<PlanWeekDonePanel> createState() => _PlanWeekDonePanelState();
}

class _PlanWeekDonePanelState extends State<PlanWeekDonePanel> {
  /// Zero on the first frame, then one: the stars fly once, on arrival.
  int _burst = 0;
  int? _pantryAdded;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _burst = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<PlanWeekController>();
    final view = context.watch<HouseholdView>();
    final saved = controller.saved;
    final planned = controller.planned;
    if (saved == null || planned == null) return const SizedBox.shrink();
    final mayShop = view.permissions.canEdit(HouseholdArea.groceries);
    final ingredients = planned.ideaIngredients;
    final flags = context.watch<FeatureFlagsController?>();
    final hasPantry = flags?.isOn(FeatureFlag.lunchPantry) ?? false;
    final added = controller.groceriesAdded;
    final failure = controller.failure;

    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        const SizedBox(height: NestSpace.xl),
        Center(
          child: NestStarBurst(
            burst: _burst,
            child: const NestIconTile(
              icon: Icons.check_rounded,
              tint: NestTileTint.mint,
              size: NestSize.mark,
              iconSize: NestSize.iconMark,
            ),
          ),
        ),
        const SizedBox(height: NestSpace.xl),
        Semantics(
          liveRegion: true,
          child: Text(
            PlanWeekCopy.doneTitle,
            textAlign: TextAlign.center,
            style: nest.text.headline,
          ),
        ),
        const SizedBox(height: NestSpace.sm),
        Text(
          PlanWeekCopy.doneBody(saved.lunches, saved.dinners),
          textAlign: TextAlign.center,
          style: nest.text.bodySecondary,
        ),
        if (saved.skipped > 0) ...[
          const SizedBox(height: NestSpace.lg),
          NestBanner(
            message: PlanWeekCopy.skipped(saved.skipped),
            tone: NestBannerTone.warning,
          ),
        ],
        if (failure != null) ...[
          const SizedBox(height: NestSpace.lg),
          NestBanner(
            message: AppCopy.failure(failure),
            tone: NestBannerTone.danger,
            actionLabel: AppCopy.back,
            onAction: controller.dismissFailure,
          ),
        ],
        const SizedBox(height: NestSpace.xl),
        if (mayShop && ingredients.isNotEmpty)
          if (added == null)
            NestButton(
              key: const ValueKey('plan-week-groceries'),
              label: PlanWeekCopy.addIngredients(ingredients.length),
              icon: Icons.add_shopping_cart_rounded,
              variant: NestButtonVariant.tonal,
              isLoading: controller.isAddingGroceries,
              onPressed: controller.addIdeasToGroceries,
            )
          else
            NestBanner(
              message: PlanWeekCopy.ingredientsAdded(added),
              tone: NestBannerTone.success,
            ),
        if (mayShop && hasPantry && planned.lunchCount > 0) ...[
          const SizedBox(height: NestSpace.sm),
          _pantryAction(context),
        ],
        const SizedBox(height: NestSpace.xl),
        NestButton(
          label: PlanWeekCopy.seeLunches,
          icon: Icons.bento_outlined,
          onPressed: () => _toTheBoard(context, controller),
        ),
        const SizedBox(height: NestSpace.xs),
        NestButton(
          label: PlanWeekCopy.planAnother,
          variant: NestButtonVariant.ghost,
          size: NestButtonSize.small,
          onPressed: controller.startOver,
        ),
      ],
    );
  }

  Widget _pantryAction(BuildContext context) {
    final pantry = context.watch<LunchPantryController>();
    final added = _pantryAdded;
    if (added != null) {
      return NestBanner(
        message: LunchPantryCopy.addedToGroceries(added),
        tone: NestBannerTone.success,
      );
    }
    return NestButton(
      label: PlanWeekCopy.addPantryShortfall,
      icon: Icons.kitchen_outlined,
      variant: NestButtonVariant.outline,
      isLoading: pantry.isSending,
      onPressed: () async {
        final count = await pantry.sendShortfallToGroceries(
          quantityFor: LunchPantryCopy.forBoxes,
        );
        if (!mounted || count == null) return;
        setState(() => _pantryAdded = count);
      },
    );
  }

  /// Back to the board it was opened from, or to it when opened by link.
  static void _toTheBoard(BuildContext context, PlanWeekController controller) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(LunchRoute.pathFor(controller.householdId));
    }
  }
}

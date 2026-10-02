import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/lunch_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../state/plan_week_controller.dart';

/// Step 5 (lunch-box ADR-0012): the week is in — a moment's celebration,
/// what was written, anything left out and why, then the basket onto the
/// grocery list, each line matched at Checkers. A tap, never automatic, and
/// only for somebody the `groceries` grant lets add to the list.
class PlanWeekDonePanel extends StatefulWidget {
  const PlanWeekDonePanel({super.key});

  @override
  State<PlanWeekDonePanel> createState() => _PlanWeekDonePanelState();
}

class _PlanWeekDonePanelState extends State<PlanWeekDonePanel> {
  /// Zero on the first frame, then one: the stars fly once, on arrival.
  int _burst = 0;

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
    final shop = controller.shop;
    final saved = shop.saved;
    final plan = switch (shop.state) {
      AsyncData(:final value) => value,
      _ => null,
    };
    if (saved == null || plan == null) return const SizedBox.shrink();
    final mayShop = view.permissions.canEdit(HouseholdArea.groceries);
    final lines = plan.basket.lines.length;
    final added = shop.groceriesAdded;
    final failure = shop.failure;
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        const SizedBox(height: NestSpace.xl),
        Center(
          child: NestStarBurst(
            burst: _burst,
            child: const NestIconTile(
              icon: LucideIcons.check,
              tint: NestTileTint.basil,
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
          PlanWeekCopy.doneBody(saved.lunches),
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
        if (!saved.pricesSaved) ...[
          const SizedBox(height: NestSpace.lg),
          const NestBanner(
            message: PlanWeekCopy.pricesNotSaved,
            tone: NestBannerTone.warning,
          ),
        ],
        if (failure != null) ...[
          const SizedBox(height: NestSpace.lg),
          NestBanner(
            message: AppCopy.failure(failure),
            tone: NestBannerTone.danger,
            actionLabel: AppCopy.back,
            onAction: shop.dismissFailure,
          ),
        ],
        const SizedBox(height: NestSpace.xl),
        if (mayShop && lines > 0)
          if (added == null)
            NestButton(
              key: const ValueKey('plan-week-groceries'),
              label: PlanWeekCopy.addToGroceries(lines),
              icon: LucideIcons.shoppingCart,
              variant: NestButtonVariant.tonal,
              isLoading: shop.isAddingGroceries,
              onPressed: () => shop.addToGroceries(PlanWeekCopy.packs),
            )
          else
            NestBanner(
              message: PlanWeekCopy.groceriesAdded(added),
              tone: NestBannerTone.success,
            ),
        const SizedBox(height: NestSpace.xl),
        NestButton(
          label: PlanWeekCopy.seeLunches,
          icon: LucideIcons.sandwich,
          onPressed: () => _toTheBoard(context, controller),
        ),
        const SizedBox(height: NestSpace.xs),
        NestButton(
          label: PlanWeekCopy.planAgain,
          variant: NestButtonVariant.ghost,
          size: NestButtonSize.small,
          onPressed: controller.startOver,
        ),
      ],
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

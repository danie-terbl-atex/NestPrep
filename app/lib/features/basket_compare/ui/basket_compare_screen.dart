import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/household_route.dart';
import '../../../app/household_shell.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/basket_compare_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../../groceries/model/product_match.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../state/basket_compare_controller.dart';
import 'basket_compare_body.dart';

/// *Compare shops* (basket-compare ADR-0001), bound to its controller.
class BasketCompareScreen extends StatelessWidget {
  const BasketCompareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BasketCompareController>();
    final canEdit = context.watch<HouseholdView>().permissions.canEdit(
      HouseholdArea.groceries,
    );
    final failure = controller.actionFailure;
    return NestScaffold(
      title: BasketCompareCopy.title,
      leading: backLeading(context),
      body: BasketCompareBody(
        comparison: controller.comparison,
        onRetry: controller.retry,
        area: controller.place?.area?.label,
        leftOut: controller.leftOut,
        banner: failure == null
            ? null
            : NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.danger,
                actionLabel: AppCopy.back,
                onAction: controller.dismissActionFailure,
              ),
        useShop: canEdit
            ? UseShopActions(
                isApplying: controller.isApplying,
                hasMatchesAt: (shop) => controller.matchesWrittenBy(shop) > 0,
                onUse: (shop) => _use(context, controller, shop),
              )
            : null,
      ),
    );
  }

  Future<void> _use(
    BuildContext context,
    BasketCompareController controller,
    ProductRetailer shop,
  ) async {
    final replaced = controller.picksReplacedBy(shop);
    if (replaced > 0) {
      final confirmed = await showNestConfirm(
        context: context,
        title: BasketCompareCopy.confirmTitle(shop),
        message: BasketCompareCopy.confirmBody(shop, replaced),
        confirmLabel: BasketCompareCopy.confirmUse(shop),
        cancelLabel: BasketCompareCopy.keepPicks,
      );
      if (confirmed != true || !context.mounted) return;
    }
    final used = await controller.useShop(shop);
    if (!used || !context.mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(
        HouseholdRoute.pathFor(controller.householdId, HouseholdTab.groceries),
      );
    }
  }
}

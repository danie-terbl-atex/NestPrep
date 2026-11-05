import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/household_route.dart';
import '../../../app/household_shell.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../../shared/ui/back_leading.dart';
import '../../add_to_checkers/model/retailer_switch.dart';
import '../../groceries/model/product_match.dart';
import '../../recipes/ui/recipe_shop_sheet.dart';
import '../model/list_scan_line.dart';
import '../state/list_scan_controller.dart';
import 'list_added_panel.dart';
import 'list_line_sheet.dart';
import 'list_reading_panel.dart';
import 'list_review_panel.dart';
import 'list_source_panel.dart';

/// Snap a shopping list (list-scan ADR-0001): pick a photo, let the model
/// read it, then tick, change and add — by name, or found at the shop through
/// *Add to grocer*'s sheet. The screen only composes; every step is its
/// controller's.
class ListScanScreen extends StatelessWidget {
  const ListScanScreen({required this.memberId, super.key});

  final String memberId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ListScanController>();
    final flags = context.watch<FeatureFlagsController?>();
    final shops = flags == null
        ? const <ProductRetailer>[]
        : shopsOn(flags.isOn);
    return NestScaffold(
      leading: backLeading(context),
      title: ListScanCopy.title,
      body: NestTwigWarmUp(
        poses: const [
          NestTwigPose.welcome,
          NestTwigPose.thinking,
          NestTwigPose.celebrate,
        ],
        child: AnimatedSwitcher(
          duration: NestMotion.of(context).standard,
          child: KeyedSubtree(
            key: ValueKey(switch (controller.step) {
              ListScanStep.adding => ListScanStep.review,
              final step => step,
            }),
            child: switch (controller.step) {
              ListScanStep.choosing => ListSourcePanel(
                onPick: controller.pick,
                isAiWelcome: controller.isAiWelcome,
                failure: controller.failure,
                onRetry: controller.canRetry ? controller.retry : null,
              ),
              ListScanStep.reading => const ListReadingPanel(),
              ListScanStep.review || ListScanStep.adding => ListReviewPanel(
                lines: controller.lines,
                shops: shops,
                isAdding: controller.step == ListScanStep.adding,
                callsLeft: controller.callsLeft,
                failure: controller.failure,
                onDismissFailure: controller.dismissFailure,
                onToggle: controller.toggle,
                onChange: (line) => _change(context, controller, line),
                onAddToList: controller.addToList,
                onFindAtShop: () => _findAtShop(context, controller, shops),
                onStartOver: controller.startOver,
              ),
              ListScanStep.done => ListAddedPanel(
                added: controller.added,
                onBackToList: () => _backToList(context, controller),
                onSnapAnother: controller.startOver,
              ),
            },
          ),
        ),
      ),
    );
  }

  static Future<void> _change(
    BuildContext context,
    ListScanController controller,
    ListScanLine line,
  ) async {
    final edit = await showListLineSheet(context: context, line: line);
    switch (edit) {
      case ListLineChanged(:final name, :final quantity):
        controller.change(line.key, name: name, quantity: quantity);
      case ListLineLeftOff():
        controller.leaveOff(line.key);
      case null:
        break;
    }
  }

  Future<void> _findAtShop(
    BuildContext context,
    ListScanController controller,
    List<ProductRetailer> shops,
  ) async {
    final added = await showRecipeShopSheet(
      context,
      householdId: controller.householdId,
      memberId: memberId,
      shops: shops,
      lines: controller.shopLines,
    );
    controller.shopped(added);
  }

  static void _backToList(BuildContext context, ListScanController controller) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(
        HouseholdRoute.pathFor(controller.householdId, HouseholdTab.groceries),
      );
    }
  }
}

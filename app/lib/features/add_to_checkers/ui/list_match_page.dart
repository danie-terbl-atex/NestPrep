import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/list_match_copy.dart';
import '../../groceries/data/grocery_repository.dart';
import '../../groceries/model/grocery_item.dart';
import '../../groceries/model/product_match.dart';
import '../state/list_match_controller.dart';
import '../state/product_finder.dart';
import 'list_match_dock.dart';
import 'list_match_step.dart';
import 'list_match_summary.dart';
import 'retailer_logo.dart';

/// What the list does once the page has closed.
typedef ListMatchResult = ({List<GroceryItem> removed, bool wantsCart});

/// Matches [items] at [shop] one at a time, over the grocery list
/// (groceries ADR-0010). Searches through the list's own [ProductFinder],
/// so what the list already found is not asked for again.
Future<ListMatchResult> showListMatch(
  BuildContext context, {
  required String householdId,
  required String memberId,
  required ProductRetailer shop,
  required List<GroceryItem> items,
}) async {
  final controller = ListMatchController(
    finder: context.read<ProductFinder>(),
    groceryRepository: context.read<GroceryRepository>(),
    householdId: householdId,
    memberId: memberId,
    shop: shop,
    items: items,
  );
  final wantsCart = await Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: controller,
        child: const ListMatchPage(),
      ),
    ),
  );
  final result = (removed: controller.removed, wantsCart: wantsCart ?? false);
  controller.dispose();
  return result;
}

class ListMatchPage extends StatelessWidget {
  const ListMatchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ListMatchController>();
    final failure = controller.actionFailure;
    return NestScaffold(
      leading: NestIconButton(
        icon: LucideIcons.x,
        label: ListMatchCopy.close,
        variant: NestIconButtonVariant.plain,
        onPressed: () => Navigator.of(context).pop(false),
      ),
      title: ListMatchCopy.title,
      trailing: [RetailerLogo.decorative(retailer: controller.shop)],
      bottomBar: NestDock(
        child: controller.isDone
            ? const ListMatchSummaryActions()
            : const ListMatchDock(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Progress(),
          const SizedBox(height: NestSpace.md),
          if (failure != null) ...[
            NestBanner(
              message: AppCopy.failure(failure),
              tone: NestBannerTone.danger,
              actionLabel: AppCopy.back,
              onAction: controller.dismissActionFailure,
            ),
            const SizedBox(height: NestSpace.md),
          ],
          Expanded(
            child: AnimatedSwitcher(
              duration: NestMotion.of(context).standard,
              switchInCurve: NestMotion.enter,
              switchOutCurve: NestMotion.exit,
              child: KeyedSubtree(
                key: ValueKey(controller.index),
                child: controller.isDone
                    ? const ListMatchSummary()
                    : const ListMatchStep(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress();

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<ListMatchController>();
    final total = controller.items.length;
    final label = controller.isDone
        ? ListMatchCopy.allDone(total)
        : ListMatchCopy.step(controller.index, total);
    final picked = ListMatchCopy.picked(controller.pickedCount);
    final shown = controller.isDone ? total : controller.index + 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(NestRadius.pill),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: total == 0 ? 0 : shown / total),
              duration: NestMotion.of(context).slow,
              curve: NestMotion.enter,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: NestSpace.xs,
                backgroundColor: nest.colors.surfaceTint,
                color: nest.colors.accent,
              ),
            ),
          ),
        ),
        const SizedBox(height: NestSpace.xs),
        Row(
          children: [
            Visibility.maintain(
              visible: controller.canGoBack,
              child: NestIconButton(
                icon: LucideIcons.chevronLeft,
                label: ListMatchCopy.previous,
                variant: NestIconButtonVariant.plain,
                onPressed: controller.back,
              ),
            ),
            Expanded(
              child: Semantics(
                liveRegion: true,
                label: '$label, $picked',
                excludeSemantics: true,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: NestSpace.md,
                  children: [
                    Text(label, style: nest.text.label),
                    Text(
                      picked,
                      style: nest.text.caption.copyWith(
                        color: nest.colors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

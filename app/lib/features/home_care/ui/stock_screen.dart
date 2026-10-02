import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/home_care_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/flags/feature_flag.dart';
import '../../../shared/ui/back_leading.dart';
import '../model/home_care_board.dart';
import '../model/home_care_product.dart';
import '../state/home_care_controller.dart';
import 'stock_row.dart';
import 'switched_off_view.dart';

/// How much of each product is left (home-care ADR-0005): what is running
/// low first — each already on its way to the grocery list — then the rest
/// of the cupboard. A helper marks what she sees; the server puts a low one
/// on the list once.
class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeCareController>();
    final canManage = controller.access.canManage;
    final failure = controller.actionFailure;
    return NestScaffold(
      title: HomeCareStockCopy.stock,
      subtitle: HomeCareStockCopy.subtitle,
      leading: backLeading(context),
      body: SwitchedOffView(
        flag: FeatureFlag.homeCareStock,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (failure != null)
              Padding(
                padding: const EdgeInsets.only(bottom: NestSpace.lg),
                child: NestBanner(
                  message: AppCopy.failure(failure),
                  tone: NestBannerTone.danger,
                  actionLabel: AppCopy.back,
                  onAction: controller.dismissActionFailure,
                ),
              ),
            Expanded(
              child: NestAsyncView<HomeCareBoard>(
                state: controller.board,
                isEmpty: (board) => board.products.isEmpty,
                onRetry: controller.retry,
                emptyBuilder: (_) => NestEmptyView(
                  title: HomeCareStockCopy.emptyTitle,
                  message: canManage
                      ? HomeCareStockCopy.emptyBody
                      : HomeCareStockCopy.emptyHelperBody,
                  icon: LucideIcons.clipboardList,
                  actionLabel: canManage
                      ? HomeCareStockCopy.openProducts
                      : null,
                  onAction: canManage
                      ? () => context.push(
                          HomeCareRoute.productsPathFor(controller.householdId),
                        )
                      : null,
                ),
                dataBuilder: (context, board) =>
                    _StockList(board: board, controller: controller),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockList extends StatelessWidget {
  const _StockList({required this.board, required this.controller});

  final HomeCareBoard board;
  final HomeCareController controller;

  @override
  Widget build(BuildContext context) {
    final products = board.productsByName;
    final low = [
      for (final product in products)
        if (product.stock.isRunningOut) product,
    ];
    final rest = [
      for (final product in products)
        if (!product.stock.isRunningOut) product,
    ];
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        if (low.isNotEmpty) ...[
          const NestSectionHeader(title: HomeCareStockCopy.runningOut),
          ..._rows(low),
        ],
        if (rest.isNotEmpty) ...[
          const NestSectionHeader(title: HomeCareStockCopy.inTheCupboard),
          ..._rows(rest),
        ],
      ],
    );
  }

  Iterable<Widget> _rows(List<HomeCareProduct> products) sync* {
    for (final (index, product) in products.indexed) {
      final by = product.stockChangedBy;
      yield NestRiseIn(
        key: ValueKey(product.id),
        index: index.clamp(0, 6),
        child: Padding(
          padding: const EdgeInsets.only(bottom: NestSpace.md),
          child: StockRow(
            product: product,
            markedBy: by == null ? null : board.memberById(by)?.displayName,
            onMark: (level) => controller.library.setStock(product.id, level),
          ),
        ),
      );
    }
  }
}

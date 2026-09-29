import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../model/home_care_board.dart';
import '../model/home_care_product.dart';
import '../model/safety/job_safety.dart';
import '../state/home_care_controller.dart';
import 'product_row.dart';
import 'product_sheet.dart';
import 'safety_panel.dart';

/// The household's product library (home-care ADR-0002): what is in the
/// cupboard, what kind each is, and where it is kept. A parent keeps it; a
/// helper opens any product to read how to use it safely.
class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeCareController>();
    final canManage = controller.access.canManage;
    final failure = controller.actionFailure;
    return NestScaffold(
      title: HomeCareLibraryCopy.products,
      subtitle: HomeCareLibraryCopy.productsSubtitle,
      leading: backLeading(context),
      trailing: [
        if (canManage)
          NestIconButton(
            icon: Icons.add,
            label: HomeCareLibraryCopy.addProduct,
            onPressed: () => _edit(context, controller, null),
          ),
      ],
      body: Column(
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
                title: HomeCareLibraryCopy.productsEmptyTitle,
                message: canManage
                    ? HomeCareLibraryCopy.productsEmptyBody
                    : HomeCareLibraryCopy.productsEmptyHelperBody,
                icon: Icons.sanitizer_outlined,
                actionLabel: canManage ? HomeCareLibraryCopy.addProduct : null,
                onAction: canManage
                    ? () => _edit(context, controller, null)
                    : null,
              ),
              dataBuilder: (context, board) {
                final products = board.productsByName;
                return ListView.separated(
                  itemCount: products.length,
                  padding: const EdgeInsets.only(bottom: NestSpace.huge),
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: NestSpace.sm),
                  itemBuilder: (context, index) => ProductRow(
                    product: products[index],
                    onTap: canManage
                        ? () => _edit(context, controller, products[index])
                        : () => _readSafety(context, products[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _edit(
    BuildContext context,
    HomeCareController controller,
    HomeCareProduct? product,
  ) async {
    final outcome = await showProductSheet(context: context, product: product);
    switch (outcome) {
      case null:
        return;
      case ProductSaved(product: final saved):
        await controller.library.saveProduct(saved);
      case ProductDeleted():
        if (product == null || !context.mounted) return;
        final isSure = await showNestConfirm(
          context: context,
          title: HomeCareLibraryCopy.deleteProductConfirm,
          message: HomeCareLibraryCopy.deleteProductBody,
          confirmLabel: HomeCareLibraryCopy.deleteProduct,
          cancelLabel: AppCopy.householdCancel,
          isDangerous: true,
        );
        if (isSure ?? false) {
          await controller.library.deleteProduct(product.id);
        }
    }
  }

  /// A helper's view of one product: how to use it safely.
  static Future<void> _readSafety(
    BuildContext context,
    HomeCareProduct product,
  ) => showNestSheet<void>(
    context: context,
    title: product.name,
    builder: (context) => SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: NestSpace.xl),
      child: SafetyPanel(safety: JobSafety.of([product])),
    ),
  );
}

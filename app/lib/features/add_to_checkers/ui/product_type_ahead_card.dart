import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/checkers_copy.dart';
import '../model/retailer_product.dart';
import '../state/product_type_ahead_controller.dart';
import 'product_suggestion_row.dart';
import 'products_message.dart';

/// The chosen shop's products for what is in the add field, at the top of
/// the list while somebody types (add-to-checkers ADR-0007). [onAdd] adds
/// the typed name with that product; [onJustAdd] adds the name alone, as the
/// field's own + does. It scrolls with the list, so at 200% text it never
/// pushes the list out from under the field.
class ProductTypeAheadCard extends StatelessWidget {
  const ProductTypeAheadCard({
    required this.onAdd,
    required this.onJustAdd,
    this.isAdding = false,
    super.key,
  });

  final ValueChanged<RetailerProduct> onAdd;
  final VoidCallback onJustAdd;

  /// True while a pick is being added, so a second tap waits.
  final bool isAdding;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProductTypeAheadController>();
    final query = controller.query;
    if (query == null) return const SizedBox.shrink();
    final nest = NestTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.lg),
      child: NestCard(
        variant: NestCardVariant.tinted,
        padding: const EdgeInsets.symmetric(vertical: NestSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: NestSpace.lg),
              child: Text(
                CheckersCopy.typeAheadTitle(query.shop, query.text),
                style: nest.text.bodyStrong,
              ),
            ),
            switch (controller.products) {
              AsyncLoading() => Padding(
                padding: const EdgeInsets.all(NestSpace.lg),
                child: ProductsLoading(shop: query.shop),
              ),
              AsyncFailure(:final failure) => Padding(
                padding: const EdgeInsets.all(NestSpace.lg),
                child: ProductsMessage(
                  message: AppCopy.failure(failure),
                  actionLabel: CheckersCopy.retry,
                  onAction: controller.retry,
                ),
              ),
              AsyncData(value: final products) when products.isEmpty => Padding(
                padding: const EdgeInsets.all(NestSpace.lg),
                child: ProductsMessage(
                  title: CheckersCopy.matchesEmptyTitle(query.shop),
                  message: CheckersCopy.matchesEmptyBody(query.shop),
                ),
              ),
              AsyncData(value: final products) => Column(
                children: [
                  for (final product in products)
                    ProductSuggestionRow(
                      key: ValueKey('${product.storeId}/${product.id}'),
                      product: product,
                      isBestMatch: product.id == controller.bestMatchId,
                      onAdd: isAdding ? null : () => onAdd(product),
                    ),
                ],
              ),
            },
            NestListRow(
              leading: const SizedBox.square(
                dimension: ProductSuggestionRow.imageSize,
                child: Icon(LucideIcons.plus),
              ),
              title: CheckersCopy.justAdd(query.text),
              onTap: isAdding ? null : onJustAdd,
            ),
          ],
        ),
      ),
    );
  }
}

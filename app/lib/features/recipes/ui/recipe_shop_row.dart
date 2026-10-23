import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/checkers_copy.dart';
import '../../add_to_checkers/ui/retailer_product_image.dart';
import '../../groceries/model/product_match.dart';
import '../model/recipe_shop_line.dart';

/// One ingredient in *Add to grocer*: a box saying whether it goes on the
/// list, the ingredient and how much, then what the shop had for it — the
/// product to buy with its price and a way to change it, a placeholder while
/// it is looked for, or why it goes on by name. Left off, it reads quieter
/// and its box is empty, so the state is never only a colour (`FE-13`).
/// Renders what it is given and reports taps (`FE-03`).
class RecipeShopRow extends StatelessWidget {
  const RecipeShopRow({
    required this.line,
    required this.shop,
    required this.onToggle,
    required this.onChange,
    super.key,
  });

  final RecipeShopLine line;
  final ProductRetailer shop;

  /// Null once the lines are on the list.
  final VoidCallback? onToggle;
  final VoidCallback? onChange;

  static const imageSize = 44.0;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final quantity = line.quantity;
    final ink = line.isIncluded ? c.ink : c.inkTertiary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NestSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            checked: line.isIncluded,
            enabled: onToggle != null,
            label: RecipeShopCopy.includeLabel(line.name, line.isIncluded),
            excludeSemantics: true,
            onTap: onToggle,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(NestRadius.sm),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: NestSize.touchTarget,
                ),
                child: Row(
                  children: [
                    _Box(isOn: line.isIncluded),
                    const SizedBox(width: NestSpace.md),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: line.name,
                              style: nest.text.bodyStrong.copyWith(color: ink),
                            ),
                            if (quantity != null)
                              TextSpan(
                                text: '  $quantity',
                                style: nest.text.caption.copyWith(
                                  color: c.inkSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: NestSize.iconMedium + NestSpace.md,
            ),
            child: AnimatedOpacity(
              duration: NestMotion.of(context).quick,
              opacity: line.isIncluded ? 1 : 0.5,
              child: _Found(line: line, shop: shop, onChange: onChange),
            ),
          ),
        ],
      ),
    );
  }
}

/// What the shop had for the line.
class _Found extends StatelessWidget {
  const _Found({required this.line, required this.shop, this.onChange});

  final RecipeShopLine line;
  final ProductRetailer shop;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final note = nest.text.caption.copyWith(color: nest.colors.inkSecondary);
    final product = line.chosen;
    if (!line.isSettled) {
      return const NestSkeleton(height: RecipeShopRow.imageSize);
    }
    if (product == null) {
      return Text(
        line.search == RecipeShopSearch.failed
            ? RecipeShopCopy.failed
            : RecipeShopCopy.notFound(shop),
        style: note,
      );
    }
    final canChange = onChange != null && line.products.length > 1;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RetailerProductImage(
          retailer: product.retailer,
          imageId: product.imageId,
          size: RecipeShopRow.imageSize,
        ),
        const SizedBox(width: NestSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.name, style: nest.text.body),
              const SizedBox(height: NestSpace.xxs),
              Wrap(
                spacing: NestSpace.sm,
                runSpacing: NestSpace.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    CheckersCopy.price(product.price, perKilogram: false),
                    style: nest.text.label,
                  ),
                  if (product.isOnPromotion)
                    const NestTag(
                      label: CheckersCopy.deal,
                      tone: NestTagTone.accent,
                    ),
                  if (canChange)
                    NestButton(
                      label: RecipeShopCopy.change,
                      variant: NestButtonVariant.link,
                      size: NestButtonSize.small,
                      isExpanded: false,
                      onPressed: onChange,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The square box of a line that goes on the list — a check when it does,
/// empty when it is left off.
class _Box extends StatelessWidget {
  const _Box({required this.isOn});

  final bool isOn;

  @override
  Widget build(BuildContext context) {
    final c = NestTheme.of(context).colors;
    return AnimatedContainer(
      duration: NestMotion.of(context).quick,
      width: NestSize.iconMedium,
      height: NestSize.iconMedium,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(NestRadius.xs),
        color: isOn ? c.accentInk : Colors.transparent,
        border: Border.all(
          color: isOn ? c.accentInk : c.outlineStrong,
          width: NestStroke.focus,
        ),
      ),
      child: isOn
          ? Icon(LucideIcons.check, size: NestSize.iconBadge, color: c.canvas)
          : null,
    );
  }
}

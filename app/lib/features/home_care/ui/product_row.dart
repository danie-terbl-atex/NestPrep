import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/home_care_product.dart';
import '../model/safety/safety_catalogue.dart';
import 'product_kind_look.dart';

/// One product: what the household calls it, what kind it is, where it is
/// kept, and — at a glance — whether it needs care.
class ProductRow extends StatelessWidget {
  const ProductRow({required this.product, required this.onTap, super.key});

  final HomeCareProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final kept = product.whereKept;
    return NestCard(
      variant: NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: NestListRow(
        title: product.name,
        subtitle: kept == null
            ? HomeCareLibraryCopy.productKindName(product.kind)
            : HomeCareLibraryCopy.kindAndPlace(
                HomeCareLibraryCopy.productKindName(product.kind),
                kept,
              ),
        leading: NestIconTile(
          icon: product.kind.icon,
          tint: product.kind.tint,
          size: NestSize.avatarMedium,
          iconSize: NestSize.iconMedium,
        ),
        trailing: SafetyCatalogue.isHazardous(product.kind)
            ? Semantics(
                label: HomeCareSafetyCopy.needsCare,
                child: Icon(
                  LucideIcons.triangleAlert,
                  color: nest.colors.warning,
                ),
              )
            : const Icon(LucideIcons.chevronRight),
        onTap: onTap,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/home_care_product.dart';
import 'product_kind_look.dart';

/// What to clean it with, and where to find it — so the helper does not
/// have to ask.
class JobProductsList extends StatelessWidget {
  const JobProductsList({required this.products, super.key});

  final List<HomeCareProduct> products;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    if (products.isEmpty) {
      return Text(HomeCareCopy.noProductsOnJob, style: nest.text.caption);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final product in products)
          NestListRow(
            title: product.name,
            subtitle: HomeCareLibraryCopy.kindAndPlace(
              HomeCareLibraryCopy.productKindName(product.kind),
              product.whereKept ?? HomeCareLibraryCopy.placeUnknown,
            ),
            leading: NestIconTile(
              icon: product.kind.icon,
              tint: product.kind.tint,
              size: NestSize.avatarMedium,
              iconSize: NestSize.iconMedium,
            ),
          ),
      ],
    );
  }
}

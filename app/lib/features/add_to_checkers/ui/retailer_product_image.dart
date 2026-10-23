import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../groceries/model/product_match.dart';
import '../model/retailer_image_url.dart';

/// A shop product's picture at a fixed [size], with a placeholder while it
/// loads and when there is none (`FE-18`). `Image.network` on purpose — no
/// image-cache dependency (the Checkers images ADR).
class RetailerProductImage extends StatelessWidget {
  const RetailerProductImage({
    required this.retailer,
    required this.imageId,
    required this.size,
    super.key,
  });

  final ProductRetailer retailer;
  final String? imageId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final placeholder = ColoredBox(
      color: nest.colors.surfaceTint,
      child: Icon(
        LucideIcons.shoppingBasket,
        size: size / 2,
        color: nest.colors.inkTertiary,
      ),
    );
    final id = imageId;
    final url = id == null ? null : retailerImageUrl(retailer, id);
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(NestRadius.sm),
        child: SizedBox.square(
          dimension: size,
          child: url == null
              ? placeholder
              : Image.network(
                  url.toString(),
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                  cacheWidth: (size * 3).round(),
                  loadingBuilder: (context, child, progress) =>
                      progress == null ? child : placeholder,
                  errorBuilder: (context, error, stack) => placeholder,
                ),
        ),
      ),
    );
  }
}

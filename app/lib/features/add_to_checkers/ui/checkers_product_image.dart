import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../model/checkers_image.dart';

/// A Checkers product's picture at a fixed [size], with a placeholder while it
/// loads and when there is none (`FE-18`). `Image.network` on purpose — no
/// image-cache dependency (the Checkers images ADR).
class CheckersProductImage extends StatelessWidget {
  const CheckersProductImage({
    required this.imageId,
    required this.size,
    super.key,
  });

  final String? imageId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final placeholder = ColoredBox(
      color: nest.colors.surfaceTint,
      child: Icon(
        Icons.shopping_basket_outlined,
        size: size / 2,
        color: nest.colors.inkTertiary,
      ),
    );
    final id = imageId;
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(NestRadius.sm),
        child: SizedBox.square(
          dimension: size,
          child: id == null
              ? placeholder
              : Image.network(
                  checkersImageUrl(id).toString(),
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

import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/checkers_copy.dart';
import '../../groceries/model/product_match.dart';
import 'checkers_product_tile.dart';

/// A shop's products on their way: three tiles' worth of skeleton.
class ProductsLoading extends StatelessWidget {
  const ProductsLoading({required this.shop, super.key});

  final ProductRetailer shop;

  @override
  Widget build(BuildContext context) => Semantics(
    label: CheckersCopy.matchesLoading(shop),
    child: const Column(
      children: [
        NestSkeleton(height: CheckersProductTile.imageSize),
        SizedBox(height: NestSpace.sm),
        NestSkeleton(height: CheckersProductTile.imageSize),
        SizedBox(height: NestSpace.sm),
        NestSkeleton(height: CheckersProductTile.imageSize),
      ],
    ),
  );
}

/// Instead of products: nothing close, or a failure with its retry.
class ProductsMessage extends StatelessWidget {
  const ProductsMessage({
    required this.message,
    this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String? title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final heading = title;
    final label = actionLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (heading != null) Text(heading, style: nest.text.label),
        Text(message, style: nest.text.bodySecondary),
        if (label != null) ...[
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: label,
            variant: NestButtonVariant.outline,
            size: NestButtonSize.small,
            isExpanded: false,
            onPressed: onAction,
          ),
        ],
      ],
    );
  }
}

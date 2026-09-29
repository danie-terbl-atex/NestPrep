import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/product_kind.dart';
import 'product_kind_look.dart';

/// Chooses what kind of product something is, with a line of examples under
/// the choice — because the kind is what the safety warnings are read from,
/// and a wrong kind is a wrong warning (home-care ADR-0002).
class ProductKindPicker extends StatelessWidget {
  const ProductKindPicker({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final ProductKind selected;
  final ValueChanged<ProductKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          HomeCareLibraryCopy.productKind,
          style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
        ),
        const SizedBox(height: NestSpace.sm),
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            for (final kind in ProductKind.values)
              NestChip(
                label: HomeCareLibraryCopy.productKindName(kind),
                icon: kind.icon,
                isSelected: kind == selected,
                onTap: () => onChanged(kind),
              ),
          ],
        ),
        const SizedBox(height: NestSpace.sm),
        Text(
          HomeCareLibraryCopy.productKindExamples(selected),
          style: nest.text.caption,
        ),
      ],
    );
  }
}

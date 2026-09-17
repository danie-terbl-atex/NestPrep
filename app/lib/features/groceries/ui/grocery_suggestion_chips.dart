import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/grocery_suggestion.dart';

/// The household's own buying history, one tap away. There is no product
/// catalogue and no staples list to maintain: what they buy often *is* the
/// staples list (groceries ADR-0001).
class GrocerySuggestionChips extends StatelessWidget {
  const GrocerySuggestionChips({
    required this.suggestions,
    required this.onTap,
    super.key,
  });

  final List<GrocerySuggestion> suggestions;
  final ValueChanged<GrocerySuggestion> onTap;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppCopy.groceriesOften,
          style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
        ),
        const SizedBox(height: NestSpace.sm),
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            for (final suggestion in suggestions)
              NestChip(
                label: suggestion.name,
                icon: Icons.add,
                onTap: () => onTap(suggestion),
              ),
          ],
        ),
      ],
    );
  }
}

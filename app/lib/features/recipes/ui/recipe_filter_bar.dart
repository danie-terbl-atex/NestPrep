import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/recipe_facet.dart';
import '../model/recipe_filter.dart';
import '../model/recipe_meal_filter.dart';

/// What can be asked of the recipes: words, a meal, a kind of dish. It shows
/// [filter] and reports each change; it decides nothing about what matches
/// (`FE-04`). The chips scroll sideways, so a long list never pushes the
/// recipes down at a large text setting (`FE-14`).
class RecipeFilterBar extends StatefulWidget {
  const RecipeFilterBar({
    required this.filter,
    required this.meals,
    required this.facets,
    required this.onSearch,
    required this.onMeal,
    required this.onFacet,
    super.key,
  });

  final RecipeFilter filter;

  /// The chips worth offering — only those that would find something.
  final List<RecipeMealFilter> meals;
  final List<RecipeFacet> facets;
  final ValueChanged<String> onSearch;
  final ValueChanged<RecipeMealFilter> onMeal;
  final ValueChanged<RecipeFacet> onFacet;

  @override
  State<RecipeFilterBar> createState() => _RecipeFilterBarState();
}

class _RecipeFilterBarState extends State<RecipeFilterBar> {
  late final _query = TextEditingController(text: widget.filter.query);

  @override
  void didUpdateWidget(RecipeFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Cleared from outside — "Show all recipes" — so the field says so too.
    if (widget.filter.query != _query.text) _query.text = widget.filter.query;
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _clear() {
    _query.clear();
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    final filter = widget.filter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestTextField(
          label: RecipeCopy.searchLabel,
          hint: RecipeCopy.searchHint,
          controller: _query,
          prefixIcon: LucideIcons.search,
          textInputAction: TextInputAction.search,
          onChanged: widget.onSearch,
          suffix: filter.query.isEmpty
              ? null
              : NestIconButton(
                  icon: LucideIcons.x,
                  label: RecipeCopy.clearSearch,
                  variant: NestIconButtonVariant.plain,
                  onPressed: _clear,
                ),
        ),
        const SizedBox(height: NestSpace.md),
        _ChipRow(
          chips: [
            for (final meal in widget.meals)
              NestChip(
                label: RecipeCopy.meal(meal),
                isSelected: filter.meal == meal,
                onTap: () => widget.onMeal(meal),
              ),
          ],
        ),
        if (widget.facets.isNotEmpty) ...[
          const SizedBox(height: NestSpace.sm),
          _ChipRow(
            chips: [
              for (final facet in widget.facets)
                NestChip(
                  label: RecipeCopy.facet(facet),
                  isSelected: filter.facet == facet,
                  trailingIcon: filter.facet == facet ? LucideIcons.x : null,
                  onTap: () => widget.onFacet(facet),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.chips});

  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final (index, chip) in chips.indexed) ...[
            if (index > 0) const SizedBox(width: NestSpace.sm),
            chip,
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/recipe.dart';
import '../model/recipe_catalogue.dart';
import '../model/recipe_discovery.dart';
import '../state/recipe_catalogue_controller.dart';
import 'recipe_discovery_skeleton.dart';
import 'recipe_filter_bar.dart';
import 'recipe_grid_row.dart';
import 'recipe_shelf_row.dart';
import 'recipe_tonight_card.dart';

/// The Meals tab's *Recipes* (recipes ADR-0003): search, the meal and
/// kind-of-dish chips, then — with nothing asked — tonight's dinner, the
/// shelves and every recipe; with something asked, what matches.
///
/// Its four states (`FE-08`): the layout held while the catalogue loads; a
/// failure with a retry; a catalogue with nothing published yet; and — the
/// one people meet most — "nothing matches", said *under* the controls that
/// can change it, never instead of them. Where a recipe opens is the
/// screen's to decide (`FE-17`).
class RecipeDiscoveryView extends StatelessWidget {
  const RecipeDiscoveryView({required this.onOpen, super.key});

  final ValueChanged<Recipe> onOpen;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RecipeCatalogueController>();
    final discovery = controller.discovery;
    return switch (controller.catalogue) {
      AsyncLoading() => const RecipeDiscoverySkeleton(),
      AsyncFailure(:final failure) => NestErrorView(
        message: AppCopy.failure(failure),
        retryLabel: AppCopy.retry,
        onRetry: controller.retry,
      ),
      AsyncData(:final value) when value.isEmpty => const NestEmptyView(
        icon: LucideIcons.cookingPot,
        title: RecipeCopy.emptyTitle,
        message: RecipeCopy.emptyMessage,
      ),
      AsyncData(:final value) when discovery != null => _Discovery(
        catalogue: value,
        discovery: discovery,
        controller: controller,
        onOpen: onOpen,
      ),
      AsyncData() => const RecipeDiscoverySkeleton(),
    };
  }
}

class _Discovery extends StatelessWidget {
  const _Discovery({
    required this.catalogue,
    required this.discovery,
    required this.controller,
    required this.onOpen,
  });

  final RecipeCatalogue catalogue;
  final RecipeDiscovery discovery;
  final RecipeCatalogueController controller;
  final ValueChanged<Recipe> onOpen;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final filter = discovery.filter;
    final results = discovery.results;
    final tonight = discovery.tonight;
    final columns = RecipeGridRow.columnsFor(context);
    final rows = (results.length / columns).ceil();
    return CustomScrollView(
      // A search field above a list that moves under it.
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: RecipeFilterBar(
            filter: filter,
            meals: catalogue.meals,
            facets: catalogue.facets,
            onSearch: controller.search,
            onMeal: controller.selectMeal,
            onFacet: controller.toggleFacet,
          ),
        ),
        if (tonight != null)
          SliverPadding(
            padding: const EdgeInsets.only(top: NestSpace.xxl),
            sliver: SliverToBoxAdapter(
              child: RecipeTonightCard(
                recipe: tonight,
                onOpen: () => onOpen(tonight),
              ),
            ),
          ),
        for (final shelf in discovery.shelves)
          SliverPadding(
            padding: const EdgeInsets.only(top: NestSpace.huge),
            sliver: SliverToBoxAdapter(
              child: RecipeShelfRow(shelf: shelf, onOpen: onOpen),
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.only(
            top: filter.isActive ? NestSpace.xl : NestSpace.huge,
            bottom: NestSpace.md,
          ),
          sliver: SliverToBoxAdapter(
            child: filter.isActive
                ? Text(
                    RecipeCopy.matchCount(results.length),
                    style: nest.text.label.copyWith(
                      color: nest.colors.inkSecondary,
                    ),
                  )
                : const NestSectionHeader(title: RecipeCopy.allRecipes),
          ),
        ),
        if (results.isEmpty)
          SliverToBoxAdapter(
            child: NestEmptyView(
              icon: LucideIcons.searchX,
              title: RecipeCopy.noMatchesTitle,
              message: RecipeCopy.noMatchesMessage,
              actionLabel: RecipeCopy.showEverything,
              onAction: controller.clearFilter,
            ),
          )
        else
          // Built a row at a time as it scrolls in (`FE-11`).
          SliverList.separated(
            itemCount: rows,
            separatorBuilder: (_, _) => const SizedBox(height: NestSpace.xl),
            itemBuilder: (context, row) => RecipeGridRow(
              key: ValueKey('row-$row-$columns'),
              recipes: results
                  .skip(row * columns)
                  .take(columns)
                  .toList(growable: false),
              columns: columns,
              onOpen: onOpen,
            ),
          ),
        // Clear of the floating bar, so the last row can be reached
        // (`FE-14`).
        const SliverToBoxAdapter(
          child: SizedBox(height: NestSize.bottomBarHeight + NestSpace.huge),
        ),
      ],
    );
  }
}

import 'package:flutter/foundation.dart';

import '../../family_profiles/model/allergen.dart';
import '../../family_profiles/model/food_rules.dart';
import '../../recipes/model/recipe.dart';
import 'lunch_concern.dart';
import 'lunch_favourite.dart';
import 'lunch_item.dart';
import 'lunch_pick.dart';
import 'lunch_safety.dart';
import 'lunch_slot.dart';
import 'lunch_starter_box.dart';
import 'starter_box_item.dart';

/// Whose box it is: the household's own go-to box for this child, or one
/// NestPrep made (lunch-box ADR-0020 §6).
enum FillWeekBoxKind { goTo, readyMade }

/// One compartment of a box on offer in *Fill the week*, as it would go in
/// this child's box: the pick, the recipe behind it when there is one, and
/// why it cannot go in — empty when it can.
@immutable
final class FillWeekCompartment {
  FillWeekCompartment({
    required this.slot,
    required this.pick,
    required this.recipe,
    required List<LunchConcern> unsafe,
    this.isRecipe = false,
  }) : unsafe = List.unmodifiable(unsafe);

  final LunchSlot slot;
  final LunchPick pick;

  /// Null for a quick pick, a go-to box's item, or a recipe that could not
  /// be read.
  final Recipe? recipe;

  /// A ready-made compartment made from a recipe, read or not.
  final bool isRecipe;
  final List<LunchConcern> unsafe;

  bool get isSafe => unsafe.isEmpty;
}

/// A box a parent may choose for one child's week in *Fill the week*
/// (lunch-box ADR-0020): its compartments in packing order, each already
/// checked against the child with the board's own food-rule check.
///
/// A go-to box with anything unsafe in it cannot be chosen (ADR-0003). A
/// ready-made box can: its unsafe compartments are left for NestPrep to fill
/// with a safe suggestion, and its treat goes in on Fridays only (ADR-0018
/// §4, kept).
@immutable
final class FillWeekBox {
  FillWeekBox({
    required this.id,
    required this.kind,
    required this.name,
    required this.blurb,
    required List<FillWeekCompartment> compartments,
    Map<String, LunchItem> candidates = const {},
  }) : compartments = List.unmodifiable(compartments),
       candidates = Map.unmodifiable(candidates);

  /// A household's go-to box, its picks as the library has them now.
  factory FillWeekBox.goTo(
    LunchFavourite favourite, {
    required FoodRules rules,
    required Map<String, LunchItem> library,
  }) => FillWeekBox(
    id: goToId(favourite.id),
    kind: FillWeekBoxKind.goTo,
    name: favourite.name,
    blurb: '',
    compartments: [
      for (final (slot, saved) in favourite.box.filled)
        _compartment(
          slot: slot,
          pick: switch (library[saved.itemId]) {
            final item? => LunchPick.of(item),
            null => saved,
          },
          also: saved.knownAllergens,
          rules: rules,
        ),
    ],
  );

  /// One of NestPrep's ready-made boxes, each compartment the library item
  /// it becomes (`StarterBoxItem`) — the household's own where it has one.
  factory FillWeekBox.readyMade(
    LunchStarterBox box, {
    required Map<String, Recipe> recipes,
    required FoodRules rules,
    required Map<String, LunchItem> library,
    required String addedBy,
  }) {
    final candidates = <String, LunchItem>{};
    final compartments = <FillWeekCompartment>[];
    for (final slot in LunchSlot.values) {
      final pick = box.picks[slot];
      if (pick == null) continue;
      final recipe = switch (pick) {
        RecipeBoxPick(:final recipeId) => recipes[recipeId],
        QuickBoxPick() => null,
      };
      final candidate = StarterBoxItem.candidateOf(
        slot: slot,
        pick: pick,
        recipe: recipe,
        addedBy: addedBy,
      );
      candidates[candidate.id] = candidate;
      final known = library[candidate.id];
      compartments.add(
        _compartment(
          slot: slot,
          pick: LunchPick.of(known ?? candidate),
          also: {...candidate.knownAllergens, ...?known?.knownAllergens},
          rules: rules,
          recipe: recipe,
          isRecipe: pick is RecipeBoxPick,
        ),
      );
    }
    return FillWeekBox(
      id: readyMadeId(box.id),
      kind: FillWeekBoxKind.readyMade,
      name: box.name,
      blurb: box.blurb,
      compartments: compartments,
      candidates: candidates,
    );
  }

  static String goToId(String favouriteId) => 'goto-$favouriteId';

  static String readyMadeId(String starterBoxId) => 'ready-$starterBoxId';

  final String id;
  final FillWeekBoxKind kind;
  final String name;
  final String blurb;
  final List<FillWeekCompartment> compartments;

  /// Item id → the library item a ready-made compartment becomes, written
  /// before the pick is (lunch-box ADR-0020 §5). Empty for a go-to box,
  /// whose items are the household's already.
  final Map<String, LunchItem> candidates;

  bool get isReadyMade => kind == FillWeekBoxKind.readyMade;

  bool get hasUnsafe => compartments.any((each) => !each.isSafe);

  /// A go-to box with anything unsafe for the child stays out of the week.
  bool get canBeChosen => isReadyMade || !hasUnsafe;

  /// What it packs on [isoWeekday]: every safe compartment, a ready-made
  /// box's treat on Friday only.
  Map<LunchSlot, LunchPick> packsOn(int isoWeekday) => {
    for (final compartment in compartments)
      if (compartment.isSafe &&
          (!isReadyMade || compartment.slot.isAutoFilledOn(isoWeekday)))
        compartment.slot: compartment.pick,
  };

  static FillWeekCompartment _compartment({
    required LunchSlot slot,
    required LunchPick pick,
    required Set<Allergen> also,
    required FoodRules rules,
    Recipe? recipe,
    bool isRecipe = false,
  }) => FillWeekCompartment(
    slot: slot,
    pick: pick,
    recipe: recipe,
    isRecipe: isRecipe,
    unsafe: [
      for (final concern in LunchSafety.concernsFor(
        name: pick.name,
        allergens: {...pick.knownAllergens, ...also},
        rules: rules,
      ))
        if (concern.isUnsafe) concern,
    ],
  );
}

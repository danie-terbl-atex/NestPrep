import '../../../shared/text/cut_text.dart';
import '../../recipes/model/recipe.dart';
import 'lunch_item.dart';
import 'lunch_seed_catalogue.dart';
import 'lunch_slot.dart';
import 'lunch_starter_box.dart';

/// The library item a ready-made box's compartment becomes (lunch-box
/// ADR-0020, recipes ADR-0001). A recipe is the item `recipe-<recipeId>`,
/// carrying the recipe's name, prep note and id; a quick pick is the starter
/// library's own `seed-<seedKey>` item (`LunchSeedCatalogue`). The id is
/// fixed, so the same compartment is the same item on every phone, and the
/// item carries every code the box, the recipe and the starter food name —
/// the strictest of them (ADR-0001).
abstract final class StarterBoxItem {
  static String recipeItemId(String recipeId) => 'recipe-$recipeId';

  static LunchItem candidateOf({
    required LunchSlot slot,
    required StarterBoxPick pick,
    required Recipe? recipe,
    required String addedBy,
  }) => switch (pick) {
    RecipeBoxPick(:final recipeId, :final name) => LunchItem.named(
      id: recipeItemId(recipeId),
      name: cutText(recipe?.name ?? name, LunchItem.nameLimit),
      slot: slot,
      allergens: {...pick.allergens, ...?recipe?.allergens},
      addedBy: addedBy,
      prepAhead: recipe?.prepAhead ?? false,
      prepNote: _note(recipe?.prepNote),
      recipeId: recipeId,
    ),
    QuickBoxPick(:final seedKey, :final name) => _seedItem(
      slot: slot,
      pick: pick,
      seedKey: seedKey,
      name: name,
      addedBy: addedBy,
    ),
  };

  static LunchItem _seedItem({
    required LunchSlot slot,
    required StarterBoxPick pick,
    required String seedKey,
    required String name,
    required String addedBy,
  }) {
    final seed = LunchSeedCatalogue.seeds
        .where((seed) => seed.key == seedKey)
        .firstOrNull;
    return LunchItem.named(
      id: LunchSeedCatalogue.idFor(seedKey),
      name: cutText(seed?.name ?? name, LunchItem.nameLimit),
      slot: slot,
      allergens: {...pick.allergens, ...?seed?.allergens},
      addedBy: addedBy,
      prepAhead: seed?.prepNote != null,
      prepNote: seed?.prepNote,
      seedKey: seedKey,
    );
  }

  static String? _note(String? note) =>
      note == null ? null : cutText(note, LunchItem.prepNoteLimit);
}

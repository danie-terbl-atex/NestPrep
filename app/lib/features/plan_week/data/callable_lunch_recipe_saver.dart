import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../../family_profiles/model/allergen.dart';
import 'lunch_recipe_saver.dart';
import 'plan_week_failure_mapper.dart';

/// `saveLunchRecipes` (recipes ADR-0002): the Function derives each recipe's
/// allergen codes from its words — no rule can — and writes it once.
final class CallableLunchRecipeSaver implements LunchRecipeSaver {
  const CallableLunchRecipeSaver(this._functions);

  final FirebaseFunctions _functions;

  /// The Function's limit is thirty seconds.
  static const _timeout = Duration(seconds: 40);

  @override
  Future<List<SavedLunchRecipe>> save({
    required String householdId,
    required List<DishToSave> dishes,
  }) async {
    try {
      final result = await _functions
          .httpsCallable(
            'saveLunchRecipes',
            options: HttpsCallableOptions(timeout: _timeout),
          )
          .call<Object?>({
            'householdId': householdId,
            'recipes': [
              for (final (:draft, :alsoContains) in dishes)
                draft.toSaveWire(alsoContains: alsoContains),
            ],
          });
      return savedFrom(result.data, expected: dishes.length);
    } on FirebaseFunctionsException catch (error) {
      throw failureFromPlanWeekCallable(error);
    }
  }

  /// The reply, parsed (`ENG-09`): one recipe per dish sent, each with an id
  /// and codes this build knows — anything else is unreadable, never a guess
  /// that could leave a code off an item.
  static List<SavedLunchRecipe> savedFrom(
    Object? data, {
    required int expected,
  }) {
    if (data case {'recipes': final List<Object?> recipes}
        when recipes.length == expected) {
      final saved = [for (final entry in recipes) ?_saved(entry)];
      if (saved.length == expected) return saved;
    }
    throw const UnavailableFailure();
  }

  static SavedLunchRecipe? _saved(Object? entry) {
    if (entry
        case {'id': final String id, 'allergens': final List<Object?> codes}
        when id.isNotEmpty) {
      final allergens = [
        for (final code in codes)
          code is String ? Allergen.fromCode(code) : null,
      ];
      if (allergens.contains(null)) return null;
      return SavedLunchRecipe(id: id, allergens: allergens.nonNulls.toSet());
    }
    return null;
  }
}

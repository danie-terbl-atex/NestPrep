import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/parsed_document.dart';
import '../../../shared/log/app_log.dart';
import '../model/recipe.dart';
import '../model/recipe_link.dart';
import 'recipe_document.dart';
import 'recipe_repository.dart';

/// `recipes/{recipeId}` and `households/{id}/recipes/{recipeId}`, read one
/// document at a time by id — the few a screen names — and the published
/// catalogue as one bounded list (recipes ADR-0003 §7).
final class FirestoreRecipeRepository implements RecipeRepository {
  const FirestoreRecipeRepository(this._firestore);

  static const collection = 'recipes';

  final FirebaseFirestore _firestore;

  @override
  Stream<List<Recipe>> watchCatalogue() => _firestore
      .collection(collection)
      .where('status', isEqualTo: RecipeDocument.published)
      .orderBy('name')
      .limit(RecipeRepository.catalogueLimit)
      .snapshots()
      .map((snapshot) => [for (final doc in snapshot.docs) ?_recipeOf(doc)])
      .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Future<List<Recipe>> fetchByIds(Set<String> ids) async {
    try {
      final snapshots = await Future.wait([
        for (final id in ids) _firestore.collection(collection).doc(id).get(),
      ]);
      return [for (final snapshot in snapshots) ?_recipeOf(snapshot)];
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }

  @override
  Future<Recipe?> fetchLinked(String householdId, RecipeLink link) async {
    try {
      return switch (link) {
        CatalogueRecipeLink(:final recipeId) => _recipeOf(
          await _firestore.collection(collection).doc(recipeId).get(),
        ),
        HouseholdRecipeLink(:final recipeId) => _recipeOf(
          await _firestore
              .collection('households')
              .doc(householdId)
              .collection(collection)
              .doc(recipeId)
              .get(),
          isHousehold: true,
        ),
      };
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }

  static Recipe? _recipeOf(
    DocumentSnapshot<Map<String, dynamic>> snapshot, {
    bool isHousehold = false,
  }) {
    final data = snapshot.data();
    if (data == null) {
      AppLog.failure('read recipe', code: 'missing');
      return null;
    }
    final parsed = isHousehold
        ? RecipeDocument.parseHousehold(snapshot.id, data)
        : RecipeDocument.parse(snapshot.id, data);
    return switch (parsed) {
      ValidDocument(:final value) => value,
      RejectedDocument(:final reason) => _dropped(reason),
    };
  }

  static Recipe? _dropped(String reason) {
    AppLog.failure('read recipe, dropped', code: reason);
    return null;
  }
}

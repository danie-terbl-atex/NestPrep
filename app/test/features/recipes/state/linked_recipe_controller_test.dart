import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/recipes/model/recipe.dart';
import 'package:nestprep/features/recipes/model/recipe_link.dart';
import 'package:nestprep/features/recipes/state/linked_recipe_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_recipe_repository.dart';
import '../../../support/fake_starter_boxes.dart';

/// The recipe a lunch item names, read when *How to make it* opens
/// (lunch-box ADR-0021 §8): loading, not there any more, failed with a retry,
/// or the recipe — never read in a build (`FE-05`).
void main() {
  const link = HouseholdRecipeLink('ai-wrap');
  final wrap = StarterBoxFixtures.wrap.copyWith(id: 'ai-wrap');

  LinkedRecipeController controllerOver(FakeRecipeRepository recipes) {
    final controller = LinkedRecipeController(
      recipes: recipes,
      householdId: 'h1',
      link: link,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  test('loads while the read is out, then holds the recipe', () async {
    final recipes = FakeRecipeRepository([wrap])..hold = Completer<void>();
    final controller = controllerOver(recipes);
    expect(controller.state, isA<AsyncLoading<Recipe?>>());
    recipes.hold!.complete();
    await pumpEventQueue();
    expect(controller.state, isA<AsyncData<Recipe?>>());
    expect((controller.state as AsyncData<Recipe?>).value?.name, wrap.name);
    expect(recipes.linked, [link]);
  });

  test(
    'a recipe that is not there is said as nothing, not as a failure',
    () async {
      final controller = controllerOver(FakeRecipeRepository());
      await pumpEventQueue();
      expect(controller.state, isA<AsyncData<Recipe?>>());
      expect((controller.state as AsyncData<Recipe?>).value, isNull);
    },
  );

  test('a failed read is a failure the sheet offers to retry', () async {
    final recipes = FakeRecipeRepository([wrap])
      ..failWith = const UnavailableFailure();
    final controller = controllerOver(recipes);
    await pumpEventQueue();
    expect(controller.state, isA<AsyncFailure<Recipe?>>());

    recipes.failWith = null;
    await controller.retry();
    expect((controller.state as AsyncData<Recipe?>).value?.id, 'ai-wrap');
  });
}

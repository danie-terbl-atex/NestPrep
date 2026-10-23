import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/lunch_box/data/firestore_lunch_starter_box_repository.dart';
import '../features/lunch_box/data/lunch_starter_box_repository.dart';
import '../features/recipes/data/firestore_recipe_repository.dart';
import '../features/recipes/data/recipe_photo_source.dart';
import '../features/recipes/data/recipe_repository.dart';
import '../features/recipes/data/storage_recipe_photo_source.dart';

/// NestPrep's published recipes and the lunch box's ready-made boxes made
/// from them (*Fill the week*, lunch-box ADR-0020), and the recipes'
/// pictures (recipes ADR-0003 §4) — system data, read-only, the same for
/// every household — in their own list so the app-wide graph changes by one
/// line.
List<SingleChildWidget> recipeProviders() => [
  Provider<RecipeRepository>(
    create: (context) =>
        FirestoreRecipeRepository(context.read<FirebaseFirestore>()),
  ),
  // One for the app's life, so a picture read once is not read again.
  Provider<RecipePhotoSource>(
    create: (context) =>
        StorageRecipePhotoSource(context.read<FirebaseStorage>()),
  ),
  Provider<LunchStarterBoxRepository>(
    create: (context) =>
        FirestoreLunchStarterBoxRepository(context.read<FirebaseFirestore>()),
  ),
];

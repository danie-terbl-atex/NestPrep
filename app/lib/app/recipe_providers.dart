import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/lunch_box/data/firestore_lunch_starter_box_repository.dart';
import '../features/lunch_box/data/lunch_starter_box_repository.dart';
import '../features/recipes/data/callable_own_recipe_repository.dart';
import '../features/recipes/data/callable_recipe_document_reader.dart';
import '../features/recipes/data/callable_recipe_drafter.dart';
import '../features/recipes/data/device_recipe_photo_picker.dart';
import '../features/recipes/data/firestore_recipe_repository.dart';
import '../features/recipes/data/guarded_web_fetch.dart';
import '../features/recipes/data/own_recipe_photo_store.dart';
import '../features/recipes/data/own_recipe_repository.dart';
import '../features/recipes/data/recipe_document_reader.dart';
import '../features/recipes/data/recipe_drafter.dart';
import '../features/recipes/data/recipe_image_fetcher.dart';
import '../features/recipes/data/recipe_page_reader.dart';
import '../features/recipes/data/recipe_pdf.dart';
import '../features/recipes/data/recipe_photo_picker.dart';
import '../features/recipes/data/recipe_photo_source.dart';
import '../features/recipes/data/recipe_repository.dart';
import '../features/recipes/data/shared_pdf_inbox.dart';
import '../features/recipes/data/storage_own_recipe_photo_store.dart';
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
  Provider<OwnRecipeRepository>(
    create: (context) =>
        CallableOwnRecipeRepository(context.read<FirebaseFunctions>()),
  ),
  Provider<OwnRecipePhotoStore>(
    create: (context) =>
        StorageOwnRecipePhotoStore(context.read<FirebaseStorage>()),
  ),
  Provider<RecipePhotoPicker>(create: (context) => DeviceRecipePhotoPicker()),
  Provider<RecipeDrafter>(
    create: (context) =>
        CallableRecipeDrafter(context.read<FirebaseFunctions>()),
  ),
  Provider<RecipeDocumentReader>(
    create: (context) =>
        CallableRecipeDocumentReader(context.read<FirebaseFunctions>()),
  ),
  Provider<RecipePdfPicker>(
    create: (context) => const FileSelectorRecipePdfPicker(),
  ),
  Provider<PdfRasterizer>(create: (context) => const PrintingPdfRasterizer()),
  Provider<SharedPdfInbox>(create: (context) => const ChannelSharedPdfInbox()),
  Provider<GuardedWebFetch>(
    create: (context) => GuardedWebFetch(client: http.Client()),
  ),
  Provider<RecipePageReader>(
    create: (context) => HttpRecipePageReader(context.read<GuardedWebFetch>()),
  ),
  Provider<RecipeImageFetcher>(
    create: (context) =>
        HttpRecipeImageFetcher(context.read<GuardedWebFetch>()),
  ),
  Provider<LunchStarterBoxRepository>(
    create: (context) =>
        FirestoreLunchStarterBoxRepository(context.read<FirebaseFirestore>()),
  ),
];

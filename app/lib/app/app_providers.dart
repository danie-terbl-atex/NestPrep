import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/accounts/data/account_repository.dart';
import '../features/accounts/data/auth_gateway.dart';
import '../features/accounts/data/firebase_auth_gateway.dart';
import '../features/accounts/data/firestore_account_repository.dart';
import '../features/accounts/state/session_controller.dart';
import '../features/calendar/data/calendar_repository.dart';
import '../features/calendar/data/firestore_calendar_repository.dart';
import '../features/documents/data/callable_document_directory.dart';
import '../features/documents/data/document_directory.dart';
import '../features/documents/data/document_opener.dart';
import '../features/documents/data/document_picker.dart';
import '../features/documents/data/document_repository.dart';
import '../features/documents/data/document_store.dart';
import '../features/documents/data/file_selector_document_picker.dart';
import '../features/documents/data/firestore_document_repository.dart';
import '../features/documents/data/launcher_document_opener.dart';
import '../features/documents/data/storage_document_store.dart';
import '../features/groceries/data/firestore_grocery_repository.dart';
import '../features/groceries/data/grocery_repository.dart';
import '../features/household/data/callable_household_directory.dart';
import '../features/household/data/firestore_household_repository.dart';
import '../features/household/data/household_directory.dart';
import '../features/household/data/household_repository.dart';
import '../features/meal_planning/data/firestore_meal_repository.dart';
import '../features/meal_planning/data/meal_repository.dart';
import '../features/todos/data/firestore_todo_repository.dart';
import '../features/todos/data/todo_repository.dart';
import 'firebase_bootstrap.dart';

/// The app-wide dependency graph: the platform instances and one repository per
/// feature, each registered behind its interface so a widget test substitutes a
/// fake and never pumps a Firebase SDK (foundation ADR-0006).
///
/// `SessionController` is the one controller here rather than at a route: the
/// router redirects on it, so it has to outlive every route. Every other
/// controller is created by the route that shows it.
List<SingleChildWidget> appProviders(FirebaseServices services) => [
  Provider<FirebaseFirestore>.value(value: services.firestore),
  Provider<FirebaseAuth>.value(value: services.auth),
  Provider<FirebaseFunctions>.value(value: services.functions),
  Provider<FirebaseStorage>.value(value: services.storage),
  Provider<AuthGateway>(
    create: (context) => FirebaseAuthGateway(context.read<FirebaseAuth>()),
  ),
  Provider<AccountRepository>(
    create: (context) =>
        FirestoreAccountRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<HouseholdRepository>(
    create: (context) =>
        FirestoreHouseholdRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<HouseholdDirectory>(
    create: (context) =>
        CallableHouseholdDirectory(context.read<FirebaseFunctions>()),
  ),
  Provider<GroceryRepository>(
    create: (context) =>
        FirestoreGroceryRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<CalendarRepository>(
    create: (context) =>
        FirestoreCalendarRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<MealRepository>(
    create: (context) =>
        FirestoreMealRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<TodoRepository>(
    create: (context) =>
        FirestoreTodoRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<DocumentRepository>(
    create: (context) =>
        FirestoreDocumentRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<DocumentStore>(
    create: (context) => StorageDocumentStore(context.read<FirebaseStorage>()),
  ),
  Provider<DocumentDirectory>(
    create: (context) => CallableDocumentDirectory(
      context.read<FirebaseFunctions>(),
      context.read<FirebaseAuth>(),
    ),
  ),
  Provider<DocumentPicker>(
    create: (context) => const FileSelectorDocumentPicker(),
  ),
  Provider<DocumentOpener>(create: (context) => const LauncherDocumentOpener()),
  ChangeNotifierProvider<SessionController>(
    create: (context) => SessionController(
      authGateway: context.read<AuthGateway>(),
      accountRepository: context.read<AccountRepository>(),
    ),
  ),
];

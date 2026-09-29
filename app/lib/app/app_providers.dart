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
import '../features/calendar_sync/data/calendar_sync_directory.dart';
import '../features/calendar_sync/data/calendar_sync_repository.dart';
import '../features/calendar_sync/data/callable_calendar_sync_directory.dart';
import '../features/calendar_sync/data/firestore_calendar_sync_repository.dart';
import '../features/documents/data/callable_document_directory.dart';
import '../features/documents/data/document_directory.dart';
import '../features/documents/data/document_picker.dart';
import '../features/documents/data/document_repository.dart';
import '../features/documents/data/document_store.dart';
import '../features/documents/data/file_selector_document_picker.dart';
import '../features/documents/data/firestore_document_repository.dart';
import '../features/documents/data/storage_document_store.dart';
import '../features/family_profiles/data/family_profile_repository.dart';
import '../features/family_profiles/data/firestore_family_profile_repository.dart';
import '../features/groceries/data/firestore_grocery_repository.dart';
import '../features/groceries/data/grocery_repository.dart';
import '../features/household/data/callable_household_directory.dart';
import '../features/household/data/firestore_household_repository.dart';
import '../features/household/data/household_directory.dart';
import '../features/household/data/household_repository.dart';
import '../features/household/data/invite_sharer.dart';
import '../features/household/data/platform_invite_sharer.dart';
import '../features/kid_accounts/data/callable_kid_sign_in_directory.dart';
import '../features/kid_accounts/data/firestore_kid_device_repository.dart';
import '../features/kid_accounts/data/kid_device_repository.dart';
import '../features/kid_accounts/data/kid_sign_in_directory.dart';
import '../features/live_location/data/firestore_live_location_repository.dart';
import '../features/live_location/data/geolocator_location_source.dart';
import '../features/live_location/data/live_location_repository.dart';
import '../features/live_location/data/location_reporter.dart';
import '../features/live_location/data/location_source.dart';
import '../features/lunch_box/data/firestore_lunch_repository.dart';
import '../features/lunch_box/data/lunch_repository.dart';
import '../features/meal_planning/data/firestore_meal_repository.dart';
import '../features/meal_planning/data/meal_repository.dart';
import '../features/product_analytics/data/activity_recorder.dart';
import '../features/product_analytics/data/beta_numbers_repository.dart';
import '../features/product_analytics/data/callable_activity_recorder.dart';
import '../features/product_analytics/data/firestore_beta_numbers_repository.dart';
import '../features/product_analytics/state/activity_heartbeat.dart';
import '../features/todos/data/firestore_todo_repository.dart';
import '../features/todos/data/todo_repository.dart';
import '../shared/links/external_link_opener.dart';
import '../shared/links/launcher_external_link_opener.dart';
import 'account_routes.dart';
import 'calendar_v2_providers.dart';
import 'chore_points_providers.dart';
import 'document_tools_providers.dart';
import 'documents_providers.dart';
import 'feature_flag_providers.dart';
import 'firebase_bootstrap.dart';
import 'home_care_providers.dart';
import 'location_reporting.dart';
import 'lunch_planning_providers.dart';
import 'nanny_hub_providers.dart';
import 'notifications_providers.dart';
import 'referral_providers.dart';
import 'subscription_providers.dart';
import 'two_homes_providers.dart';

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
  // The V2 switches (foundation ADR-0014).
  ...featureFlagProviders(),
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
  // household phase 2: the invite leaves through the share sheet (household
  // ADR-0003).
  Provider<InviteSharer>(create: (context) => PlatformInviteSharer()),
  Provider<GroceryRepository>(
    create: (context) =>
        FirestoreGroceryRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<CalendarRepository>(
    create: (context) =>
        FirestoreCalendarRepository(context.read<FirebaseFirestore>()),
  ),
  // ---- calendar sync (calendar ADR-0003) ----
  Provider<CalendarSyncRepository>(
    create: (context) =>
        FirestoreCalendarSyncRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<CalendarSyncDirectory>(
    create: (context) =>
        CallableCalendarSyncDirectory(context.read<FirebaseFunctions>()),
  ),
  Provider<ExternalLinkOpener>(
    create: (context) => const LauncherExternalLinkOpener(),
  ),
  Provider<MealRepository>(
    create: (context) =>
        FirestoreMealRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<TodoRepository>(
    create: (context) =>
        FirestoreTodoRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<LiveLocationRepository>(
    create: (context) =>
        FirestoreLiveLocationRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<LocationSource>(
    create: (context) => const GeolocatorLocationSource(),
  ),
  // Above every route on purpose: a share the person opened keeps reporting
  // when they navigate away from the screen, and stops when its window closes
  // (live-location ADR-0001).
  Provider<LocationReporter>(
    create: (context) => locationReporterFor(
      LocationReporting.fromEnvironment(),
      locationSource: context.read<LocationSource>(),
      liveLocationRepository: context.read<LiveLocationRepository>(),
    ),
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
  // ---- product analytics (product-analytics ADR-0001) ----
  // The heartbeat is app-wide so its once-a-day memory outlives any one
  // household shell; the shell's scope only tells it when to beat.
  Provider<ActivityRecorder>(
    create: (context) =>
        CallableActivityRecorder(context.read<FirebaseFunctions>()),
  ),
  Provider<ActivityHeartbeat>(
    create: (context) =>
        ActivityHeartbeat(activityRecorder: context.read<ActivityRecorder>()),
  ),
  Provider<BetaNumbersRepository>(
    create: (context) => FirestoreBetaNumbersRepository(
      context.read<FirebaseFirestore>(),
      context.read<FirebaseAuth>(),
    ),
  ),
  // Kid sign-in (accounts ADR-0003).
  Provider<KidSignInDirectory>(
    create: (context) =>
        CallableKidSignInDirectory(context.read<FirebaseFunctions>()),
  ),
  Provider<KidDeviceRepository>(
    create: (context) =>
        FirestoreKidDeviceRepository(context.read<FirebaseFirestore>()),
  ),
  // lunch-box (lunch-box ADR-0001).
  Provider<LunchRepository>(
    create: (context) =>
        FirestoreLunchRepository(context.read<FirebaseFirestore>()),
  ),
  // family-profiles (family-profiles ADR-0001).
  Provider<FamilyProfileRepository>(
    create: (context) =>
        FirestoreFamilyProfileRepository(context.read<FirebaseFirestore>()),
  ),
  // ---- nanny hub (nanny-hub ADR-0002, ADR-0003) ----
  ...nannyHubProviders(),
  // documents phase 2 — vaults, lock, scanning (documents ADR-0002 to ADR-0004)
  ...documentVaultProviders(),
  // todos phase 2: chores that earn kids stars (todos ADR-0003).
  ...chorePointsProviders(),
  // home-care (home-care ADR-0001 to ADR-0003).
  ...homeCareProviders(),
  // subscriptions — the store, premium and the free tier's one child
  // (subscriptions ADR-0001)
  ...subscriptionProviders(),
  // lunch-box V2 — pantry, budget, kid picks (lunch-box ADR-0005 to ADR-0007)
  ...lunchPlanningProviders(),
  // account data: delete my account, download my data (accounts ADR-0006)
  ...accountDataProviders(),
  // calendar V2: the school-letter reader and the card sharer (calendar
  // ADR-0005, ADR-0006). The switches are provided above.
  ...calendarV2Providers(),
  // co-parenting: two homes (household ADR-0004).
  ...twoHomesProviders(),
  // referrals and conversion by trigger (subscriptions ADR-0002,
  // product-analytics ADR-0002)
  ...referralProviders(),
  ChangeNotifierProvider<SessionController>(
    create: (context) => SessionController(
      authGateway: context.read<AuthGateway>(),
      accountRepository: context.read<AccountRepository>(),
    ),
  ),
  // documents V2: shared links and offline copies (documents ADR-0006,
  // ADR-0007). After the session, which the offline janitor listens to.
  ...documentToolProviders(),
  // notifications — after the session, which the phone's registration
  // follows (notifications ADR-0001).
  ...notificationsProviders(),
];

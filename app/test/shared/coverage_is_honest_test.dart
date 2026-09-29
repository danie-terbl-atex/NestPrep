import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// What the coverage percentage does **not** include.
///
/// `flutter test --coverage` only reports libraries a test actually loaded. A
/// file nothing imports is not 0% — it is absent, and the percentage is the
/// average over the rest. So the headline figure flatters itself by exactly the
/// code nobody tests, which is the code most worth knowing about.
///
/// This app was at "92.8%" while **26** hand-written files, including every
/// Firestore repository, appeared nowhere in the report. Most of them cannot be
/// loaded without a live Firebase and that is a deliberate choice — the app's
/// `CLAUDE.md` says nothing pumps the Firestore SDK. The problem was never the
/// choice; it was that the number said nothing about it.
///
/// So every absent file is listed here with why. A new one has to be added
/// deliberately, and a file that starts being covered has to be removed — both
/// directions, because a list that only grows becomes a place to hide things.
void main() {
  /// Why each file is not in the report. Grouped by cause, because the causes
  /// are what a reader needs: two of these three are permanent, one is a gap.
  const absentByDesign = <String, String>{
    // Needs a live Firebase. Reachable only against the emulator suite or the
    // cloud, which is what `functions/test/rules` and `test/emulator` cover
    // from the other side (foundation ADR-0002).
    'lib/main.dart': 'boots Firebase',
    'lib/app/firebase_bootstrap.dart': 'boots Firebase',
    'lib/app/firebase_options.dart': 'generated client configuration',
    'lib/app/emulator_endpoint.dart': 'reads dart:io and the emulator host',
    'lib/app/app_providers.dart':
        'builds the provider graph over live repositories',
    'lib/app/nestprep_app.dart': 'the root widget, which boots the graph',
    'lib/features/accounts/data/firebase_auth_gateway.dart':
        'wraps FirebaseAuth',
    'lib/features/accounts/data/firestore_account_repository.dart':
        'writes Firestore',
    'lib/features/calendar/data/firestore_calendar_repository.dart':
        'writes Firestore',
    'lib/features/groceries/data/firestore_grocery_repository.dart':
        'writes Firestore',
    'lib/features/household/data/firestore_household_repository.dart':
        'writes Firestore',
    'lib/features/meal_planning/data/firestore_meal_repository.dart':
        'writes Firestore',
    'lib/features/todos/data/firestore_todo_repository.dart':
        'writes Firestore',
    'lib/features/household/data/callable_household_directory.dart':
        'calls Functions',
    'lib/features/product_analytics/data/callable_activity_recorder.dart':
        'calls Functions',
    'lib/features/product_analytics/data/firestore_beta_numbers_repository.dart':
        'reads Firestore and the ID token',
    'lib/features/live_location/data/firestore_live_location_repository.dart':
        'writes Firestore',
    'lib/features/live_location/data/geolocator_location_source.dart':
        'wraps the platform location plugin',
    'lib/features/documents/data/firestore_document_repository.dart':
        'writes Firestore',
    'lib/features/family_profiles/data/firestore_family_profile_repository.dart':
        'writes Firestore',
    'lib/features/documents/data/storage_document_store.dart':
        'wraps FirebaseStorage',
    'lib/features/documents/data/callable_document_directory.dart':
        'calls Functions and refreshes an ID token',
    'lib/features/documents/data/file_selector_document_picker.dart':
        'opens the platform file picker',
    'lib/features/kid_accounts/data/callable_kid_sign_in_directory.dart':
        'calls Functions',
    'lib/features/kid_accounts/data/firestore_kid_device_repository.dart':
        'reads Firestore',
    // Documents phase 2 (documents ADR-0002 to ADR-0004).
    'lib/app/documents_providers.dart':
        'builds the vault providers over live Firebase and plugins',
    'lib/features/documents/data/firestore_vault_repository.dart':
        'writes Firestore',
    'lib/features/documents/data/storage_vault_store.dart':
        'wraps FirebaseStorage',
    'lib/features/documents/data/storage_upload.dart':
        'wraps a FirebaseStorage UploadTask',
    'lib/features/documents/data/local_auth_device_lock.dart':
        'asks the platform biometric prompt',
    'lib/features/documents/data/platform_document_scanner.dart':
        'opens the platform document scanner',
    'lib/features/documents/data/printing_pdf_page_renderer.dart':
        'rasterises through the platform PDF engine',
    // nanny hub (nanny-hub ADR-0002, ADR-0003).
    'lib/app/nanny_hub_providers.dart':
        'builds the nanny hub providers over live Firebase and plugins',
    'lib/features/nanny_hub/data/firestore_nanny_hub_repository.dart':
        'writes Firestore',
    'lib/features/nanny_hub/data/firestore_shift_repository.dart':
        'writes Firestore',
    'lib/features/nanny_hub/data/callable_shift_directory.dart':
        'calls Functions',
    'lib/features/nanny_hub/data/storage_photo_store.dart':
        'wraps FirebaseStorage',
    'lib/features/nanny_hub/data/image_picker_photo_picker.dart':
        'opens the platform camera and photo library',
    // co-parenting (household ADR-0004), and the feature flags it switches on.
    'lib/app/two_homes_providers.dart':
        'builds the two-homes and flag providers over live Firebase',
    'lib/features/two_homes/data/callable_two_homes_directory.dart':
        'calls Functions',
    'lib/shared/flags/firestore_feature_flag_source.dart': 'reads Firestore',

    // Declarations only: an interface or a barrel has no executable line to
    // attribute coverage to, so it cannot appear whatever tests do.
    'lib/features/accounts/data/account_repository.dart': 'interface only',
    'lib/features/accounts/data/auth_gateway.dart': 'interface only',
    'lib/features/calendar/data/calendar_repository.dart': 'interface only',
    'lib/features/groceries/data/grocery_repository.dart': 'interface only',
    'lib/features/household/data/household_repository.dart': 'interface only',
    'lib/features/meal_planning/data/meal_repository.dart': 'interface only',
    'lib/features/live_location/data/live_location_repository.dart':
        'interface only',
    'lib/features/live_location/data/location_reporter.dart': 'interface only',
    'lib/features/live_location/data/location_source.dart': 'interface only',
    'lib/features/todos/data/todo_repository.dart': 'interface only',
    'lib/features/documents/data/document_repository.dart': 'interface only',
    'lib/features/documents/data/document_store.dart': 'interface only',
    'lib/features/documents/data/document_directory.dart': 'interface only',
    'lib/features/documents/data/document_picker.dart': 'interface only',
    'lib/features/kid_accounts/data/kid_sign_in_directory.dart':
        'interface only',
    'lib/features/kid_accounts/data/kid_device_repository.dart':
        'interface only',
    'lib/features/family_profiles/data/family_profile_repository.dart':
        'interface only',
    'lib/features/documents/data/device_lock.dart': 'interface only',
    'lib/features/documents/data/document_scanner.dart': 'interface only',
    'lib/features/documents/data/pdf_page_renderer.dart': 'interface only',
    'lib/features/documents/data/scan_composer.dart': 'interface only',
    'lib/features/documents/data/vault_store.dart': 'interface only',
    'lib/features/documents/state/upload_destination.dart': 'interface only',
    'lib/features/documents/model/vault_lock_state.dart': 'two enums only',
    'lib/features/nanny_hub/data/nanny_hub_repository.dart': 'interface only',
    'lib/features/nanny_hub/data/shift_repository.dart': 'interface only',
    'lib/features/nanny_hub/data/shift_directory.dart': 'interface only',
    'lib/features/nanny_hub/data/photo_store.dart': 'interface only',
    'lib/features/nanny_hub/data/photo_picker.dart':
        'an enum and an interface only',
    'lib/features/nanny_hub/model/contact_kind.dart': 'an enum only',
    'lib/features/nanny_hub/model/handover_kind.dart': 'an enum only',
    'lib/features/nanny_hub/model/handover_mood.dart': 'an enum only',
    'lib/features/two_homes/data/two_homes_repository.dart': 'interface only',
    'lib/features/two_homes/data/two_homes_directory.dart':
        'an enum and an interface only',
    'lib/shared/flags/feature_flag_source.dart': 'interface only',
    'lib/design/nest_kit.dart': 'barrel of exports',

    // Compile-time constants, folded before anything runs. Tested by their
    // effect elsewhere — the gallery test asserts `DesignGalleryAccess`, and
    // every screen test renders `NestSpace`.
    'lib/design/tokens/nest_spacing.dart': 'const only',
    'lib/app/design_gallery_access.dart': 'const only',
    'lib/features/nanny_hub/data/nanny_paths.dart': 'const only',
  };

  final lcov = File('coverage/lcov.info');

  List<File> sourcesAndTests() => [
    for (final directory in ['lib', 'test'])
      ...Directory(directory)
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')),
  ];

  /// Why this can be skipped, or `false` to run.
  ///
  /// The report is written **by the run this test is part of**, so during
  /// `flutter test --coverage` it reads the *previous* run's file. That is fine
  /// when nothing has moved since, and wrong the moment a file is added — the
  /// new file is legitimately absent from yesterday's report and would be
  /// reported as untested. So a report older than the newest source or test is
  /// treated as no report at all, which is the honest answer rather than a
  /// failure somebody learns to re-run past.
  Object staleOrMissing() {
    if (!lcov.existsSync()) {
      return 'no coverage/lcov.info — run `flutter test --coverage` first';
    }
    final written = lcov.lastModifiedSync();
    final newer = sourcesAndTests()
        .where((file) => file.lastModifiedSync().isAfter(written))
        .map((file) => file.path)
        .toList();
    if (newer.isEmpty) return false;
    return 'coverage/lcov.info predates ${newer.length} file(s), '
        'starting with ${newer.first} — re-run `flutter test --coverage`';
  }

  final Object skipWithoutCoverage = staleOrMissing();

  List<String> handWritten() =>
      Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) => file.path)
          .where((path) => path.endsWith('.dart'))
          .where((path) => !path.endsWith('.g.dart'))
          .where((path) => !path.endsWith('.freezed.dart'))
          .toList();

  Set<String> reported() => {
    for (final line in lcov.readAsLinesSync())
      if (line.startsWith('SF:')) line.substring(3).trim(),
  };

  test('every file missing from the report is one we know about', () {
    final missing = handWritten().toSet().difference(reported());
    final undeclared = missing.difference(absentByDesign.keys.toSet()).toList()
      ..sort();

    expect(
      undeclared,
      isEmpty,
      reason:
          'these are in lib/ and no test loads them, so the coverage figure '
          'says nothing about them — either test them, or add them here with '
          'the reason they cannot be',
    );
  }, skip: skipWithoutCoverage);

  test('and nothing is excused that the tests now reach', () {
    final reachable = reported();
    final stale = [
      for (final path in absentByDesign.keys)
        if (reachable.contains(path)) path,
    ]..sort();

    expect(
      stale,
      isEmpty,
      reason:
          'covered now — delete the excuse rather than leaving it to cover '
          'for something else later',
    );
  }, skip: skipWithoutCoverage);

  test('and nothing is excused that has been deleted', () {
    final onDisk = handWritten().toSet();
    final ghosts = [
      for (final path in absentByDesign.keys)
        if (!onDisk.contains(path)) path,
    ]..sort();

    expect(ghosts, isEmpty, reason: 'the file is gone; so should the row be');
  });
}

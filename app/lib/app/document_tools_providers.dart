import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/accounts/state/session_controller.dart';
import '../features/documents/data/callable_document_share_directory.dart';
import '../features/documents/data/document_share_directory.dart';
import '../features/documents/data/document_share_repository.dart';
import '../features/documents/data/encrypted_offline_copy_store.dart';
import '../features/documents/data/firestore_document_share_repository.dart';
import '../features/documents/data/firestore_offline_access_check.dart';
import '../features/documents/data/offline_access_check.dart';
import '../features/documents/data/offline_copy_store.dart';
import '../features/documents/data/secure_storage_offline_key_vault.dart';
import '../features/documents/state/offline_copy_janitor.dart';
import '../shared/flags/feature_flags_controller.dart';

/// Documents V2's part of the app-wide graph (documents ADR-0006, ADR-0007):
/// shared links' callables and list, the phone's encrypted offline copies,
/// the check that asks the server whether a copy may stay, and the janitor
/// that deletes copies on sign-out, on leaving a household and when the
/// switch goes off.
///
/// Spread **after** `SessionController` and the flags: the janitor listens to
/// both from the moment the app starts, not from the moment somebody opens
/// Documents.
List<SingleChildWidget> documentToolProviders() => [
  Provider<DocumentShareDirectory>(
    create: (context) =>
        CallableDocumentShareDirectory(context.read<FirebaseFunctions>()),
  ),
  Provider<DocumentShareRepository>(
    create: (context) =>
        FirestoreDocumentShareRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<OfflineCopyStore>(
    create: (context) => EncryptedOfflineCopyStore(
      keyVault: SecureStorageOfflineKeyVault(),
      supportDirectory: getApplicationSupportDirectory,
    ),
  ),
  Provider<OfflineAccessCheck>(
    create: (context) =>
        FirestoreOfflineAccessCheck(context.read<FirebaseFirestore>()),
  ),
  Provider<OfflineCopyJanitor>(
    lazy: false,
    create: (context) => OfflineCopyJanitor(
      store: context.read<OfflineCopyStore>(),
      session: context.read<SessionController>(),
      flags: context.read<FeatureFlagsController>(),
    ),
    dispose: (context, janitor) => janitor.dispose(),
  ),
];

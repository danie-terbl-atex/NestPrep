import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/documents/data/device_lock.dart';
import '../features/documents/data/document_scanner.dart';
import '../features/documents/data/firestore_vault_repository.dart';
import '../features/documents/data/local_auth_device_lock.dart';
import '../features/documents/data/pdf_page_renderer.dart';
import '../features/documents/data/pdf_scan_composer.dart';
import '../features/documents/data/platform_document_scanner.dart';
import '../features/documents/data/printing_pdf_page_renderer.dart';
import '../features/documents/data/scan_composer.dart';
import '../features/documents/data/storage_vault_store.dart';
import '../features/documents/data/vault_repository.dart';
import '../features/documents/data/vault_store.dart';

/// Documents phase 2's part of the app-wide graph (documents ADR-0002 to
/// ADR-0004): the vaults' metadata and bytes, the phone's lock, its scanner,
/// the scan pipeline and the PDF renderer — each behind its interface, so a
/// widget test substitutes a fake and never touches a plugin.
///
/// Its own list, spread into `appProviders`, so the shared file changes by
/// one line.
List<SingleChildWidget> documentVaultProviders() => [
  Provider<VaultRepository>(
    create: (context) =>
        FirestoreVaultRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<VaultStore>(
    create: (context) => StorageVaultStore(context.read<FirebaseStorage>()),
  ),
  Provider<DeviceLock>(create: (context) => LocalAuthDeviceLock()),
  Provider<DocumentScanner>(
    create: (context) => const PlatformDocumentScanner(),
  ),
  Provider<ScanComposer>(create: (context) => const PdfScanComposer()),
  Provider<PdfPageRenderer>(
    create: (context) => const PrintingPdfPageRenderer(),
  ),
];

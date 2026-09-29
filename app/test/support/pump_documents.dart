import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/documents_shell.dart';
import 'package:nestprep/features/accounts/model/account.dart';
import 'package:nestprep/features/accounts/model/auth_user.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/documents/data/device_lock.dart';
import 'package:nestprep/features/documents/data/document_directory.dart';
import 'package:nestprep/features/documents/data/document_opener.dart';
import 'package:nestprep/features/documents/data/document_picker.dart';
import 'package:nestprep/features/documents/data/document_repository.dart';
import 'package:nestprep/features/documents/data/document_scanner.dart';
import 'package:nestprep/features/documents/data/document_store.dart';
import 'package:nestprep/features/documents/data/pdf_page_renderer.dart';
import 'package:nestprep/features/documents/data/scan_composer.dart';
import 'package:nestprep/features/documents/data/vault_repository.dart';
import 'package:nestprep/features/documents/data/vault_store.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:provider/provider.dart';

import 'fake_auth.dart';
import 'fake_documents.dart';
import 'fake_vault.dart';
import 'household_fixtures.dart';
import 'pump_screen.dart';

/// Every fake behind the Documents shell, in one place a test can reach into.
final class DocumentsFakes {
  final documents = FakeDocumentRepository();
  final store = FakeDocumentStore();
  final directory = FakeDocumentDirectory();
  final picker = FakeDocumentPicker();
  final opener = FakeDocumentOpener();
  final vaults = FakeVaultRepository();
  final vaultStore = FakeVaultStore();
  final deviceLock = FakeDeviceLock();
  final scanner = FakeDocumentScanner();
  final composer = FakeScanComposer();
  final renderer = FakePdfPageRenderer();

  Future<void> close() async {
    await documents.close();
    await vaults.close();
  }
}

/// Pumps the real Documents shell — its route table, its controllers, its
/// vault lock — over fakes, at [location]. What a person sees there is what
/// the app would show: the gate, the redirects between screens, back.
Future<void> pumpDocuments(
  WidgetTester tester, {
  required DocumentsFakes fakes,
  required String location,
  HouseholdView? view,
  String viewerUid = Fixtures.samUid,
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) async {
  final auth = FakeAuthGateway();
  final accounts = FakeAccountRepository();
  final session = SessionController(
    authGateway: auth,
    accountRepository: accounts,
  );
  auth.emit(AuthUser(uid: viewerUid, email: 'someone@nestprep.test'));
  accounts.emit(
    Account(
      id: viewerUid,
      displayName: 'Someone',
      householdIds: const [Fixtures.householdId],
      activeHouseholdId: Fixtures.householdId,
    ),
  );
  addTearDown(() async {
    session.dispose();
    await auth.close();
    await accounts.close();
  });
  await tester.pump();

  await pumpRouter(
    tester,
    router: GoRouter(
      initialLocation: location,
      routes: [documentsShellRoute(session)],
    ),
    view: view,
    brightness: brightness,
    textScale: textScale,
    providers: [
      Provider<DocumentRepository>.value(value: fakes.documents),
      Provider<DocumentStore>.value(value: fakes.store),
      Provider<DocumentDirectory>.value(value: fakes.directory),
      Provider<DocumentPicker>.value(value: fakes.picker),
      Provider<DocumentOpener>.value(value: fakes.opener),
      Provider<VaultRepository>.value(value: fakes.vaults),
      Provider<VaultStore>.value(value: fakes.vaultStore),
      Provider<DeviceLock>.value(value: fakes.deviceLock),
      Provider<DocumentScanner>.value(value: fakes.scanner),
      Provider<ScanComposer>.value(value: fakes.composer),
      Provider<PdfPageRenderer>.value(value: fakes.renderer),
    ],
  );
}

/// The household's folders and documents, answered, so the library is not
/// loading.
void answerLibrary(DocumentsFakes fakes) {
  fakes.documents.emitFolders([]);
  fakes.documents.emitDocuments([]);
}

/// Every vault an admin listens to, answered with nothing in it.
void answerEmptyVaults(DocumentsFakes fakes, {List<String>? owners}) {
  for (final owner in owners ?? const ['m-sam', 'm-thandi', 'm-kid']) {
    fakes.vaults.emitVault(owner, []);
    fakes.vaults.emitGrants(owner, []);
  }
}

/// Sets a 360-wide phone for the dark, 200% text checks (`FE-13`, `FE-14`).
void onASmallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360 * 3, 800 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

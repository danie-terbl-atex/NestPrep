import 'dart:typed_data';

import '../model/account_export.dart';
import '../model/deletion_preview.dart';

/// Delete my account and download my data, as the app asks the server for
/// them (accounts ADR-0006). Every rule lives in the Functions; this is the
/// asking.
abstract interface class AccountDataGateway {
  /// What deleting would do, household by household. Changes nothing.
  Future<DeletionPreview> previewDeletion();

  /// Deletes the account. [endingHouseholdIds] are the households the person
  /// agreed to end; the server refuses if that is no longer what would happen.
  Future<void> deleteAccount({required List<String> endingHouseholdIds});

  /// Writes an export of everything about this account and says where.
  Future<AccountExport> exportData();

  /// Fetches an export's bytes, while its hour lasts.
  Future<Uint8List> download(AccountExport export);
}

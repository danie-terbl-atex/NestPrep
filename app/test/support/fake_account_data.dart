import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:nestprep/features/account_data/data/account_data_gateway.dart';
import 'package:nestprep/features/account_data/data/export_sharer.dart';
import 'package:nestprep/features/account_data/model/account_export.dart';
import 'package:nestprep/features/account_data/model/deletion_preview.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// The account-data callables, answered in memory (accounts ADR-0006). A test
/// sets what the next call returns or throws, and reads back what was asked.
final class FakeAccountDataGateway implements AccountDataGateway {
  FakeAccountDataGateway({DeletionPreview? preview})
    : preview = preview ?? AccountDataFixtures.handOverAndEnd;

  DeletionPreview preview;
  AppFailure? previewError;
  AppFailure? deleteError;
  AppFailure? exportError;
  AppFailure? downloadError;

  /// Held open by a test that wants to see the in-flight state.
  Completer<void>? deleteGate;
  Completer<void>? exportGate;

  int previewCalls = 0;
  final List<List<String>> deletions = [];
  int exports = 0;

  @override
  Future<DeletionPreview> previewDeletion() async {
    previewCalls++;
    final error = previewError;
    if (error != null) throw error;
    return preview;
  }

  @override
  Future<void> deleteAccount({required List<String> endingHouseholdIds}) async {
    deletions.add(endingHouseholdIds);
    await deleteGate?.future;
    final error = deleteError;
    if (error != null) throw error;
  }

  @override
  Future<AccountExport> exportData() async {
    exports++;
    await exportGate?.future;
    final error = exportError;
    if (error != null) throw error;
    return AccountExport(
      path: 'accountExports/uid-sam/e$exports.json',
      expiresAt: DateTime.utc(2026, 9, 29, 9),
      fileCount: 2,
    );
  }

  @override
  Future<Uint8List> download(AccountExport export) async {
    final error = downloadError;
    if (error != null) throw error;
    return Uint8List.fromList(utf8.encode('{"formatVersion":1}'));
  }
}

final class FakeExportSharer implements ExportSharer {
  bool opens = true;
  final List<String> shared = [];

  @override
  Future<bool> share({
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (opens) shared.add(fileName);
    return opens;
  }
}

abstract final class AccountDataFixtures {
  static const parkers = HouseholdDeletionPreview(
    householdId: 'h-parkers',
    name: 'The Parkers',
    outcome: HouseholdDeletionOutcome.handOver,
    successorName: 'Alex',
    othersLosingAccess: 0,
    hasPremium: false,
  );

  static const granny = HouseholdDeletionPreview(
    householdId: 'h-gran',
    name: 'Gran’s house',
    outcome: HouseholdDeletionOutcome.end,
    othersLosingAccess: 2,
    hasPremium: true,
  );

  static const helping = HouseholdDeletionPreview(
    householdId: 'h-smiths',
    name: 'The Smiths',
    outcome: HouseholdDeletionOutcome.leave,
    othersLosingAccess: 0,
    hasPremium: false,
  );

  static const handOverAndEnd = DeletionPreview(
    households: [parkers, granny, helping],
    renewingSubscriptions: 1,
  );

  static const nothing = DeletionPreview(
    households: [],
    renewingSubscriptions: 0,
  );
}

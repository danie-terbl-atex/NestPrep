import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/failure/storage_failure_mapper.dart';
import '../model/account_export.dart';
import '../model/deletion_preview.dart';
import 'account_data_failure_mapper.dart';
import 'account_data_gateway.dart';

/// The account-data callables and the export's bytes in Storage (accounts
/// ADR-0006). Results are parsed here, at the edge, and never cast (`ENG-09`).
final class CallableAccountDataGateway implements AccountDataGateway {
  const CallableAccountDataGateway(this._functions, this._storage);

  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;

  @override
  Future<DeletionPreview> previewDeletion() async {
    final result = await _call('previewAccountDeletion', null);
    final households = result['households'];
    return DeletionPreview(
      households: households is List
          ? [for (final entry in households) _household(entry)]
          : throw FormatException(
              'households missing from the preview',
              result,
            ),
      renewingSubscriptions: _int(result, 'renewingSubscriptions'),
    );
  }

  @override
  Future<void> deleteAccount({required List<String> endingHouseholdIds}) =>
      _call('deleteAccount', {
        'confirmation': 'DELETE',
        'endingHouseholdIds': endingHouseholdIds,
      });

  @override
  Future<AccountExport> exportData() async {
    final result = await _call('exportAccountData', null);
    return AccountExport(
      path: _string(result, 'path'),
      expiresAt: DateTime.parse(_string(result, 'expiresAt')).toUtc(),
      fileCount: _int(result, 'fileCount'),
    );
  }

  @override
  Future<Uint8List> download(AccountExport export) async {
    try {
      // An export is a few hundred kilobytes for a busy household; the SDK's
      // default ten-megabyte ceiling is the most the app will read.
      final bytes = await _storage.ref(export.path).getData();
      if (bytes == null) {
        throw const AccountDataFailure(AccountDataProblem.downloadFailed);
      }
      return bytes;
    } on FirebaseException catch (error) {
      throw failureFromStorage(error);
    }
  }

  HouseholdDeletionPreview _household(Object? entry) {
    final map = entry is Map ? Map<String, Object?>.from(entry) : null;
    final outcome = HouseholdDeletionOutcome.fromName(map?['outcome']);
    if (map == null || outcome == null) {
      throw FormatException('a household in the preview is malformed', entry);
    }
    final successor = map['successorName'];
    final premium = map['hasPremium'];
    return HouseholdDeletionPreview(
      householdId: _string(map, 'householdId'),
      name: _string(map, 'name'),
      outcome: outcome,
      successorName: successor is String && successor.isNotEmpty
          ? successor
          : null,
      othersLosingAccess: _int(map, 'othersLosingAccess'),
      hasPremium: premium == true,
    );
  }

  Future<Map<String, Object?>> _call(
    String name,
    Map<String, Object?>? payload,
  ) async {
    try {
      final result = await _functions
          .httpsCallable(name)
          .call<Object?>(payload);
      final data = result.data;
      return data is Map ? Map<String, Object?>.from(data) : const {};
    } on FirebaseFunctionsException catch (error) {
      throw failureFromAccountDataCallable(error);
    }
  }

  /// A field the Function documents that it returns. Its absence is our bug,
  /// not the person's, so it fails loudly rather than defaulting (`ENG-09`).
  String _string(Map<String, Object?> data, String key) {
    final value = data[key];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('$key missing from the callable result', data);
  }

  int _int(Map<String, Object?> data, String key) {
    final value = data[key];
    if (value is int) return value;
    throw FormatException('$key missing from the callable result', data);
  }
}

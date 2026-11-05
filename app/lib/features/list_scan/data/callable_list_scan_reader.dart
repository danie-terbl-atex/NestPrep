import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../model/list_photo.dart';
import '../model/list_reading.dart';
import 'list_scan_failure_mapper.dart';
import 'list_scan_reader.dart';

/// `readShoppingList` (list-scan ADR-0001). The photo travels in the call and
/// is never uploaded or stored.
final class CallableListScanReader implements ListScanReader {
  const CallableListScanReader(this._functions);

  final FirebaseFunctions _functions;

  /// A little past the Function's sixty seconds, so the phone hears its
  /// answer rather than its own timeout.
  static const _timeout = Duration(seconds: 70);

  @override
  Future<ListReading> read({
    required String householdId,
    required ListPhoto photo,
  }) async {
    if (photo.isTooLarge) {
      throw const ListScanFailure(ListScanProblem.listPhotoTooLarge);
    }
    try {
      final result = await _functions
          .httpsCallable(
            'readShoppingList',
            options: HttpsCallableOptions(timeout: _timeout),
          )
          .call<Object?>({
            'householdId': householdId,
            'mimeType': ListPhoto.mimeType,
            'data': base64Encode(photo.bytes),
          });
      return ListReading.fromWire(result.data);
    } on FirebaseFunctionsException catch (error) {
      throw failureFromListScanCallable(error);
    }
  }
}

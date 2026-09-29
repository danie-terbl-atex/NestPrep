import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../model/letter_file.dart';
import '../model/letter_reading.dart';
import 'school_letter_failure_mapper.dart';
import 'school_letter_reader.dart';

/// `readSchoolLetter` (calendar ADR-0005). The letter travels in the call and
/// is never uploaded or stored; the Function answers with proposals only.
final class CallableSchoolLetterReader implements SchoolLetterReader {
  const CallableSchoolLetterReader(this._functions);

  final FirebaseFunctions _functions;

  /// The Function's own limit is sixty seconds; the phone waits a little
  /// longer so it hears the Function's answer rather than its own timeout.
  static const _timeout = Duration(seconds: 70);

  @override
  Future<LetterReading> read({
    required String householdId,
    required LetterFile letter,
  }) async {
    if (letter.isTooLarge) {
      throw const SchoolLetterFailure(SchoolLetterProblem.letterTooLarge);
    }
    try {
      final result = await _functions
          .httpsCallable(
            'readSchoolLetter',
            options: HttpsCallableOptions(timeout: _timeout),
          )
          .call<Object?>({
            'householdId': householdId,
            'mimeType': letter.kind.mimeType,
            'data': base64Encode(letter.bytes),
          });
      return LetterReading.fromWire(result.data);
    } on FirebaseFunctionsException catch (error) {
      throw failureFromLetterCallable(error);
    }
  }
}

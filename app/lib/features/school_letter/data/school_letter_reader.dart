import '../model/letter_file.dart';
import '../model/letter_reading.dart';

/// Reading a letter needs the model, and the model is reached only from a
/// Cloud Function (foundation ADR-0015) — so this is a callable, behind an
/// interface a widget test substitutes.
abstract interface class SchoolLetterReader {
  /// The events [letter] proposes. Throws an `AiFailure` (switched off, the
  /// month spent, the model down or unreadable), a `SchoolLetterFailure` (the
  /// flag, the file) or a calendar-grant refusal. Saves nothing.
  Future<LetterReading> read({
    required String householdId,
    required LetterFile letter,
  });
}

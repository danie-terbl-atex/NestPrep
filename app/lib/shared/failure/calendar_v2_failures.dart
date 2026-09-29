part of 'app_failure.dart';

// ---- AI, shared by every AI feature (foundation ADR-0015) ----

/// Why an AI call did not happen. Each is a `reason` the server's
/// `AI_REFUSALS` puts in its error's details, and
/// `calendar_v2_contract_test.dart` reads both. Plan-my-week and every later
/// AI feature reuse these.
enum AiProblem {
  /// The AI kill switch, or this feature's own switch, is off.
  aiSwitchedOff,

  /// The household has used this month's AI calls.
  aiLimitReached,

  /// The model could not be reached, or kept failing.
  aiUnavailable,

  /// The model answered, twice, in a shape that could not be read.
  aiUnreadable,

  /// The model declined the content.
  aiDeclined,
}

final class AiFailure extends AppFailure {
  const AiFailure(this.problem);

  final AiProblem problem;
}

// ---- calendar V2: snap a school letter (calendar ADR-0005) ----

/// Why a school letter could not be read or its events added. The first
/// three are the server's `SCHOOL_LETTER_REFUSALS`; the rest are the phone's.
enum SchoolLetterProblem {
  /// The `snapSchoolLetter` switch is off.
  letterFeatureOff,

  /// Past the size a letter needs to be.
  letterTooLarge,

  /// Not a photo or a PDF, whatever it claimed.
  letterNotSupported,

  /// The camera, the photo library or the file picker would not open.
  pickerUnavailable,

  /// Some of the ticked events could not be added; the rest were.
  someNotAdded,
}

final class SchoolLetterFailure extends AppFailure {
  const SchoolLetterFailure(this.problem);

  final SchoolLetterProblem problem;
}

// ---- calendar V2: the mental-load split view (calendar ADR-0006) ----

/// Why a week's card could not be shared. Both are the phone's own.
enum MentalLoadProblem {
  /// The card could not be turned into a picture.
  cardUnreadable,

  /// The share sheet would not open.
  shareUnavailable,
}

final class MentalLoadFailure extends AppFailure {
  const MentalLoadFailure(this.problem);

  final MentalLoadProblem problem;
}

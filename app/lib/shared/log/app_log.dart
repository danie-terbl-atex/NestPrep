import 'dart:developer' as developer;

/// Where the technical half of a failure goes. The person sees copy from
/// `AppCopy` and never an error code (`FE-09`); we see the code here, with
/// enough context to find it again and nothing that identifies anybody
/// (`ENG-22`).
///
/// Names and emails, invite codes, household and member ids are all things a
/// log must not carry — so callers pass the *kind* of thing that failed, not
/// the thing.
abstract final class AppLog {
  static const _name = 'nestprep';

  /// A boundary refused or broke. [operation] is what we were doing, [code] is
  /// the SDK's own code, and [error] is kept for the stack only.
  static void failure(String operation, {required String code, Object? error}) {
    developer.log(
      'failed: $operation ($code)',
      name: _name,
      level: 900,
      error: error,
    );
  }
}

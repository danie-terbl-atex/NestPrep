import 'package:json_annotation/json_annotation.dart';

import 'birthday.dart';

/// A member's birthday, stored as `YYYY-MM-DD` or `--MM-DD` (birthdays
/// ADR-0001). Absent on every member document written before the field existed,
/// which reads as no birthday rather than as a failure (`BE-10`).
///
/// A value that is not a birthday reads as no birthday too, for the reason
/// `MemberColorConverter` falls back: every screen in the app waits on the
/// member listener, so one unreadable field on one profile would take the whole
/// household down. Losing a birthday is the smaller loss, and the rules refuse
/// a malformed one on the way in.
class BirthdayConverter implements JsonConverter<Birthday?, Object?> {
  const BirthdayConverter();

  @override
  Birthday? fromJson(Object? json) {
    if (json is! String) return null;
    try {
      return Birthday.parse(json);
    } on FormatException {
      return null;
    }
  }

  @override
  Object? toJson(Birthday? value) => value?.iso;
}

/// Morning or afternoon, when the words said which.
enum Meridiem { am, pm }

/// One time on a clock as written — `5`, `5pm`, `17h30`, `noon` — before the
/// grammar has decided what an unmarked `5` means (calendar ADR-0004).
final class ClockReading {
  const ClockReading({
    required this.hour,
    required this.minute,
    this.meridiem,
    this.is24Hour = false,
  });

  final int hour;
  final int minute;
  final Meridiem? meridiem;

  /// Written so that there is only one reading: `17:30`, `07:30`, `17h30`,
  /// `noon`. An unmarked `5:30` is not.
  final bool is24Hour;

  bool get isValid {
    if (minute < 0 || minute > 59) return false;
    if (meridiem != null) return hour >= 1 && hour <= 12;
    return hour >= 0 && hour <= 23;
  }

  bool get isAmbiguous =>
      meridiem == null && !is24Hour && hour >= 1 && hour <= 12;

  ClockReading withMeridiem(Meridiem value) => ClockReading(
    hour: hour,
    minute: minute,
    meridiem: value,
    is24Hour: is24Hour,
  );

  /// Minutes since midnight. An unmarked hour is read the way a family
  /// calendar reads it — 1 to 6 is the afternoon, 7 to 11 the morning, 12 is
  /// noon — unless the sentence said which ([hint]).
  int toMinutes({Meridiem? hint}) {
    final marked = meridiem ?? (isAmbiguous ? hint ?? _familyGuess : null);
    final hour24 = switch (marked) {
      null => hour,
      Meridiem.am => hour % 12,
      Meridiem.pm => (hour % 12) + 12,
    };
    return (hour24 * 60) + minute;
  }

  Meridiem get _familyGuess =>
      hour == 12 || hour <= 6 ? Meridiem.pm : Meridiem.am;

  static final _withMeridiem = RegExp(r'^(\d{1,2})(?:[:.](\d{2}))?(am|pm)$');
  static final _withMinutes = RegExp(r'^(\d{1,2})[:.](\d{2})$');
  static final _hourMark = RegExp(r'^(\d{1,2})h(\d{2})?$');
  static final _bare = RegExp(r'^\d{1,2}$');

  /// Reads one word as a clock time, or null when it is not one. A bare number
  /// is returned too, and marked [isBare], because only its neighbours can say
  /// whether `5` is a time or the 5th.
  static ClockReading? parse(String word) {
    switch (word) {
      case 'noon' || 'midday':
        return const ClockReading(hour: 12, minute: 0, is24Hour: true);
      case 'midnight':
        return const ClockReading(hour: 0, minute: 0, is24Hour: true);
    }
    final marked = _withMeridiem.firstMatch(word);
    if (marked != null) {
      return ClockReading(
        hour: int.parse(marked.group(1)!),
        minute: int.parse(marked.group(2) ?? '0'),
        meridiem: marked.group(3) == 'am' ? Meridiem.am : Meridiem.pm,
      );
    }
    final withMinutes = _withMinutes.firstMatch(word);
    if (withMinutes != null) {
      final hourText = withMinutes.group(1)!;
      final hour = int.parse(hourText);
      return ClockReading(
        hour: hour,
        minute: int.parse(withMinutes.group(2)!),
        is24Hour:
            (hourText.length == 2 && hourText.startsWith('0')) || hour > 12,
      );
    }
    final hourMark = _hourMark.firstMatch(word);
    if (hourMark != null) {
      // South African `17h30` is always the 24-hour clock, and so is `7h30`.
      return ClockReading(
        hour: int.parse(hourMark.group(1)!),
        minute: int.parse(hourMark.group(2) ?? '0'),
        is24Hour: true,
      );
    }
    if (_bare.hasMatch(word)) {
      final hour = int.parse(word);
      return ClockReading(hour: hour, minute: 0, is24Hour: hour > 12);
    }
    return null;
  }

  static bool isBare(String word) => _bare.hasMatch(word);

  static Meridiem? meridiemOf(String? word) => switch (word) {
    'am' => Meridiem.am,
    'pm' => Meridiem.pm,
    _ => null,
  };
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'care_routine.freezed.dart';
part 'care_routine.g.dart';

/// One step of a child's day a carer follows — "Bath, 18:00, warm not hot".
///
/// [minuteOfDay] is minutes since midnight on the household's wall clock,
/// the one way the app stores a time of day (calendar ADR-0002), so 18:00
/// means 18:00 wherever the household lives (`ENG-21`). Null is a step with
/// no fixed time, like "a story before sleep".
@freezed
abstract class CareRoutine with _$CareRoutine {
  const factory CareRoutine({
    required String label,
    int? minuteOfDay,
    String? note,
  }) = _CareRoutine;

  const CareRoutine._();

  factory CareRoutine.fromJson(Map<String, Object?> json) =>
      _$CareRoutineFromJson(json);

  /// A step with no time sorts after every timed one.
  int get sortMinute => minuteOfDay ?? Duration.minutesPerDay;

  /// In the order of the day, untimed last, and otherwise as written.
  static List<CareRoutine> inOrderOfTheDay(List<CareRoutine> routines) {
    final indexed = [...routines.indexed]..sort(_byTimeThenPosition);
    return [for (final (_, routine) in indexed) routine];
  }

  static int _byTimeThenPosition((int, CareRoutine) a, (int, CareRoutine) b) {
    final byTime = a.$2.sortMinute.compareTo(b.$2.sortMinute);
    return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
  }
}

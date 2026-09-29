import 'package:freezed_annotation/freezed_annotation.dart';

part 'medication.freezed.dart';
part 'medication.g.dart';

/// One medicine a person takes, with the times a parent set for it.
///
/// `times` are minutes since midnight on the household's wall clock — the
/// representation calendar ADR-0002 chose for event times — so "08:00 with
/// breakfast" means 08:00 wherever the household lives (`ENG-21`). An empty
/// list is a medicine taken when needed, like an inhaler.
@freezed
abstract class Medication with _$Medication {
  const factory Medication({
    required String name,

    /// Free text, because "5 ml", "one puff" and "half a tablet" are all what
    /// a parent writes.
    String? dose,
    @Default(<int>[]) List<int> times,
    String? note,
  }) = _Medication;

  const Medication._();

  factory Medication.fromJson(Map<String, Object?> json) =>
      _$MedicationFromJson(json);

  static const minutesInADay = 24 * 60;

  /// The times in the order of the day, each once.
  List<int> get timesInOrder => ({...times}.toList()..sort());

  bool get isWhenNeeded => times.isEmpty;

  /// The first time it is due, for ordering a list of medicines by the day.
  /// A when-needed medicine sorts last.
  int get firstTime => isWhenNeeded ? minutesInADay : timesInOrder.first;
}

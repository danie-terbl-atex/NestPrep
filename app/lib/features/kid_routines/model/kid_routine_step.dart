import 'package:freezed_annotation/freezed_annotation.dart';

part 'kid_routine_step.freezed.dart';
part 'kid_routine_step.g.dart';

/// One thing to take along under a step — what goes in the school bag
/// (kid-routines ADR-0001). No weekdays means every day.
@freezed
abstract class KidRoutinePart with _$KidRoutinePart {
  const factory KidRoutinePart({
    required String id,
    required String text,
    @JsonKey(includeIfNull: false) String? picture,
    @Default(<int>[]) List<int> weekdays,
  }) = _KidRoutinePart;

  const KidRoutinePart._();

  factory KidRoutinePart.fromJson(Map<String, Object?> json) =>
      _$KidRoutinePartFromJson(json);

  bool fallsOn(int weekday) => weekdays.isEmpty || weekdays.contains(weekday);
}

/// One step of a kid routine. The id is what "done" records, so rewording a
/// step or moving it does not untick it.
@freezed
abstract class KidRoutineStep with _$KidRoutineStep {
  const factory KidRoutineStep({
    required String id,
    required String title,
    @JsonKey(includeIfNull: false) String? picture,
    @JsonKey(includeIfNull: false) String? note,
    @Default(<KidRoutinePart>[]) List<KidRoutinePart> parts,
  }) = _KidRoutineStep;

  factory KidRoutineStep.fromJson(Map<String, Object?> json) =>
      _$KidRoutineStepFromJson(json);
}

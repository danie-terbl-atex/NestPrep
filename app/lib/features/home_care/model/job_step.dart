import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_step.freezed.dart';
part 'job_step.g.dart';

/// One line of a job's checklist. The id is what "done" records, so editing
/// the wording of a step does not untick it.
@freezed
abstract class JobStep with _$JobStep {
  const factory JobStep({required String id, required String text}) = _JobStep;

  factory JobStep.fromJson(Map<String, Object?> json) =>
      _$JobStepFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'checklist_progress.freezed.dart';
part 'checklist_progress.g.dart';

/// How much of the shift's checklists was done: [ticked] of [total], counting
/// only items that still existed when the shift ended.
@freezed
abstract class ChecklistProgress with _$ChecklistProgress {
  const factory ChecklistProgress({
    @Default(0) int ticked,
    @Default(0) int total,
  }) = _ChecklistProgress;

  const ChecklistProgress._();

  factory ChecklistProgress.fromJson(Map<String, Object?> json) =>
      _$ChecklistProgressFromJson(json);

  bool get isEmpty => total == 0;
}

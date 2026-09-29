import 'package:freezed_annotation/freezed_annotation.dart';

part 'checklist_item.freezed.dart';
part 'checklist_item.g.dart';

/// One thing to do at one part of a shift. Its [id] is what a shift's tick
/// names, so renaming an item keeps its tick and removing one drops it.
@freezed
abstract class ChecklistItem with _$ChecklistItem {
  const factory ChecklistItem({required String id, required String text}) =
      _ChecklistItem;

  factory ChecklistItem.fromJson(Map<String, Object?> json) =>
      _$ChecklistItemFromJson(json);
}

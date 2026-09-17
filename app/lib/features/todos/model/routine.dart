import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../design/tokens/nest_member_palette.dart';
import '../../../shared/firestore/server_timestamp_converter.dart';
import '../../../shared/recurrence/calendar_date_converter.dart';
import '../../../shared/recurrence/recurrence_rule.dart';
import '../../../shared/time/calendar_date.dart';
import '../../household/model/member_color_converter.dart';

part 'routine.freezed.dart';
part 'routine.g.dart';

/// A named bundle of tasks with one schedule — "Laundry Day Tasks", every
/// Saturday (todos ADR-0001). Every task in it inherits its rule and its due
/// date, and its default assignees unless the task says otherwise.
///
/// Moving a routine's schedule moves every task in it, which is the whole point
/// of the bundle: a household changes laundry day once, not six times.
@freezed
abstract class Routine with _$Routine {
  const factory Routine({
    @JsonKey(includeToJson: false) required String id,
    required String name,
    @CalendarDateConverter() required CalendarDate firstDate,
    RecurrenceRule? recurrence,
    @Default(<String>[]) List<String> defaultAssigneeIds,
    @MemberColorConverter() @Default(MemberColor.violet) MemberColor color,
    required String createdBy,
    @ServerTimestampConverter() DateTime? createdAt,
  }) = _Routine;

  const Routine._();

  factory Routine.fromJson(Map<String, Object?> json) =>
      _$RoutineFromJson(json);
}

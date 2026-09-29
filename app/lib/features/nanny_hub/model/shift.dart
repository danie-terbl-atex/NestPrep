import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/nullable_timestamp_converter.dart';
import '../../../shared/firestore/server_timestamp_converter.dart';

part 'shift.freezed.dart';
part 'shift.g.dart';

/// One stretch of looking after the children, at
/// `households/{id}/nannyShifts/{id}` (nanny-hub ADR-0002). It has an explicit
/// start — the carer, or a parent for them — and an explicit end, which only
/// `endNannyShift` writes, because the end is also when the parents' summary
/// is made.
///
/// [ticks] holds the checklists ticked during this shift, keyed by
/// `ShiftChecklist.tickKey`; the checklists themselves stay as the parents
/// wrote them.
@freezed
abstract class Shift with _$Shift {
  const factory Shift({
    @JsonKey(includeToJson: false) required String id,
    required String carerMemberId,
    required String startedBy,
    @ServerTimestampConverter() DateTime? startedAt,
    @NullableTimestampConverter() DateTime? endedAt,
    String? endedBy,
    @Default(Shift.open) String status,
    @Default(<String, bool>{}) Map<String, bool> ticks,
  }) = _Shift;

  const Shift._();

  factory Shift.fromJson(Map<String, Object?> json) => _$ShiftFromJson(json);

  static const open = 'open';
  static const ended = 'ended';

  bool get isOpen => status == open;

  bool isTicked(String tickKey) => ticks[tickKey] ?? false;
}

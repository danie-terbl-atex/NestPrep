import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../shared/firestore/nullable_timestamp_converter.dart';
import '../../../../shared/firestore/server_timestamp_converter.dart';

part 'helper_shift.freezed.dart';
part 'helper_shift.g.dart';

/// One stretch of a helper's work, clocked in and out, at
/// `households/{id}/homeCareShifts/{id}` (home-care ADR-0007). Both instants
/// are the server's, and a shift only ever moves open → ended.
///
/// [startedVia] and [endedVia] say where the tap was made — this app or a
/// wall frame — so a later leave calculation can tell them apart.
@freezed
abstract class HelperShift with _$HelperShift {
  const factory HelperShift({
    @JsonKey(includeToJson: false) required String id,
    required String helperId,
    required String startedBy,
    @ServerTimestampConverter() DateTime? startedAt,
    @Default(HelperShift.app) String startedVia,
    @NullableTimestampConverter() DateTime? endedAt,
    String? endedBy,
    String? endedVia,
    @Default(HelperShift.open) String status,
  }) = _HelperShift;

  const HelperShift._();

  factory HelperShift.fromJson(Map<String, Object?> json) =>
      _$HelperShiftFromJson(json);

  static const open = 'open';
  static const ended = 'ended';
  static const app = 'app';
  static const frame = 'frame';

  bool get isOpen => status == open;

  /// How long it lasted, once both ends are known.
  Duration? get length {
    final from = startedAt;
    final to = endedAt;
    return from == null || to == null ? null : to.difference(from);
  }
}

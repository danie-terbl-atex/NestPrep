import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/instant_converter.dart';
import '../../../shared/firestore/server_timestamp_converter.dart';
import 'nanny_limits.dart';

part 'shift_booking.freezed.dart';
part 'shift_booking.g.dart';

/// A shift a parent booked ahead for a carer, at
/// `households/{id}/nannyBookings/{id}` (nanny-hub ADR-0006). It is the window
/// a carer kept to their booked shifts sees the household in, and the only
/// time anybody but family sees the house codes — from [opensAt] to
/// [closesAt], which the rules work out from the same two instants.
///
/// A booking is never changed: moving one is cancelling it and booking again,
/// so the window a carer's pass names cannot shift under it.
@freezed
abstract class ShiftBooking with _$ShiftBooking {
  const factory ShiftBooking({
    @JsonKey(includeToJson: false) required String id,
    required String carerMemberId,
    @InstantConverter() required DateTime startsAt,
    @InstantConverter() required DateTime endsAt,
    String? note,
    required String createdBy,
    @ServerTimestampConverter() DateTime? createdAt,
  }) = _ShiftBooking;

  const ShiftBooking._();

  factory ShiftBooking.fromJson(Map<String, Object?> json) =>
      _$ShiftBookingFromJson(json);

  /// When the carer's access opens: a little before the start, to reach the
  /// gate.
  DateTime get opensAt => startsAt.subtract(NannyLimits.shiftGrace);

  /// When it closes: a little after the end, to hand over.
  DateTime get closesAt => endsAt.add(NannyLimits.shiftGrace);

  /// Inclusive at both ends, as the rules are.
  bool isOpenAt(DateTime instant) =>
      !instant.isBefore(opensAt) && !instant.isAfter(closesAt);

  bool hasClosedBy(DateTime instant) => instant.isAfter(closesAt);
}

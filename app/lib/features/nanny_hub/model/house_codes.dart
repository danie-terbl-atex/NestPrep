import 'package:flutter/foundation.dart';

import 'house_code.dart';
import 'shift_booking.dart';

/// What the house-codes screen shows (nanny-hub ADR-0006): the codes, while
/// the viewer may see them, or why not yet.
@immutable
sealed class HouseCodes {
  const HouseCodes();
}

final class CodesShown extends HouseCodes {
  CodesShown(List<HouseCode> codes, {this.closesAt})
    : codes = List.unmodifiable(codes);

  final List<HouseCode> codes;

  /// When they go again — null for family, who always sees them.
  final DateTime? closesAt;
}

/// Outside a booked shift: shut, with the next shift when there is one.
final class CodesClosed extends HouseCodes {
  const CodesClosed({this.next});

  final ShiftBooking? next;
}

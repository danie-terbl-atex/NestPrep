import 'dart:typed_data';

import '../../../shared/time/calendar_date.dart';

/// A premium household's photo of one child's lunchbox on one day
/// (lunch-box ADR-0015), or null when there is none to show — not premium,
/// still being made after the wait, or any failure. The drawn box stands in
/// for null, so a caller never shows an error for a missing photo.
abstract interface class LunchPhotoSource {
  /// [signature] names what is in the box, so the same box asked for twice
  /// shares one request and a changed box asks again.
  Future<Uint8List?> photoFor({
    required String householdId,
    required String childId,
    required CalendarDate date,
    required String signature,
  });
}

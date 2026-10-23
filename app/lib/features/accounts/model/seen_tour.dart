import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';

part 'seen_tour.freezed.dart';
part 'seen_tour.g.dart';

/// Which version of the welcome tour this person last finished or skipped,
/// and when — `users/{uid}.tour` (welcome-tour ADR-0001). The rules accept it
/// only in this shape, stamped with the server's time, and never lower than
/// the version recorded before.
@freezed
abstract class SeenTour with _$SeenTour {
  const factory SeenTour({
    required int version,
    @ServerTimestampConverter() DateTime? seenAt,
  }) = _SeenTour;

  factory SeenTour.fromJson(Map<String, Object?> json) =>
      _$SeenTourFromJson(json);
}

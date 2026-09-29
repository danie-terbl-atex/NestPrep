import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'spot_mark.freezed.dart';
part 'spot_mark.g.dart';

/// One stroke a parent drew over the before photo — usually a circle round
/// the spot (home-care ADR-0001).
///
/// Stored as a flat `x, y, x, y…` list, each normalised to 0–1 of the photo's
/// width and height, because Firestore cannot store a list of lists and a
/// point in pixels would mean nothing at another size. The photo itself is
/// never changed.
@freezed
abstract class SpotMark with _$SpotMark {
  const factory SpotMark({@Default(<double>[]) List<double> points}) =
      _SpotMark;

  const SpotMark._();

  factory SpotMark.fromJson(Map<String, Object?> json) =>
      _$SpotMarkFromJson(json);

  /// A stroke from points in a box of [size], kept inside it, and thinned to
  /// at most [pointLimit] points so one scribble cannot grow the job without
  /// end.
  factory SpotMark.fromOffsets(List<Offset> offsets, Size size) {
    final step = (offsets.length / pointLimit).ceil().clamp(1, offsets.length);
    return SpotMark(
      points: [
        for (var index = 0; index < offsets.length; index += step) ...[
          _unit(offsets[index].dx, size.width),
          _unit(offsets[index].dy, size.height),
        ],
      ],
    );
  }

  /// The most marks a job keeps — what the rules cap.
  static const limit = 20;

  /// The most points one mark keeps.
  static const pointLimit = 200;

  /// The points again, placed in a box of [size].
  List<Offset> offsetsIn(Size size) => [
    for (var index = 0; index + 1 < points.length; index += 2)
      Offset(points[index] * size.width, points[index + 1] * size.height),
  ];

  static double _unit(double value, double extent) =>
      extent <= 0 ? 0 : (value / extent).clamp(0, 1).toDouble();
}

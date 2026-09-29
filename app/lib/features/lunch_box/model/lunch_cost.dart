import 'package:flutter/foundation.dart';

import '../../../shared/money/money.dart';

/// A lunch cost while it is still being added up (lunch-box ADR-0007): whole
/// thousandths of a cent, so a pack shared by eight boxes is not rounded
/// eight times before it reaches a total. It becomes [Money] — rounded once,
/// half up, to whole cents — only where it is shown (`ENG-20`).
@immutable
final class LunchCost implements Comparable<LunchCost> {
  const LunchCost(this.millicents);

  static const zero = LunchCost(0);

  /// One box's share of [cents] paid for something that makes [portions]
  /// boxes, to the nearest thousandth of a cent.
  factory LunchCost.share({required int cents, required int portions}) {
    if (portions <= 0) throw ArgumentError.value(portions, 'portions');
    return LunchCost((cents * 1000 * 2 + portions) ~/ (portions * 2));
  }

  final int millicents;

  LunchCost operator +(LunchCost other) =>
      LunchCost(millicents + other.millicents);

  LunchCost operator -(LunchCost other) =>
      LunchCost(millicents - other.millicents);

  LunchCost operator *(int times) => LunchCost(millicents * times);

  bool get isZero => millicents == 0;

  /// Rounded, once, to whole cents.
  Money get money {
    final rounded = millicents >= 0
        ? (millicents + 500) ~/ 1000
        : -((-millicents + 500) ~/ 1000);
    return Money(rounded);
  }

  @override
  int compareTo(LunchCost other) => millicents.compareTo(other.millicents);

  bool operator <(LunchCost other) => millicents < other.millicents;

  @override
  bool operator ==(Object other) =>
      other is LunchCost && other.millicents == millicents;

  @override
  int get hashCode => millicents.hashCode;

  @override
  String toString() => 'LunchCost($millicents m¢)';
}

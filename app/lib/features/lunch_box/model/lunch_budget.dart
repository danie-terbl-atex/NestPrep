import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import '../../../shared/money/money.dart';

part 'lunch_budget.freezed.dart';
part 'lunch_budget.g.dart';

/// What the household means to spend on school lunches in a week, for every
/// child together, at `households/{id}/lunchBudget/weekly` (lunch-box
/// ADR-0007). Premium to set; a meter, never an alarm.
@freezed
abstract class LunchBudget with _$LunchBudget {
  const factory LunchBudget({
    @JsonKey(includeToJson: false) required String id,
    required int cents,
    @Default('ZAR') String currency,
    required String updatedBy,
    @ServerTimestampConverter() DateTime? updatedAt,
  }) = _LunchBudget;

  const LunchBudget._();

  factory LunchBudget.fromJson(Map<String, Object?> json) =>
      _$LunchBudgetFromJson(json);

  /// The one budget document's id.
  static const weekly = 'weekly';

  /// R1 to R100 000 a week.
  static const minimumCents = 100;
  static const centsLimit = 10000000;

  Money get money =>
      Money(cents, currency: Currency.fromCode(currency) ?? Currency.zar);
}

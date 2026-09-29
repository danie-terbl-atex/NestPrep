import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import '../../../shared/money/money.dart';
import 'lunch_cost.dart';

part 'lunch_price.freezed.dart';
part 'lunch_price.g.dart';

/// What the household pays for one library item, at
/// `households/{id}/lunchPrices/{itemId}` (lunch-box ADR-0007): [cents] for
/// something that makes [portions] boxes — `portions: 1` is a price per box,
/// more is a pack ("R42 for a bag that does 8 boxes").
///
/// Premium: the rules refuse a write without it; reading is never refused.
@freezed
abstract class LunchPrice with _$LunchPrice {
  const factory LunchPrice({
    /// The lunch item's id — also the document id.
    @JsonKey(includeToJson: false) required String id,
    required int cents,
    @Default(1) int portions,

    /// ISO 4217, as stored. Read through [money].
    @Default('ZAR') String currency,
    required String updatedBy,
    @ServerTimestampConverter() DateTime? updatedAt,
  }) = _LunchPrice;

  const LunchPrice._();

  factory LunchPrice.fromJson(Map<String, Object?> json) =>
      _$LunchPriceFromJson(json);

  /// R5 000: more than anything in a lunch box costs, less than a typo.
  static const centsLimit = 500000;
  static const portionLimit = 100;

  String get itemId => id;

  /// What was paid, in the currency it was paid in; rand for a code this
  /// build does not know, which the rules never let in.
  Money get money =>
      Money(cents, currency: Currency.fromCode(currency) ?? Currency.zar);

  /// One box's share of it, before any rounding.
  LunchCost get perBox => LunchCost.share(cents: cents, portions: portions);

  bool get isPack => portions > 1;
}

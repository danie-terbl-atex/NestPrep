import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/nullable_timestamp_converter.dart';
import '../../../shared/firestore/server_timestamp_converter.dart';

part 'grocery_item.freezed.dart';
part 'grocery_item.g.dart';

/// One line on the household's single list, at
/// `households/{id}/groceryItems/{itemId}` (groceries ADR-0001).
///
/// Ticking sets `boughtAt` to the server's time; unticking clears it. A bought
/// item is never deleted — it is the history the quick re-add chips are built
/// from.
@freezed
abstract class GroceryItem with _$GroceryItem {
  const factory GroceryItem({
    @JsonKey(includeToJson: false) required String id,
    required String name,

    /// Free text, because "2 kg" and "a few" are both what people write.
    String? quantity,

    /// The member profile that added it, not the account — an admin adding on
    /// behalf of a child records the child.
    required String addedBy,
    @ServerTimestampConverter() DateTime? addedAt,
    @NullableTimestampConverter() DateTime? boughtAt,
    String? boughtBy,
  }) = _GroceryItem;

  const GroceryItem._();

  factory GroceryItem.fromJson(Map<String, Object?> json) =>
      _$GroceryItemFromJson(json);

  /// Bought is decided by **who** bought it, not when.
  ///
  /// `boughtBy` is written by the device and is there the instant somebody
  /// ticks; `boughtAt` is the server's and is null until the write reaches it.
  /// Keying on the timestamp made a tick made offline vanish from the list
  /// entirely — it was in neither the unbought nor the bought set until the
  /// network came back (groceries phase 1).
  bool get isBought => boughtBy != null;

  /// Whether a bought item is still worth showing, struck through, so somebody
  /// who ticked the wrong thing can undo it (groceries ADR-0001).
  ///
  /// A tick whose timestamp has not reached the server yet was, by definition,
  /// a moment ago.
  bool isStillVisible(DateTime now) {
    if (!isBought) return true;
    final bought = boughtAt;
    if (bought == null) return true;
    return now.difference(bought) < visibleAfterBuying;
  }

  static const visibleAfterBuying = Duration(hours: 24);
}

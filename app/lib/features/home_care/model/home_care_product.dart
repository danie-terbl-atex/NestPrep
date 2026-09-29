import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/nullable_timestamp_converter.dart';
import '../../../shared/firestore/server_timestamp_converter.dart';
import 'product_kind.dart';
import 'stock_level.dart';

part 'home_care_product.freezed.dart';
part 'home_care_product.g.dart';

/// One product in the household's own library, at
/// `households/{id}/homeCareProducts/{productId}` (home-care ADR-0002).
///
/// The name is the household's ("Jik", "the blue spray"); the kind is what
/// the safety catalogue reads. The two flags are the household's own extra
/// care on top of whatever the catalogue already says.
@freezed
abstract class HomeCareProduct with _$HomeCareProduct {
  const factory HomeCareProduct({
    @JsonKey(includeToJson: false) required String id,
    required String name,
    @JsonKey(unknownEnumValue: ProductKind.other) required ProductKind kind,

    /// Where it lives, so the helper does not have to ask.
    String? whereKept,
    String? note,
    @Default(false) bool keepFromChildren,
    @Default(false) bool keepFromPets,

    /// The member profile that added it, not the account.
    required String createdBy,
    @ServerTimestampConverter() DateTime? createdAt,

    /// How much is left (home-care ADR-0005). Never written with the rest of
    /// the product — only by its own update, so a parent's edit cannot put a
    /// stale level back over the helper's. A product from before the tracker
    /// has none, which reads as full (`BE-10`).
    @JsonKey(includeToJson: false, unknownEnumValue: StockLevel.full)
    @Default(StockLevel.full)
    StockLevel stock,
    @JsonKey(includeToJson: false) String? stockChangedBy,
    @JsonKey(includeToJson: false)
    @NullableTimestampConverter()
    DateTime? stockChangedAt,
  }) = _HomeCareProduct;

  factory HomeCareProduct.fromJson(Map<String, Object?> json) =>
      _$HomeCareProductFromJson(json);

  /// The longest name the rules keep.
  static const nameLimit = 60;

  /// The longest "where it is kept" or note the rules keep.
  static const textLimit = 200;
}

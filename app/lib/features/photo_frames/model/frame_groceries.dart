import 'package:freezed_annotation/freezed_annotation.dart';

import '../../add_to_checkers/model/checkers_area.dart';
import '../../groceries/model/product_match.dart';

part 'frame_groceries.freezed.dart';

/// The `groceries` field of a frame: adding to the grocery list from the
/// frame, with products picked at [shop] near [area]. A frame without the
/// field — or with one this app cannot read — has it off.
@Freezed(fromJson: false, toJson: false)
abstract class FrameGroceries with _$FrameGroceries {
  const factory FrameGroceries({
    required ProductRetailer shop,
    required CheckersArea area,
  }) = _FrameGroceries;

  const FrameGroceries._();

  static FrameGroceries? fromJson(Object? json) {
    if (json is! Map) return null;
    final shop = json['shop'];
    final area = json['area'];
    if (shop is! String || area is! String) return null;
    final retailer = ProductRetailer.fromCode(shop);
    final city = CheckersArea.fromCode(area);
    if (retailer == null || !retailer.isConnected || city == null) return null;
    return FrameGroceries(shop: retailer, area: city);
  }

  Map<String, Object?> toJson() => {'shop': shop.code, 'area': area.code};
}

final class FrameGroceriesConverter
    implements JsonConverter<FrameGroceries?, Object?> {
  const FrameGroceriesConverter();

  @override
  FrameGroceries? fromJson(Object? json) => FrameGroceries.fromJson(json);

  @override
  Object? toJson(FrameGroceries? groceries) => groceries?.toJson();
}

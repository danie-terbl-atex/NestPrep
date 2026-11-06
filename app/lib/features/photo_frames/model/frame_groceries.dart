import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/failure/app_failure.dart';
import '../../add_to_checkers/model/checkers_area.dart';
import '../../add_to_woolworths/model/woolworths_store.dart';
import '../../groceries/model/product_match.dart';
import '../../live_location/model/coordinates.dart';

part 'frame_groceries.freezed.dart';

/// Finds the Woolworths store and price list that fulfil a point.
typedef WoolworthsStoreLookup = Future<WoolworthsStore> Function(Coordinates);

/// The `groceries` field of a frame: adding to the grocery list from the
/// frame, with products picked at [shop] near [area]. At Woolworths it also
/// carries the [store] the phone found for the area, because the frame's
/// search runs on the server, which cannot reach Woolworths' store lookup. A
/// frame without the field — or with one this app cannot read — has it off.
@Freezed(fromJson: false, toJson: false)
abstract class FrameGroceries with _$FrameGroceries {
  const factory FrameGroceries({
    required ProductRetailer shop,
    required CheckersArea area,
    WoolworthsStore? store,
  }) = _FrameGroceries;

  const FrameGroceries._();

  static final _storeId = RegExp(r'^[0-9]{1,10}$');
  static const _priceZones = {'p10', 'p30', 'p60'};

  static FrameGroceries? fromJson(Object? json) {
    if (json is! Map) return null;
    final shop = json['shop'];
    final area = json['area'];
    if (shop is! String || area is! String) return null;
    final retailer = ProductRetailer.fromCode(shop);
    final city = CheckersArea.fromCode(area);
    if (retailer == null || !retailer.isConnected || city == null) return null;
    if (retailer != ProductRetailer.woolworths) {
      return FrameGroceries(shop: retailer, area: city);
    }
    final store = switch (json) {
      {'store': final String id, 'priceZone': final String zone} =>
        WoolworthsStore(id: id, priceZone: zone),
      _ => null,
    };
    if (store == null || !_isSavable(store)) return null;
    return FrameGroceries(shop: retailer, area: city, store: store);
  }

  /// What to save: at Woolworths with the store [storeFor] finds for the
  /// area's centre now, and at any other shop with none.
  Future<FrameGroceries> located(WoolworthsStoreLookup storeFor) async {
    if (shop != ProductRetailer.woolworths) return copyWith(store: null);
    final found = await storeFor(area.centre);
    if (!_isSavable(found)) {
      throw const WoolworthsFailure(WoolworthsProblem.catalogueChanged);
    }
    return copyWith(store: found);
  }

  Map<String, Object?> toJson() => {
    'shop': shop.code,
    'area': area.code,
    if (store case final store? when shop == ProductRetailer.woolworths) ...{
      'store': store.id,
      'priceZone': store.priceZone,
    },
  };

  static bool _isSavable(WoolworthsStore store) =>
      _storeId.hasMatch(store.id) && _priceZones.contains(store.priceZone);
}

final class FrameGroceriesConverter
    implements JsonConverter<FrameGroceries?, Object?> {
  const FrameGroceriesConverter();

  @override
  FrameGroceries? fromJson(Object? json) => FrameGroceries.fromJson(json);

  @override
  Object? toJson(FrameGroceries? groceries) => groceries?.toJson();
}

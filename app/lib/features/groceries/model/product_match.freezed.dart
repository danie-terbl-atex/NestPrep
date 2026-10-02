// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_match.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductMatch {

 ProductRetailer get retailer;/// The Sixty60 product id, the same id a cart line carries.
 String get productId;/// Article number and unit of measure together, e.g. `10136729EA` — the
/// backup key when a product id is ever re-issued.
 String get articleCode;/// `EA`, `KG`, `PK1`… as Checkers sends it. `KG` is sold by weight.
 String get unitOfMeasure; String get name; String? get brand;/// What it cost when it was picked (`ENG-20`); per kilogram for a
/// weighed item.
 Money get price; String? get imageId;/// The member profile that picked it, the same convention as `addedBy`.
 String get pickedBy;/// Null while the write has not reached the server.
 DateTime? get pickedAt;
/// Create a copy of ProductMatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductMatchCopyWith<ProductMatch> get copyWith => _$ProductMatchCopyWithImpl<ProductMatch>(this as ProductMatch, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ProductMatch;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductMatch&&(identical(other.retailer, _this.retailer) || other.retailer == _this.retailer)&&(identical(other.productId, _this.productId) || other.productId == _this.productId)&&(identical(other.articleCode, _this.articleCode) || other.articleCode == _this.articleCode)&&(identical(other.unitOfMeasure, _this.unitOfMeasure) || other.unitOfMeasure == _this.unitOfMeasure)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.brand, _this.brand) || other.brand == _this.brand)&&(identical(other.price, _this.price) || other.price == _this.price)&&(identical(other.imageId, _this.imageId) || other.imageId == _this.imageId)&&(identical(other.pickedBy, _this.pickedBy) || other.pickedBy == _this.pickedBy)&&(identical(other.pickedAt, _this.pickedAt) || other.pickedAt == _this.pickedAt));
}


@override
int get hashCode {
  final _this = this as ProductMatch;
  return Object.hash(runtimeType,_this.retailer,_this.productId,_this.articleCode,_this.unitOfMeasure,_this.name,_this.brand,_this.price,_this.imageId,_this.pickedBy,_this.pickedAt);
}

@override
String toString() {
  final _this = this as ProductMatch;
  return 'ProductMatch(retailer: ${_this.retailer}, productId: ${_this.productId}, articleCode: ${_this.articleCode}, unitOfMeasure: ${_this.unitOfMeasure}, name: ${_this.name}, brand: ${_this.brand}, price: ${_this.price}, imageId: ${_this.imageId}, pickedBy: ${_this.pickedBy}, pickedAt: ${_this.pickedAt})';
}


}

/// @nodoc
abstract mixin class $ProductMatchCopyWith<$Res>  {
  factory $ProductMatchCopyWith(ProductMatch value, $Res Function(ProductMatch) _then) = _$ProductMatchCopyWithImpl;
@useResult
$Res call({
 ProductRetailer retailer, String productId, String articleCode, String unitOfMeasure, String name, String? brand, Money price, String? imageId, String pickedBy, DateTime? pickedAt
});




}
/// @nodoc
class _$ProductMatchCopyWithImpl<$Res>
    implements $ProductMatchCopyWith<$Res> {
  _$ProductMatchCopyWithImpl(this._self, this._then);

  final ProductMatch _self;
  final $Res Function(ProductMatch) _then;

/// Create a copy of ProductMatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? retailer = null,Object? productId = null,Object? articleCode = null,Object? unitOfMeasure = null,Object? name = null,Object? brand = freezed,Object? price = null,Object? imageId = freezed,Object? pickedBy = null,Object? pickedAt = freezed,}) {
  return _then(ProductMatch(
retailer: null == retailer ? _self.retailer : retailer // ignore: cast_nullable_to_non_nullable
as ProductRetailer,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,articleCode: null == articleCode ? _self.articleCode : articleCode // ignore: cast_nullable_to_non_nullable
as String,unitOfMeasure: null == unitOfMeasure ? _self.unitOfMeasure : unitOfMeasure // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as Money,imageId: freezed == imageId ? _self.imageId : imageId // ignore: cast_nullable_to_non_nullable
as String?,pickedBy: null == pickedBy ? _self.pickedBy : pickedBy // ignore: cast_nullable_to_non_nullable
as String,pickedAt: freezed == pickedAt ? _self.pickedAt : pickedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductMatch].
extension ProductMatchPatterns on ProductMatch {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductMatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductMatch() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductMatch value)  $default,){
final _that = this;
switch (_that) {
case _ProductMatch():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductMatch value)?  $default,){
final _that = this;
switch (_that) {
case _ProductMatch() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProductRetailer retailer,  String productId,  String articleCode,  String unitOfMeasure,  String name,  String? brand,  Money price,  String? imageId,  String pickedBy,  DateTime? pickedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductMatch() when $default != null:
return $default(_that.retailer,_that.productId,_that.articleCode,_that.unitOfMeasure,_that.name,_that.brand,_that.price,_that.imageId,_that.pickedBy,_that.pickedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProductRetailer retailer,  String productId,  String articleCode,  String unitOfMeasure,  String name,  String? brand,  Money price,  String? imageId,  String pickedBy,  DateTime? pickedAt)  $default,) {final _that = this;
switch (_that) {
case _ProductMatch():
return $default(_that.retailer,_that.productId,_that.articleCode,_that.unitOfMeasure,_that.name,_that.brand,_that.price,_that.imageId,_that.pickedBy,_that.pickedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProductRetailer retailer,  String productId,  String articleCode,  String unitOfMeasure,  String name,  String? brand,  Money price,  String? imageId,  String pickedBy,  DateTime? pickedAt)?  $default,) {final _that = this;
switch (_that) {
case _ProductMatch() when $default != null:
return $default(_that.retailer,_that.productId,_that.articleCode,_that.unitOfMeasure,_that.name,_that.brand,_that.price,_that.imageId,_that.pickedBy,_that.pickedAt);case _:
  return null;

}
}

}

/// @nodoc


class _ProductMatch extends ProductMatch {
  const _ProductMatch({required this.retailer, required this.productId, required this.articleCode, required this.unitOfMeasure, required this.name, this.brand, required this.price, this.imageId, required this.pickedBy, this.pickedAt}): super._();
  

@override final  ProductRetailer retailer;
/// The Sixty60 product id, the same id a cart line carries.
@override final  String productId;
/// Article number and unit of measure together, e.g. `10136729EA` — the
/// backup key when a product id is ever re-issued.
@override final  String articleCode;
/// `EA`, `KG`, `PK1`… as Checkers sends it. `KG` is sold by weight.
@override final  String unitOfMeasure;
@override final  String name;
@override final  String? brand;
/// What it cost when it was picked (`ENG-20`); per kilogram for a
/// weighed item.
@override final  Money price;
@override final  String? imageId;
/// The member profile that picked it, the same convention as `addedBy`.
@override final  String pickedBy;
/// Null while the write has not reached the server.
@override final  DateTime? pickedAt;

/// Create a copy of ProductMatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductMatchCopyWith<_ProductMatch> get copyWith => __$ProductMatchCopyWithImpl<_ProductMatch>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductMatch&&(identical(other.retailer, retailer) || other.retailer == retailer)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.articleCode, articleCode) || other.articleCode == articleCode)&&(identical(other.unitOfMeasure, unitOfMeasure) || other.unitOfMeasure == unitOfMeasure)&&(identical(other.name, name) || other.name == name)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.price, price) || other.price == price)&&(identical(other.imageId, imageId) || other.imageId == imageId)&&(identical(other.pickedBy, pickedBy) || other.pickedBy == pickedBy)&&(identical(other.pickedAt, pickedAt) || other.pickedAt == pickedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,retailer,productId,articleCode,unitOfMeasure,name,brand,price,imageId,pickedBy,pickedAt);
}

@override
String toString() {
    return 'ProductMatch(retailer: $retailer, productId: $productId, articleCode: $articleCode, unitOfMeasure: $unitOfMeasure, name: $name, brand: $brand, price: $price, imageId: $imageId, pickedBy: $pickedBy, pickedAt: $pickedAt)';
}


}

/// @nodoc
abstract mixin class _$ProductMatchCopyWith<$Res> implements $ProductMatchCopyWith<$Res> {
  factory _$ProductMatchCopyWith(_ProductMatch value, $Res Function(_ProductMatch) _then) = __$ProductMatchCopyWithImpl;
@override @useResult
$Res call({
 ProductRetailer retailer, String productId, String articleCode, String unitOfMeasure, String name, String? brand, Money price, String? imageId, String pickedBy, DateTime? pickedAt
});




}
/// @nodoc
class __$ProductMatchCopyWithImpl<$Res>
    implements _$ProductMatchCopyWith<$Res> {
  __$ProductMatchCopyWithImpl(this._self, this._then);

  final _ProductMatch _self;
  final $Res Function(_ProductMatch) _then;

/// Create a copy of ProductMatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? retailer = null,Object? productId = null,Object? articleCode = null,Object? unitOfMeasure = null,Object? name = null,Object? brand = freezed,Object? price = null,Object? imageId = freezed,Object? pickedBy = null,Object? pickedAt = freezed,}) {
  return _then(_ProductMatch(
retailer: null == retailer ? _self.retailer : retailer // ignore: cast_nullable_to_non_nullable
as ProductRetailer,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,articleCode: null == articleCode ? _self.articleCode : articleCode // ignore: cast_nullable_to_non_nullable
as String,unitOfMeasure: null == unitOfMeasure ? _self.unitOfMeasure : unitOfMeasure // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as Money,imageId: freezed == imageId ? _self.imageId : imageId // ignore: cast_nullable_to_non_nullable
as String?,pickedBy: null == pickedBy ? _self.pickedBy : pickedBy // ignore: cast_nullable_to_non_nullable
as String,pickedAt: freezed == pickedAt ? _self.pickedAt : pickedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

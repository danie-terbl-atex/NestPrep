// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'frame_groceries.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FrameGroceries {

 ProductRetailer get shop; CheckersArea get area;
/// Create a copy of FrameGroceries
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FrameGroceriesCopyWith<FrameGroceries> get copyWith => _$FrameGroceriesCopyWithImpl<FrameGroceries>(this as FrameGroceries, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FrameGroceries;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FrameGroceries&&(identical(other.shop, _this.shop) || other.shop == _this.shop)&&(identical(other.area, _this.area) || other.area == _this.area));
}


@override
int get hashCode {
  final _this = this as FrameGroceries;
  return Object.hash(runtimeType,_this.shop,_this.area);
}

@override
String toString() {
  final _this = this as FrameGroceries;
  return 'FrameGroceries(shop: ${_this.shop}, area: ${_this.area})';
}


}

/// @nodoc
abstract mixin class $FrameGroceriesCopyWith<$Res>  {
  factory $FrameGroceriesCopyWith(FrameGroceries value, $Res Function(FrameGroceries) _then) = _$FrameGroceriesCopyWithImpl;
@useResult
$Res call({
 ProductRetailer shop, CheckersArea area
});




}
/// @nodoc
class _$FrameGroceriesCopyWithImpl<$Res>
    implements $FrameGroceriesCopyWith<$Res> {
  _$FrameGroceriesCopyWithImpl(this._self, this._then);

  final FrameGroceries _self;
  final $Res Function(FrameGroceries) _then;

/// Create a copy of FrameGroceries
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? shop = null,Object? area = null,}) {
  return _then(FrameGroceries(
shop: null == shop ? _self.shop : shop // ignore: cast_nullable_to_non_nullable
as ProductRetailer,area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as CheckersArea,
  ));
}

}


/// Adds pattern-matching-related methods to [FrameGroceries].
extension FrameGroceriesPatterns on FrameGroceries {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FrameGroceries value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FrameGroceries() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FrameGroceries value)  $default,){
final _that = this;
switch (_that) {
case _FrameGroceries():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FrameGroceries value)?  $default,){
final _that = this;
switch (_that) {
case _FrameGroceries() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProductRetailer shop,  CheckersArea area)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FrameGroceries() when $default != null:
return $default(_that.shop,_that.area);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProductRetailer shop,  CheckersArea area)  $default,) {final _that = this;
switch (_that) {
case _FrameGroceries():
return $default(_that.shop,_that.area);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProductRetailer shop,  CheckersArea area)?  $default,) {final _that = this;
switch (_that) {
case _FrameGroceries() when $default != null:
return $default(_that.shop,_that.area);case _:
  return null;

}
}

}

/// @nodoc


class _FrameGroceries extends FrameGroceries {
  const _FrameGroceries({required this.shop, required this.area}): super._();
  

@override final  ProductRetailer shop;
@override final  CheckersArea area;

/// Create a copy of FrameGroceries
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FrameGroceriesCopyWith<_FrameGroceries> get copyWith => __$FrameGroceriesCopyWithImpl<_FrameGroceries>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FrameGroceries&&(identical(other.shop, shop) || other.shop == shop)&&(identical(other.area, area) || other.area == area));
}


@override
int get hashCode {
    return Object.hash(runtimeType,shop,area);
}

@override
String toString() {
    return 'FrameGroceries(shop: $shop, area: $area)';
}


}

/// @nodoc
abstract mixin class _$FrameGroceriesCopyWith<$Res> implements $FrameGroceriesCopyWith<$Res> {
  factory _$FrameGroceriesCopyWith(_FrameGroceries value, $Res Function(_FrameGroceries) _then) = __$FrameGroceriesCopyWithImpl;
@override @useResult
$Res call({
 ProductRetailer shop, CheckersArea area
});




}
/// @nodoc
class __$FrameGroceriesCopyWithImpl<$Res>
    implements _$FrameGroceriesCopyWith<$Res> {
  __$FrameGroceriesCopyWithImpl(this._self, this._then);

  final _FrameGroceries _self;
  final $Res Function(_FrameGroceries) _then;

/// Create a copy of FrameGroceries
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? shop = null,Object? area = null,}) {
  return _then(_FrameGroceries(
shop: null == shop ? _self.shop : shop // ignore: cast_nullable_to_non_nullable
as ProductRetailer,area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as CheckersArea,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lunch_price.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LunchPrice {

/// The lunch item's id — also the document id.
@JsonKey(includeToJson: false) String get id; int get cents; int get portions;/// ISO 4217, as stored. Read through [money].
 String get currency; String get updatedBy;@ServerTimestampConverter() DateTime? get updatedAt;
/// Create a copy of LunchPrice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LunchPriceCopyWith<LunchPrice> get copyWith => _$LunchPriceCopyWithImpl<LunchPrice>(this as LunchPrice, _$identity);

  /// Serializes this LunchPrice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LunchPrice;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LunchPrice&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.cents, _this.cents) || other.cents == _this.cents)&&(identical(other.portions, _this.portions) || other.portions == _this.portions)&&(identical(other.currency, _this.currency) || other.currency == _this.currency)&&(identical(other.updatedBy, _this.updatedBy) || other.updatedBy == _this.updatedBy)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LunchPrice;
  return Object.hash(runtimeType,_this.id,_this.cents,_this.portions,_this.currency,_this.updatedBy,_this.updatedAt);
}

@override
String toString() {
  final _this = this as LunchPrice;
  return 'LunchPrice(id: ${_this.id}, cents: ${_this.cents}, portions: ${_this.portions}, currency: ${_this.currency}, updatedBy: ${_this.updatedBy}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $LunchPriceCopyWith<$Res>  {
  factory $LunchPriceCopyWith(LunchPrice value, $Res Function(LunchPrice) _then) = _$LunchPriceCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, int cents, int portions, String currency, String updatedBy,@ServerTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$LunchPriceCopyWithImpl<$Res>
    implements $LunchPriceCopyWith<$Res> {
  _$LunchPriceCopyWithImpl(this._self, this._then);

  final LunchPrice _self;
  final $Res Function(LunchPrice) _then;

/// Create a copy of LunchPrice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? cents = null,Object? portions = null,Object? currency = null,Object? updatedBy = null,Object? updatedAt = freezed,}) {
  return _then(LunchPrice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,cents: null == cents ? _self.cents : cents // ignore: cast_nullable_to_non_nullable
as int,portions: null == portions ? _self.portions : portions // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [LunchPrice].
extension LunchPricePatterns on LunchPrice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LunchPrice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LunchPrice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LunchPrice value)  $default,){
final _that = this;
switch (_that) {
case _LunchPrice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LunchPrice value)?  $default,){
final _that = this;
switch (_that) {
case _LunchPrice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  int cents,  int portions,  String currency,  String updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LunchPrice() when $default != null:
return $default(_that.id,_that.cents,_that.portions,_that.currency,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  int cents,  int portions,  String currency,  String updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _LunchPrice():
return $default(_that.id,_that.cents,_that.portions,_that.currency,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  int cents,  int portions,  String currency,  String updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _LunchPrice() when $default != null:
return $default(_that.id,_that.cents,_that.portions,_that.currency,_that.updatedBy,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LunchPrice extends LunchPrice {
  const _LunchPrice({@JsonKey(includeToJson: false) required this.id, required this.cents, this.portions = 1, this.currency = 'ZAR', required this.updatedBy, @ServerTimestampConverter() this.updatedAt}): super._();
  factory _LunchPrice.fromJson(Map<String, dynamic> json) => _$LunchPriceFromJson(json);

/// The lunch item's id — also the document id.
@override@JsonKey(includeToJson: false) final  String id;
@override final  int cents;
@override@JsonKey() final  int portions;
/// ISO 4217, as stored. Read through [money].
@override@JsonKey() final  String currency;
@override final  String updatedBy;
@override@ServerTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of LunchPrice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LunchPriceCopyWith<_LunchPrice> get copyWith => __$LunchPriceCopyWithImpl<_LunchPrice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LunchPriceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LunchPrice&&(identical(other.id, id) || other.id == id)&&(identical(other.cents, cents) || other.cents == cents)&&(identical(other.portions, portions) || other.portions == portions)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,cents,portions,currency,updatedBy,updatedAt);
}

@override
String toString() {
    return 'LunchPrice(id: $id, cents: $cents, portions: $portions, currency: $currency, updatedBy: $updatedBy, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$LunchPriceCopyWith<$Res> implements $LunchPriceCopyWith<$Res> {
  factory _$LunchPriceCopyWith(_LunchPrice value, $Res Function(_LunchPrice) _then) = __$LunchPriceCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, int cents, int portions, String currency, String updatedBy,@ServerTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$LunchPriceCopyWithImpl<$Res>
    implements _$LunchPriceCopyWith<$Res> {
  __$LunchPriceCopyWithImpl(this._self, this._then);

  final _LunchPrice _self;
  final $Res Function(_LunchPrice) _then;

/// Create a copy of LunchPrice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? cents = null,Object? portions = null,Object? currency = null,Object? updatedBy = null,Object? updatedAt = freezed,}) {
  return _then(_LunchPrice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,cents: null == cents ? _self.cents : cents // ignore: cast_nullable_to_non_nullable
as int,portions: null == portions ? _self.portions : portions // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

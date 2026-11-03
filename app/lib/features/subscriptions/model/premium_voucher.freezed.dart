// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'premium_voucher.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PremiumVoucher {

 String get voucherId; PremiumVoucherKind get kind; int get days; String get emailMasked; String? get sku; bool get isTest;
/// Create a copy of PremiumVoucher
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PremiumVoucherCopyWith<PremiumVoucher> get copyWith => _$PremiumVoucherCopyWithImpl<PremiumVoucher>(this as PremiumVoucher, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PremiumVoucher;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PremiumVoucher&&(identical(other.voucherId, _this.voucherId) || other.voucherId == _this.voucherId)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.days, _this.days) || other.days == _this.days)&&(identical(other.emailMasked, _this.emailMasked) || other.emailMasked == _this.emailMasked)&&(identical(other.sku, _this.sku) || other.sku == _this.sku)&&(identical(other.isTest, _this.isTest) || other.isTest == _this.isTest));
}


@override
int get hashCode {
  final _this = this as PremiumVoucher;
  return Object.hash(runtimeType,_this.voucherId,_this.kind,_this.days,_this.emailMasked,_this.sku,_this.isTest);
}

@override
String toString() {
  final _this = this as PremiumVoucher;
  return 'PremiumVoucher(voucherId: ${_this.voucherId}, kind: ${_this.kind}, days: ${_this.days}, emailMasked: ${_this.emailMasked}, sku: ${_this.sku}, isTest: ${_this.isTest})';
}


}

/// @nodoc
abstract mixin class $PremiumVoucherCopyWith<$Res>  {
  factory $PremiumVoucherCopyWith(PremiumVoucher value, $Res Function(PremiumVoucher) _then) = _$PremiumVoucherCopyWithImpl;
@useResult
$Res call({
 String voucherId, PremiumVoucherKind kind, int days, String emailMasked, String? sku, bool isTest
});




}
/// @nodoc
class _$PremiumVoucherCopyWithImpl<$Res>
    implements $PremiumVoucherCopyWith<$Res> {
  _$PremiumVoucherCopyWithImpl(this._self, this._then);

  final PremiumVoucher _self;
  final $Res Function(PremiumVoucher) _then;

/// Create a copy of PremiumVoucher
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? voucherId = null,Object? kind = null,Object? days = null,Object? emailMasked = null,Object? sku = freezed,Object? isTest = null,}) {
  return _then(PremiumVoucher(
voucherId: null == voucherId ? _self.voucherId : voucherId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PremiumVoucherKind,days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int,emailMasked: null == emailMasked ? _self.emailMasked : emailMasked // ignore: cast_nullable_to_non_nullable
as String,sku: freezed == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String?,isTest: null == isTest ? _self.isTest : isTest // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PremiumVoucher].
extension PremiumVoucherPatterns on PremiumVoucher {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PremiumVoucher value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PremiumVoucher() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PremiumVoucher value)  $default,){
final _that = this;
switch (_that) {
case _PremiumVoucher():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PremiumVoucher value)?  $default,){
final _that = this;
switch (_that) {
case _PremiumVoucher() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String voucherId,  PremiumVoucherKind kind,  int days,  String emailMasked,  String? sku,  bool isTest)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PremiumVoucher() when $default != null:
return $default(_that.voucherId,_that.kind,_that.days,_that.emailMasked,_that.sku,_that.isTest);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String voucherId,  PremiumVoucherKind kind,  int days,  String emailMasked,  String? sku,  bool isTest)  $default,) {final _that = this;
switch (_that) {
case _PremiumVoucher():
return $default(_that.voucherId,_that.kind,_that.days,_that.emailMasked,_that.sku,_that.isTest);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String voucherId,  PremiumVoucherKind kind,  int days,  String emailMasked,  String? sku,  bool isTest)?  $default,) {final _that = this;
switch (_that) {
case _PremiumVoucher() when $default != null:
return $default(_that.voucherId,_that.kind,_that.days,_that.emailMasked,_that.sku,_that.isTest);case _:
  return null;

}
}

}

/// @nodoc


class _PremiumVoucher extends PremiumVoucher {
  const _PremiumVoucher({required this.voucherId, required this.kind, required this.days, required this.emailMasked, this.sku, this.isTest = false}): super._();
  

@override final  String voucherId;
@override final  PremiumVoucherKind kind;
@override final  int days;
@override final  String emailMasked;
@override final  String? sku;
@override@JsonKey() final  bool isTest;

/// Create a copy of PremiumVoucher
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PremiumVoucherCopyWith<_PremiumVoucher> get copyWith => __$PremiumVoucherCopyWithImpl<_PremiumVoucher>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PremiumVoucher&&(identical(other.voucherId, voucherId) || other.voucherId == voucherId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.days, days) || other.days == days)&&(identical(other.emailMasked, emailMasked) || other.emailMasked == emailMasked)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.isTest, isTest) || other.isTest == isTest));
}


@override
int get hashCode {
    return Object.hash(runtimeType,voucherId,kind,days,emailMasked,sku,isTest);
}

@override
String toString() {
    return 'PremiumVoucher(voucherId: $voucherId, kind: $kind, days: $days, emailMasked: $emailMasked, sku: $sku, isTest: $isTest)';
}


}

/// @nodoc
abstract mixin class _$PremiumVoucherCopyWith<$Res> implements $PremiumVoucherCopyWith<$Res> {
  factory _$PremiumVoucherCopyWith(_PremiumVoucher value, $Res Function(_PremiumVoucher) _then) = __$PremiumVoucherCopyWithImpl;
@override @useResult
$Res call({
 String voucherId, PremiumVoucherKind kind, int days, String emailMasked, String? sku, bool isTest
});




}
/// @nodoc
class __$PremiumVoucherCopyWithImpl<$Res>
    implements _$PremiumVoucherCopyWith<$Res> {
  __$PremiumVoucherCopyWithImpl(this._self, this._then);

  final _PremiumVoucher _self;
  final $Res Function(_PremiumVoucher) _then;

/// Create a copy of PremiumVoucher
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? voucherId = null,Object? kind = null,Object? days = null,Object? emailMasked = null,Object? sku = freezed,Object? isTest = null,}) {
  return _then(_PremiumVoucher(
voucherId: null == voucherId ? _self.voucherId : voucherId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PremiumVoucherKind,days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int,emailMasked: null == emailMasked ? _self.emailMasked : emailMasked // ignore: cast_nullable_to_non_nullable
as String,sku: freezed == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String?,isTest: null == isTest ? _self.isTest : isTest // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

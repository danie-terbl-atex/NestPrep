// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'voucher_claim.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VoucherClaim {

 String get grantId; int get days; bool get queued; DateTime? get startsAt;
/// Create a copy of VoucherClaim
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VoucherClaimCopyWith<VoucherClaim> get copyWith => _$VoucherClaimCopyWithImpl<VoucherClaim>(this as VoucherClaim, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as VoucherClaim;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VoucherClaim&&(identical(other.grantId, _this.grantId) || other.grantId == _this.grantId)&&(identical(other.days, _this.days) || other.days == _this.days)&&(identical(other.queued, _this.queued) || other.queued == _this.queued)&&(identical(other.startsAt, _this.startsAt) || other.startsAt == _this.startsAt));
}


@override
int get hashCode {
  final _this = this as VoucherClaim;
  return Object.hash(runtimeType,_this.grantId,_this.days,_this.queued,_this.startsAt);
}

@override
String toString() {
  final _this = this as VoucherClaim;
  return 'VoucherClaim(grantId: ${_this.grantId}, days: ${_this.days}, queued: ${_this.queued}, startsAt: ${_this.startsAt})';
}


}

/// @nodoc
abstract mixin class $VoucherClaimCopyWith<$Res>  {
  factory $VoucherClaimCopyWith(VoucherClaim value, $Res Function(VoucherClaim) _then) = _$VoucherClaimCopyWithImpl;
@useResult
$Res call({
 String grantId, int days, bool queued, DateTime? startsAt
});




}
/// @nodoc
class _$VoucherClaimCopyWithImpl<$Res>
    implements $VoucherClaimCopyWith<$Res> {
  _$VoucherClaimCopyWithImpl(this._self, this._then);

  final VoucherClaim _self;
  final $Res Function(VoucherClaim) _then;

/// Create a copy of VoucherClaim
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? grantId = null,Object? days = null,Object? queued = null,Object? startsAt = freezed,}) {
  return _then(VoucherClaim(
grantId: null == grantId ? _self.grantId : grantId // ignore: cast_nullable_to_non_nullable
as String,days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int,queued: null == queued ? _self.queued : queued // ignore: cast_nullable_to_non_nullable
as bool,startsAt: freezed == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [VoucherClaim].
extension VoucherClaimPatterns on VoucherClaim {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VoucherClaim value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VoucherClaim() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VoucherClaim value)  $default,){
final _that = this;
switch (_that) {
case _VoucherClaim():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VoucherClaim value)?  $default,){
final _that = this;
switch (_that) {
case _VoucherClaim() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String grantId,  int days,  bool queued,  DateTime? startsAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VoucherClaim() when $default != null:
return $default(_that.grantId,_that.days,_that.queued,_that.startsAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String grantId,  int days,  bool queued,  DateTime? startsAt)  $default,) {final _that = this;
switch (_that) {
case _VoucherClaim():
return $default(_that.grantId,_that.days,_that.queued,_that.startsAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String grantId,  int days,  bool queued,  DateTime? startsAt)?  $default,) {final _that = this;
switch (_that) {
case _VoucherClaim() when $default != null:
return $default(_that.grantId,_that.days,_that.queued,_that.startsAt);case _:
  return null;

}
}

}

/// @nodoc


class _VoucherClaim implements VoucherClaim {
  const _VoucherClaim({required this.grantId, required this.days, required this.queued, this.startsAt});
  

@override final  String grantId;
@override final  int days;
@override final  bool queued;
@override final  DateTime? startsAt;

/// Create a copy of VoucherClaim
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VoucherClaimCopyWith<_VoucherClaim> get copyWith => __$VoucherClaimCopyWithImpl<_VoucherClaim>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _VoucherClaim&&(identical(other.grantId, grantId) || other.grantId == grantId)&&(identical(other.days, days) || other.days == days)&&(identical(other.queued, queued) || other.queued == queued)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,grantId,days,queued,startsAt);
}

@override
String toString() {
    return 'VoucherClaim(grantId: $grantId, days: $days, queued: $queued, startsAt: $startsAt)';
}


}

/// @nodoc
abstract mixin class _$VoucherClaimCopyWith<$Res> implements $VoucherClaimCopyWith<$Res> {
  factory _$VoucherClaimCopyWith(_VoucherClaim value, $Res Function(_VoucherClaim) _then) = __$VoucherClaimCopyWithImpl;
@override @useResult
$Res call({
 String grantId, int days, bool queued, DateTime? startsAt
});




}
/// @nodoc
class __$VoucherClaimCopyWithImpl<$Res>
    implements _$VoucherClaimCopyWith<$Res> {
  __$VoucherClaimCopyWithImpl(this._self, this._then);

  final _VoucherClaim _self;
  final $Res Function(_VoucherClaim) _then;

/// Create a copy of VoucherClaim
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? grantId = null,Object? days = null,Object? queued = null,Object? startsAt = freezed,}) {
  return _then(_VoucherClaim(
grantId: null == grantId ? _self.grantId : grantId // ignore: cast_nullable_to_non_nullable
as String,days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int,queued: null == queued ? _self.queued : queued // ignore: cast_nullable_to_non_nullable
as bool,startsAt: freezed == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'premium_grant.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PremiumGrant {

@JsonKey(includeToJson: false) String get id; int get days;@InstantConverter() DateTime get grantedAt;/// When it began running, or null while it waits behind paid time.
@NullableTimestampConverter() DateTime? get startsAt;
/// Create a copy of PremiumGrant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PremiumGrantCopyWith<PremiumGrant> get copyWith => _$PremiumGrantCopyWithImpl<PremiumGrant>(this as PremiumGrant, _$identity);

  /// Serializes this PremiumGrant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PremiumGrant;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PremiumGrant&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.days, _this.days) || other.days == _this.days)&&(identical(other.grantedAt, _this.grantedAt) || other.grantedAt == _this.grantedAt)&&(identical(other.startsAt, _this.startsAt) || other.startsAt == _this.startsAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PremiumGrant;
  return Object.hash(runtimeType,_this.id,_this.days,_this.grantedAt,_this.startsAt);
}

@override
String toString() {
  final _this = this as PremiumGrant;
  return 'PremiumGrant(id: ${_this.id}, days: ${_this.days}, grantedAt: ${_this.grantedAt}, startsAt: ${_this.startsAt})';
}


}

/// @nodoc
abstract mixin class $PremiumGrantCopyWith<$Res>  {
  factory $PremiumGrantCopyWith(PremiumGrant value, $Res Function(PremiumGrant) _then) = _$PremiumGrantCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, int days,@InstantConverter() DateTime grantedAt,@NullableTimestampConverter() DateTime? startsAt
});




}
/// @nodoc
class _$PremiumGrantCopyWithImpl<$Res>
    implements $PremiumGrantCopyWith<$Res> {
  _$PremiumGrantCopyWithImpl(this._self, this._then);

  final PremiumGrant _self;
  final $Res Function(PremiumGrant) _then;

/// Create a copy of PremiumGrant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? days = null,Object? grantedAt = null,Object? startsAt = freezed,}) {
  return _then(PremiumGrant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int,grantedAt: null == grantedAt ? _self.grantedAt : grantedAt // ignore: cast_nullable_to_non_nullable
as DateTime,startsAt: freezed == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PremiumGrant].
extension PremiumGrantPatterns on PremiumGrant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PremiumGrant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PremiumGrant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PremiumGrant value)  $default,){
final _that = this;
switch (_that) {
case _PremiumGrant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PremiumGrant value)?  $default,){
final _that = this;
switch (_that) {
case _PremiumGrant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  int days, @InstantConverter()  DateTime grantedAt, @NullableTimestampConverter()  DateTime? startsAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PremiumGrant() when $default != null:
return $default(_that.id,_that.days,_that.grantedAt,_that.startsAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  int days, @InstantConverter()  DateTime grantedAt, @NullableTimestampConverter()  DateTime? startsAt)  $default,) {final _that = this;
switch (_that) {
case _PremiumGrant():
return $default(_that.id,_that.days,_that.grantedAt,_that.startsAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  int days, @InstantConverter()  DateTime grantedAt, @NullableTimestampConverter()  DateTime? startsAt)?  $default,) {final _that = this;
switch (_that) {
case _PremiumGrant() when $default != null:
return $default(_that.id,_that.days,_that.grantedAt,_that.startsAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PremiumGrant extends PremiumGrant {
  const _PremiumGrant({@JsonKey(includeToJson: false) required this.id, required this.days, @InstantConverter() required this.grantedAt, @NullableTimestampConverter() this.startsAt}): super._();
  factory _PremiumGrant.fromJson(Map<String, dynamic> json) => _$PremiumGrantFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  int days;
@override@InstantConverter() final  DateTime grantedAt;
/// When it began running, or null while it waits behind paid time.
@override@NullableTimestampConverter() final  DateTime? startsAt;

/// Create a copy of PremiumGrant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PremiumGrantCopyWith<_PremiumGrant> get copyWith => __$PremiumGrantCopyWithImpl<_PremiumGrant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PremiumGrantToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PremiumGrant&&(identical(other.id, id) || other.id == id)&&(identical(other.days, days) || other.days == days)&&(identical(other.grantedAt, grantedAt) || other.grantedAt == grantedAt)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,days,grantedAt,startsAt);
}

@override
String toString() {
    return 'PremiumGrant(id: $id, days: $days, grantedAt: $grantedAt, startsAt: $startsAt)';
}


}

/// @nodoc
abstract mixin class _$PremiumGrantCopyWith<$Res> implements $PremiumGrantCopyWith<$Res> {
  factory _$PremiumGrantCopyWith(_PremiumGrant value, $Res Function(_PremiumGrant) _then) = __$PremiumGrantCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, int days,@InstantConverter() DateTime grantedAt,@NullableTimestampConverter() DateTime? startsAt
});




}
/// @nodoc
class __$PremiumGrantCopyWithImpl<$Res>
    implements _$PremiumGrantCopyWith<$Res> {
  __$PremiumGrantCopyWithImpl(this._self, this._then);

  final _PremiumGrant _self;
  final $Res Function(_PremiumGrant) _then;

/// Create a copy of PremiumGrant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? days = null,Object? grantedAt = null,Object? startsAt = freezed,}) {
  return _then(_PremiumGrant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int,grantedAt: null == grantedAt ? _self.grantedAt : grantedAt // ignore: cast_nullable_to_non_nullable
as DateTime,startsAt: freezed == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

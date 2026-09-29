// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shift_booking.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShiftBooking {

@JsonKey(includeToJson: false) String get id; String get carerMemberId;@InstantConverter() DateTime get startsAt;@InstantConverter() DateTime get endsAt; String? get note; String get createdBy;@ServerTimestampConverter() DateTime? get createdAt;
/// Create a copy of ShiftBooking
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShiftBookingCopyWith<ShiftBooking> get copyWith => _$ShiftBookingCopyWithImpl<ShiftBooking>(this as ShiftBooking, _$identity);

  /// Serializes this ShiftBooking to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ShiftBooking;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShiftBooking&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.carerMemberId, _this.carerMemberId) || other.carerMemberId == _this.carerMemberId)&&(identical(other.startsAt, _this.startsAt) || other.startsAt == _this.startsAt)&&(identical(other.endsAt, _this.endsAt) || other.endsAt == _this.endsAt)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ShiftBooking;
  return Object.hash(runtimeType,_this.id,_this.carerMemberId,_this.startsAt,_this.endsAt,_this.note,_this.createdBy,_this.createdAt);
}

@override
String toString() {
  final _this = this as ShiftBooking;
  return 'ShiftBooking(id: ${_this.id}, carerMemberId: ${_this.carerMemberId}, startsAt: ${_this.startsAt}, endsAt: ${_this.endsAt}, note: ${_this.note}, createdBy: ${_this.createdBy}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $ShiftBookingCopyWith<$Res>  {
  factory $ShiftBookingCopyWith(ShiftBooking value, $Res Function(ShiftBooking) _then) = _$ShiftBookingCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String carerMemberId,@InstantConverter() DateTime startsAt,@InstantConverter() DateTime endsAt, String? note, String createdBy,@ServerTimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class _$ShiftBookingCopyWithImpl<$Res>
    implements $ShiftBookingCopyWith<$Res> {
  _$ShiftBookingCopyWithImpl(this._self, this._then);

  final ShiftBooking _self;
  final $Res Function(ShiftBooking) _then;

/// Create a copy of ShiftBooking
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? carerMemberId = null,Object? startsAt = null,Object? endsAt = null,Object? note = freezed,Object? createdBy = null,Object? createdAt = freezed,}) {
  return _then(ShiftBooking(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,carerMemberId: null == carerMemberId ? _self.carerMemberId : carerMemberId // ignore: cast_nullable_to_non_nullable
as String,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,endsAt: null == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ShiftBooking].
extension ShiftBookingPatterns on ShiftBooking {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShiftBooking value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShiftBooking() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShiftBooking value)  $default,){
final _that = this;
switch (_that) {
case _ShiftBooking():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShiftBooking value)?  $default,){
final _that = this;
switch (_that) {
case _ShiftBooking() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String carerMemberId, @InstantConverter()  DateTime startsAt, @InstantConverter()  DateTime endsAt,  String? note,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShiftBooking() when $default != null:
return $default(_that.id,_that.carerMemberId,_that.startsAt,_that.endsAt,_that.note,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String carerMemberId, @InstantConverter()  DateTime startsAt, @InstantConverter()  DateTime endsAt,  String? note,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _ShiftBooking():
return $default(_that.id,_that.carerMemberId,_that.startsAt,_that.endsAt,_that.note,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String carerMemberId, @InstantConverter()  DateTime startsAt, @InstantConverter()  DateTime endsAt,  String? note,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ShiftBooking() when $default != null:
return $default(_that.id,_that.carerMemberId,_that.startsAt,_that.endsAt,_that.note,_that.createdBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShiftBooking extends ShiftBooking {
  const _ShiftBooking({@JsonKey(includeToJson: false) required this.id, required this.carerMemberId, @InstantConverter() required this.startsAt, @InstantConverter() required this.endsAt, this.note, required this.createdBy, @ServerTimestampConverter() this.createdAt}): super._();
  factory _ShiftBooking.fromJson(Map<String, dynamic> json) => _$ShiftBookingFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String carerMemberId;
@override@InstantConverter() final  DateTime startsAt;
@override@InstantConverter() final  DateTime endsAt;
@override final  String? note;
@override final  String createdBy;
@override@ServerTimestampConverter() final  DateTime? createdAt;

/// Create a copy of ShiftBooking
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShiftBookingCopyWith<_ShiftBooking> get copyWith => __$ShiftBookingCopyWithImpl<_ShiftBooking>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShiftBookingToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShiftBooking&&(identical(other.id, id) || other.id == id)&&(identical(other.carerMemberId, carerMemberId) || other.carerMemberId == carerMemberId)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt)&&(identical(other.note, note) || other.note == note)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,carerMemberId,startsAt,endsAt,note,createdBy,createdAt);
}

@override
String toString() {
    return 'ShiftBooking(id: $id, carerMemberId: $carerMemberId, startsAt: $startsAt, endsAt: $endsAt, note: $note, createdBy: $createdBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ShiftBookingCopyWith<$Res> implements $ShiftBookingCopyWith<$Res> {
  factory _$ShiftBookingCopyWith(_ShiftBooking value, $Res Function(_ShiftBooking) _then) = __$ShiftBookingCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String carerMemberId,@InstantConverter() DateTime startsAt,@InstantConverter() DateTime endsAt, String? note, String createdBy,@ServerTimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class __$ShiftBookingCopyWithImpl<$Res>
    implements _$ShiftBookingCopyWith<$Res> {
  __$ShiftBookingCopyWithImpl(this._self, this._then);

  final _ShiftBooking _self;
  final $Res Function(_ShiftBooking) _then;

/// Create a copy of ShiftBooking
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? carerMemberId = null,Object? startsAt = null,Object? endsAt = null,Object? note = freezed,Object? createdBy = null,Object? createdAt = freezed,}) {
  return _then(_ShiftBooking(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,carerMemberId: null == carerMemberId ? _self.carerMemberId : carerMemberId // ignore: cast_nullable_to_non_nullable
as String,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,endsAt: null == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

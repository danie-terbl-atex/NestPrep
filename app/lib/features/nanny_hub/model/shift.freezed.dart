// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shift.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Shift {

@JsonKey(includeToJson: false) String get id; String get carerMemberId; String get startedBy;@ServerTimestampConverter() DateTime? get startedAt;@NullableTimestampConverter() DateTime? get endedAt; String? get endedBy; String get status; Map<String, bool> get ticks;
/// Create a copy of Shift
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShiftCopyWith<Shift> get copyWith => _$ShiftCopyWithImpl<Shift>(this as Shift, _$identity);

  /// Serializes this Shift to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Shift;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Shift&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.carerMemberId, _this.carerMemberId) || other.carerMemberId == _this.carerMemberId)&&(identical(other.startedBy, _this.startedBy) || other.startedBy == _this.startedBy)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.endedAt, _this.endedAt) || other.endedAt == _this.endedAt)&&(identical(other.endedBy, _this.endedBy) || other.endedBy == _this.endedBy)&&(identical(other.status, _this.status) || other.status == _this.status)&&const DeepCollectionEquality().equals(other.ticks, _this.ticks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Shift;
  return Object.hash(runtimeType,_this.id,_this.carerMemberId,_this.startedBy,_this.startedAt,_this.endedAt,_this.endedBy,_this.status,const DeepCollectionEquality().hash(_this.ticks));
}

@override
String toString() {
  final _this = this as Shift;
  return 'Shift(id: ${_this.id}, carerMemberId: ${_this.carerMemberId}, startedBy: ${_this.startedBy}, startedAt: ${_this.startedAt}, endedAt: ${_this.endedAt}, endedBy: ${_this.endedBy}, status: ${_this.status}, ticks: ${_this.ticks})';
}


}

/// @nodoc
abstract mixin class $ShiftCopyWith<$Res>  {
  factory $ShiftCopyWith(Shift value, $Res Function(Shift) _then) = _$ShiftCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String carerMemberId, String startedBy,@ServerTimestampConverter() DateTime? startedAt,@NullableTimestampConverter() DateTime? endedAt, String? endedBy, String status, Map<String, bool> ticks
});




}
/// @nodoc
class _$ShiftCopyWithImpl<$Res>
    implements $ShiftCopyWith<$Res> {
  _$ShiftCopyWithImpl(this._self, this._then);

  final Shift _self;
  final $Res Function(Shift) _then;

/// Create a copy of Shift
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? carerMemberId = null,Object? startedBy = null,Object? startedAt = freezed,Object? endedAt = freezed,Object? endedBy = freezed,Object? status = null,Object? ticks = null,}) {
  return _then(Shift(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,carerMemberId: null == carerMemberId ? _self.carerMemberId : carerMemberId // ignore: cast_nullable_to_non_nullable
as String,startedBy: null == startedBy ? _self.startedBy : startedBy // ignore: cast_nullable_to_non_nullable
as String,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endedBy: freezed == endedBy ? _self.endedBy : endedBy // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,ticks: null == ticks ? _self.ticks : ticks // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,
  ));
}

}


/// Adds pattern-matching-related methods to [Shift].
extension ShiftPatterns on Shift {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Shift value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Shift() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Shift value)  $default,){
final _that = this;
switch (_that) {
case _Shift():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Shift value)?  $default,){
final _that = this;
switch (_that) {
case _Shift() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String carerMemberId,  String startedBy, @ServerTimestampConverter()  DateTime? startedAt, @NullableTimestampConverter()  DateTime? endedAt,  String? endedBy,  String status,  Map<String, bool> ticks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Shift() when $default != null:
return $default(_that.id,_that.carerMemberId,_that.startedBy,_that.startedAt,_that.endedAt,_that.endedBy,_that.status,_that.ticks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String carerMemberId,  String startedBy, @ServerTimestampConverter()  DateTime? startedAt, @NullableTimestampConverter()  DateTime? endedAt,  String? endedBy,  String status,  Map<String, bool> ticks)  $default,) {final _that = this;
switch (_that) {
case _Shift():
return $default(_that.id,_that.carerMemberId,_that.startedBy,_that.startedAt,_that.endedAt,_that.endedBy,_that.status,_that.ticks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String carerMemberId,  String startedBy, @ServerTimestampConverter()  DateTime? startedAt, @NullableTimestampConverter()  DateTime? endedAt,  String? endedBy,  String status,  Map<String, bool> ticks)?  $default,) {final _that = this;
switch (_that) {
case _Shift() when $default != null:
return $default(_that.id,_that.carerMemberId,_that.startedBy,_that.startedAt,_that.endedAt,_that.endedBy,_that.status,_that.ticks);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Shift extends Shift {
  const _Shift({@JsonKey(includeToJson: false) required this.id, required this.carerMemberId, required this.startedBy, @ServerTimestampConverter() this.startedAt, @NullableTimestampConverter() this.endedAt, this.endedBy, this.status = Shift.open,  Map<String, bool> ticks = const <String, bool>{}}): _ticks = ticks,super._();
  factory _Shift.fromJson(Map<String, dynamic> json) => _$ShiftFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String carerMemberId;
@override final  String startedBy;
@override@ServerTimestampConverter() final  DateTime? startedAt;
@override@NullableTimestampConverter() final  DateTime? endedAt;
@override final  String? endedBy;
@override@JsonKey() final  String status;
 final  Map<String, bool> _ticks;
@override@JsonKey() Map<String, bool> get ticks {
  if (_ticks is EqualUnmodifiableMapView) return _ticks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_ticks);
}


/// Create a copy of Shift
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShiftCopyWith<_Shift> get copyWith => __$ShiftCopyWithImpl<_Shift>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShiftToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Shift&&(identical(other.id, id) || other.id == id)&&(identical(other.carerMemberId, carerMemberId) || other.carerMemberId == carerMemberId)&&(identical(other.startedBy, startedBy) || other.startedBy == startedBy)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.endedBy, endedBy) || other.endedBy == endedBy)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.ticks, _ticks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,carerMemberId,startedBy,startedAt,endedAt,endedBy,status,const DeepCollectionEquality().hash(_ticks));
}

@override
String toString() {
    return 'Shift(id: $id, carerMemberId: $carerMemberId, startedBy: $startedBy, startedAt: $startedAt, endedAt: $endedAt, endedBy: $endedBy, status: $status, ticks: $ticks)';
}


}

/// @nodoc
abstract mixin class _$ShiftCopyWith<$Res> implements $ShiftCopyWith<$Res> {
  factory _$ShiftCopyWith(_Shift value, $Res Function(_Shift) _then) = __$ShiftCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String carerMemberId, String startedBy,@ServerTimestampConverter() DateTime? startedAt,@NullableTimestampConverter() DateTime? endedAt, String? endedBy, String status, Map<String, bool> ticks
});




}
/// @nodoc
class __$ShiftCopyWithImpl<$Res>
    implements _$ShiftCopyWith<$Res> {
  __$ShiftCopyWithImpl(this._self, this._then);

  final _Shift _self;
  final $Res Function(_Shift) _then;

/// Create a copy of Shift
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? carerMemberId = null,Object? startedBy = null,Object? startedAt = freezed,Object? endedAt = freezed,Object? endedBy = freezed,Object? status = null,Object? ticks = null,}) {
  return _then(_Shift(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,carerMemberId: null == carerMemberId ? _self.carerMemberId : carerMemberId // ignore: cast_nullable_to_non_nullable
as String,startedBy: null == startedBy ? _self.startedBy : startedBy // ignore: cast_nullable_to_non_nullable
as String,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endedBy: freezed == endedBy ? _self.endedBy : endedBy // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,ticks: null == ticks ? _self._ticks : ticks // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,
  ));
}


}

// dart format on

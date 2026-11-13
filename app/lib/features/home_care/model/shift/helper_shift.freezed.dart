// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'helper_shift.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HelperShift {

@JsonKey(includeToJson: false) String get id; String get helperId; String get startedBy;@ServerTimestampConverter() DateTime? get startedAt; String get startedVia;@NullableTimestampConverter() DateTime? get endedAt; String? get endedBy; String? get endedVia; String get status;
/// Create a copy of HelperShift
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HelperShiftCopyWith<HelperShift> get copyWith => _$HelperShiftCopyWithImpl<HelperShift>(this as HelperShift, _$identity);

  /// Serializes this HelperShift to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HelperShift;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HelperShift&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.helperId, _this.helperId) || other.helperId == _this.helperId)&&(identical(other.startedBy, _this.startedBy) || other.startedBy == _this.startedBy)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.startedVia, _this.startedVia) || other.startedVia == _this.startedVia)&&(identical(other.endedAt, _this.endedAt) || other.endedAt == _this.endedAt)&&(identical(other.endedBy, _this.endedBy) || other.endedBy == _this.endedBy)&&(identical(other.endedVia, _this.endedVia) || other.endedVia == _this.endedVia)&&(identical(other.status, _this.status) || other.status == _this.status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HelperShift;
  return Object.hash(runtimeType,_this.id,_this.helperId,_this.startedBy,_this.startedAt,_this.startedVia,_this.endedAt,_this.endedBy,_this.endedVia,_this.status);
}

@override
String toString() {
  final _this = this as HelperShift;
  return 'HelperShift(id: ${_this.id}, helperId: ${_this.helperId}, startedBy: ${_this.startedBy}, startedAt: ${_this.startedAt}, startedVia: ${_this.startedVia}, endedAt: ${_this.endedAt}, endedBy: ${_this.endedBy}, endedVia: ${_this.endedVia}, status: ${_this.status})';
}


}

/// @nodoc
abstract mixin class $HelperShiftCopyWith<$Res>  {
  factory $HelperShiftCopyWith(HelperShift value, $Res Function(HelperShift) _then) = _$HelperShiftCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String helperId, String startedBy,@ServerTimestampConverter() DateTime? startedAt, String startedVia,@NullableTimestampConverter() DateTime? endedAt, String? endedBy, String? endedVia, String status
});




}
/// @nodoc
class _$HelperShiftCopyWithImpl<$Res>
    implements $HelperShiftCopyWith<$Res> {
  _$HelperShiftCopyWithImpl(this._self, this._then);

  final HelperShift _self;
  final $Res Function(HelperShift) _then;

/// Create a copy of HelperShift
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? helperId = null,Object? startedBy = null,Object? startedAt = freezed,Object? startedVia = null,Object? endedAt = freezed,Object? endedBy = freezed,Object? endedVia = freezed,Object? status = null,}) {
  return _then(HelperShift(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,helperId: null == helperId ? _self.helperId : helperId // ignore: cast_nullable_to_non_nullable
as String,startedBy: null == startedBy ? _self.startedBy : startedBy // ignore: cast_nullable_to_non_nullable
as String,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,startedVia: null == startedVia ? _self.startedVia : startedVia // ignore: cast_nullable_to_non_nullable
as String,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endedBy: freezed == endedBy ? _self.endedBy : endedBy // ignore: cast_nullable_to_non_nullable
as String?,endedVia: freezed == endedVia ? _self.endedVia : endedVia // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [HelperShift].
extension HelperShiftPatterns on HelperShift {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HelperShift value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HelperShift() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HelperShift value)  $default,){
final _that = this;
switch (_that) {
case _HelperShift():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HelperShift value)?  $default,){
final _that = this;
switch (_that) {
case _HelperShift() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String helperId,  String startedBy, @ServerTimestampConverter()  DateTime? startedAt,  String startedVia, @NullableTimestampConverter()  DateTime? endedAt,  String? endedBy,  String? endedVia,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HelperShift() when $default != null:
return $default(_that.id,_that.helperId,_that.startedBy,_that.startedAt,_that.startedVia,_that.endedAt,_that.endedBy,_that.endedVia,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String helperId,  String startedBy, @ServerTimestampConverter()  DateTime? startedAt,  String startedVia, @NullableTimestampConverter()  DateTime? endedAt,  String? endedBy,  String? endedVia,  String status)  $default,) {final _that = this;
switch (_that) {
case _HelperShift():
return $default(_that.id,_that.helperId,_that.startedBy,_that.startedAt,_that.startedVia,_that.endedAt,_that.endedBy,_that.endedVia,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String helperId,  String startedBy, @ServerTimestampConverter()  DateTime? startedAt,  String startedVia, @NullableTimestampConverter()  DateTime? endedAt,  String? endedBy,  String? endedVia,  String status)?  $default,) {final _that = this;
switch (_that) {
case _HelperShift() when $default != null:
return $default(_that.id,_that.helperId,_that.startedBy,_that.startedAt,_that.startedVia,_that.endedAt,_that.endedBy,_that.endedVia,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HelperShift extends HelperShift {
  const _HelperShift({@JsonKey(includeToJson: false) required this.id, required this.helperId, required this.startedBy, @ServerTimestampConverter() this.startedAt, this.startedVia = HelperShift.app, @NullableTimestampConverter() this.endedAt, this.endedBy, this.endedVia, this.status = HelperShift.open}): super._();
  factory _HelperShift.fromJson(Map<String, dynamic> json) => _$HelperShiftFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String helperId;
@override final  String startedBy;
@override@ServerTimestampConverter() final  DateTime? startedAt;
@override@JsonKey() final  String startedVia;
@override@NullableTimestampConverter() final  DateTime? endedAt;
@override final  String? endedBy;
@override final  String? endedVia;
@override@JsonKey() final  String status;

/// Create a copy of HelperShift
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HelperShiftCopyWith<_HelperShift> get copyWith => __$HelperShiftCopyWithImpl<_HelperShift>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HelperShiftToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HelperShift&&(identical(other.id, id) || other.id == id)&&(identical(other.helperId, helperId) || other.helperId == helperId)&&(identical(other.startedBy, startedBy) || other.startedBy == startedBy)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.startedVia, startedVia) || other.startedVia == startedVia)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.endedBy, endedBy) || other.endedBy == endedBy)&&(identical(other.endedVia, endedVia) || other.endedVia == endedVia)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,helperId,startedBy,startedAt,startedVia,endedAt,endedBy,endedVia,status);
}

@override
String toString() {
    return 'HelperShift(id: $id, helperId: $helperId, startedBy: $startedBy, startedAt: $startedAt, startedVia: $startedVia, endedAt: $endedAt, endedBy: $endedBy, endedVia: $endedVia, status: $status)';
}


}

/// @nodoc
abstract mixin class _$HelperShiftCopyWith<$Res> implements $HelperShiftCopyWith<$Res> {
  factory _$HelperShiftCopyWith(_HelperShift value, $Res Function(_HelperShift) _then) = __$HelperShiftCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String helperId, String startedBy,@ServerTimestampConverter() DateTime? startedAt, String startedVia,@NullableTimestampConverter() DateTime? endedAt, String? endedBy, String? endedVia, String status
});




}
/// @nodoc
class __$HelperShiftCopyWithImpl<$Res>
    implements _$HelperShiftCopyWith<$Res> {
  __$HelperShiftCopyWithImpl(this._self, this._then);

  final _HelperShift _self;
  final $Res Function(_HelperShift) _then;

/// Create a copy of HelperShift
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? helperId = null,Object? startedBy = null,Object? startedAt = freezed,Object? startedVia = null,Object? endedAt = freezed,Object? endedBy = freezed,Object? endedVia = freezed,Object? status = null,}) {
  return _then(_HelperShift(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,helperId: null == helperId ? _self.helperId : helperId // ignore: cast_nullable_to_non_nullable
as String,startedBy: null == startedBy ? _self.startedBy : startedBy // ignore: cast_nullable_to_non_nullable
as String,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,startedVia: null == startedVia ? _self.startedVia : startedVia // ignore: cast_nullable_to_non_nullable
as String,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endedBy: freezed == endedBy ? _self.endedBy : endedBy // ignore: cast_nullable_to_non_nullable
as String?,endedVia: freezed == endedVia ? _self.endedVia : endedVia // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kid_device.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$KidDevice {

@JsonKey(includeToJson: false) String get id;/// The kid profile this device is signed in as.
 String get memberId;/// What the parent called it when they made the code. Empty when they
/// did not say.
 String get label;/// The admin account that made the code it was paired with.
 String get pairedBy;@ServerTimestampConverter() DateTime? get pairedAt;
/// Create a copy of KidDevice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KidDeviceCopyWith<KidDevice> get copyWith => _$KidDeviceCopyWithImpl<KidDevice>(this as KidDevice, _$identity);

  /// Serializes this KidDevice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as KidDevice;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KidDevice&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.memberId, _this.memberId) || other.memberId == _this.memberId)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.pairedBy, _this.pairedBy) || other.pairedBy == _this.pairedBy)&&(identical(other.pairedAt, _this.pairedAt) || other.pairedAt == _this.pairedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as KidDevice;
  return Object.hash(runtimeType,_this.id,_this.memberId,_this.label,_this.pairedBy,_this.pairedAt);
}

@override
String toString() {
  final _this = this as KidDevice;
  return 'KidDevice(id: ${_this.id}, memberId: ${_this.memberId}, label: ${_this.label}, pairedBy: ${_this.pairedBy}, pairedAt: ${_this.pairedAt})';
}


}

/// @nodoc
abstract mixin class $KidDeviceCopyWith<$Res>  {
  factory $KidDeviceCopyWith(KidDevice value, $Res Function(KidDevice) _then) = _$KidDeviceCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String memberId, String label, String pairedBy,@ServerTimestampConverter() DateTime? pairedAt
});




}
/// @nodoc
class _$KidDeviceCopyWithImpl<$Res>
    implements $KidDeviceCopyWith<$Res> {
  _$KidDeviceCopyWithImpl(this._self, this._then);

  final KidDevice _self;
  final $Res Function(KidDevice) _then;

/// Create a copy of KidDevice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? memberId = null,Object? label = null,Object? pairedBy = null,Object? pairedAt = freezed,}) {
  return _then(KidDevice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,pairedBy: null == pairedBy ? _self.pairedBy : pairedBy // ignore: cast_nullable_to_non_nullable
as String,pairedAt: freezed == pairedAt ? _self.pairedAt : pairedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [KidDevice].
extension KidDevicePatterns on KidDevice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KidDevice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KidDevice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KidDevice value)  $default,){
final _that = this;
switch (_that) {
case _KidDevice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KidDevice value)?  $default,){
final _that = this;
switch (_that) {
case _KidDevice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String memberId,  String label,  String pairedBy, @ServerTimestampConverter()  DateTime? pairedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KidDevice() when $default != null:
return $default(_that.id,_that.memberId,_that.label,_that.pairedBy,_that.pairedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String memberId,  String label,  String pairedBy, @ServerTimestampConverter()  DateTime? pairedAt)  $default,) {final _that = this;
switch (_that) {
case _KidDevice():
return $default(_that.id,_that.memberId,_that.label,_that.pairedBy,_that.pairedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String memberId,  String label,  String pairedBy, @ServerTimestampConverter()  DateTime? pairedAt)?  $default,) {final _that = this;
switch (_that) {
case _KidDevice() when $default != null:
return $default(_that.id,_that.memberId,_that.label,_that.pairedBy,_that.pairedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _KidDevice extends KidDevice {
  const _KidDevice({@JsonKey(includeToJson: false) required this.id, required this.memberId, this.label = '', required this.pairedBy, @ServerTimestampConverter() this.pairedAt}): super._();
  factory _KidDevice.fromJson(Map<String, dynamic> json) => _$KidDeviceFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
/// The kid profile this device is signed in as.
@override final  String memberId;
/// What the parent called it when they made the code. Empty when they
/// did not say.
@override@JsonKey() final  String label;
/// The admin account that made the code it was paired with.
@override final  String pairedBy;
@override@ServerTimestampConverter() final  DateTime? pairedAt;

/// Create a copy of KidDevice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KidDeviceCopyWith<_KidDevice> get copyWith => __$KidDeviceCopyWithImpl<_KidDevice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KidDeviceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _KidDevice&&(identical(other.id, id) || other.id == id)&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.label, label) || other.label == label)&&(identical(other.pairedBy, pairedBy) || other.pairedBy == pairedBy)&&(identical(other.pairedAt, pairedAt) || other.pairedAt == pairedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,memberId,label,pairedBy,pairedAt);
}

@override
String toString() {
    return 'KidDevice(id: $id, memberId: $memberId, label: $label, pairedBy: $pairedBy, pairedAt: $pairedAt)';
}


}

/// @nodoc
abstract mixin class _$KidDeviceCopyWith<$Res> implements $KidDeviceCopyWith<$Res> {
  factory _$KidDeviceCopyWith(_KidDevice value, $Res Function(_KidDevice) _then) = __$KidDeviceCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String memberId, String label, String pairedBy,@ServerTimestampConverter() DateTime? pairedAt
});




}
/// @nodoc
class __$KidDeviceCopyWithImpl<$Res>
    implements _$KidDeviceCopyWith<$Res> {
  __$KidDeviceCopyWithImpl(this._self, this._then);

  final _KidDevice _self;
  final $Res Function(_KidDevice) _then;

/// Create a copy of KidDevice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? memberId = null,Object? label = null,Object? pairedBy = null,Object? pairedAt = freezed,}) {
  return _then(_KidDevice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,pairedBy: null == pairedBy ? _self.pairedBy : pairedBy // ignore: cast_nullable_to_non_nullable
as String,pairedAt: freezed == pairedAt ? _self.pairedAt : pairedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

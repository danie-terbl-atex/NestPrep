// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'member_location.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MemberLocation {

@JsonKey(includeToJson: false) String get id;@CoordinatesConverter() Coordinates get point; int get accuracyMetres;@ServerTimestampConverter() DateTime? get reportedAt;/// When this share ends: the member's window, or the lease an always-on
/// phone renews on every write. The rules refuse any write once it has
/// passed, which is what actually stops a share.
@InstantConverter() DateTime get sharingUntil;@JsonKey(unknownEnumValue: ShareMode.window) ShareMode get mode;@JsonKey(includeIfNull: false) int? get batteryPercent;@JsonKey(includeIfNull: false) bool? get charging;@JsonKey(includeIfNull: false, unknownEnumValue: DeviceMotion.unknown) DeviceMotion? get motion;
/// Create a copy of MemberLocation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberLocationCopyWith<MemberLocation> get copyWith => _$MemberLocationCopyWithImpl<MemberLocation>(this as MemberLocation, _$identity);

  /// Serializes this MemberLocation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MemberLocation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberLocation&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.point, _this.point) || other.point == _this.point)&&(identical(other.accuracyMetres, _this.accuracyMetres) || other.accuracyMetres == _this.accuracyMetres)&&(identical(other.reportedAt, _this.reportedAt) || other.reportedAt == _this.reportedAt)&&(identical(other.sharingUntil, _this.sharingUntil) || other.sharingUntil == _this.sharingUntil)&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&(identical(other.batteryPercent, _this.batteryPercent) || other.batteryPercent == _this.batteryPercent)&&(identical(other.charging, _this.charging) || other.charging == _this.charging)&&(identical(other.motion, _this.motion) || other.motion == _this.motion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MemberLocation;
  return Object.hash(runtimeType,_this.id,_this.point,_this.accuracyMetres,_this.reportedAt,_this.sharingUntil,_this.mode,_this.batteryPercent,_this.charging,_this.motion);
}

@override
String toString() {
  final _this = this as MemberLocation;
  return 'MemberLocation(id: ${_this.id}, point: ${_this.point}, accuracyMetres: ${_this.accuracyMetres}, reportedAt: ${_this.reportedAt}, sharingUntil: ${_this.sharingUntil}, mode: ${_this.mode}, batteryPercent: ${_this.batteryPercent}, charging: ${_this.charging}, motion: ${_this.motion})';
}


}

/// @nodoc
abstract mixin class $MemberLocationCopyWith<$Res>  {
  factory $MemberLocationCopyWith(MemberLocation value, $Res Function(MemberLocation) _then) = _$MemberLocationCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id,@CoordinatesConverter() Coordinates point, int accuracyMetres,@ServerTimestampConverter() DateTime? reportedAt,@InstantConverter() DateTime sharingUntil,@JsonKey(unknownEnumValue: ShareMode.window) ShareMode mode,@JsonKey(includeIfNull: false) int? batteryPercent,@JsonKey(includeIfNull: false) bool? charging,@JsonKey(includeIfNull: false, unknownEnumValue: DeviceMotion.unknown) DeviceMotion? motion
});




}
/// @nodoc
class _$MemberLocationCopyWithImpl<$Res>
    implements $MemberLocationCopyWith<$Res> {
  _$MemberLocationCopyWithImpl(this._self, this._then);

  final MemberLocation _self;
  final $Res Function(MemberLocation) _then;

/// Create a copy of MemberLocation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? point = null,Object? accuracyMetres = null,Object? reportedAt = freezed,Object? sharingUntil = null,Object? mode = null,Object? batteryPercent = freezed,Object? charging = freezed,Object? motion = freezed,}) {
  return _then(MemberLocation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,point: null == point ? _self.point : point // ignore: cast_nullable_to_non_nullable
as Coordinates,accuracyMetres: null == accuracyMetres ? _self.accuracyMetres : accuracyMetres // ignore: cast_nullable_to_non_nullable
as int,reportedAt: freezed == reportedAt ? _self.reportedAt : reportedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,sharingUntil: null == sharingUntil ? _self.sharingUntil : sharingUntil // ignore: cast_nullable_to_non_nullable
as DateTime,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as ShareMode,batteryPercent: freezed == batteryPercent ? _self.batteryPercent : batteryPercent // ignore: cast_nullable_to_non_nullable
as int?,charging: freezed == charging ? _self.charging : charging // ignore: cast_nullable_to_non_nullable
as bool?,motion: freezed == motion ? _self.motion : motion // ignore: cast_nullable_to_non_nullable
as DeviceMotion?,
  ));
}

}


/// Adds pattern-matching-related methods to [MemberLocation].
extension MemberLocationPatterns on MemberLocation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemberLocation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemberLocation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemberLocation value)  $default,){
final _that = this;
switch (_that) {
case _MemberLocation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemberLocation value)?  $default,){
final _that = this;
switch (_that) {
case _MemberLocation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id, @CoordinatesConverter()  Coordinates point,  int accuracyMetres, @ServerTimestampConverter()  DateTime? reportedAt, @InstantConverter()  DateTime sharingUntil, @JsonKey(unknownEnumValue: ShareMode.window)  ShareMode mode, @JsonKey(includeIfNull: false)  int? batteryPercent, @JsonKey(includeIfNull: false)  bool? charging, @JsonKey(includeIfNull: false, unknownEnumValue: DeviceMotion.unknown)  DeviceMotion? motion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemberLocation() when $default != null:
return $default(_that.id,_that.point,_that.accuracyMetres,_that.reportedAt,_that.sharingUntil,_that.mode,_that.batteryPercent,_that.charging,_that.motion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id, @CoordinatesConverter()  Coordinates point,  int accuracyMetres, @ServerTimestampConverter()  DateTime? reportedAt, @InstantConverter()  DateTime sharingUntil, @JsonKey(unknownEnumValue: ShareMode.window)  ShareMode mode, @JsonKey(includeIfNull: false)  int? batteryPercent, @JsonKey(includeIfNull: false)  bool? charging, @JsonKey(includeIfNull: false, unknownEnumValue: DeviceMotion.unknown)  DeviceMotion? motion)  $default,) {final _that = this;
switch (_that) {
case _MemberLocation():
return $default(_that.id,_that.point,_that.accuracyMetres,_that.reportedAt,_that.sharingUntil,_that.mode,_that.batteryPercent,_that.charging,_that.motion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id, @CoordinatesConverter()  Coordinates point,  int accuracyMetres, @ServerTimestampConverter()  DateTime? reportedAt, @InstantConverter()  DateTime sharingUntil, @JsonKey(unknownEnumValue: ShareMode.window)  ShareMode mode, @JsonKey(includeIfNull: false)  int? batteryPercent, @JsonKey(includeIfNull: false)  bool? charging, @JsonKey(includeIfNull: false, unknownEnumValue: DeviceMotion.unknown)  DeviceMotion? motion)?  $default,) {final _that = this;
switch (_that) {
case _MemberLocation() when $default != null:
return $default(_that.id,_that.point,_that.accuracyMetres,_that.reportedAt,_that.sharingUntil,_that.mode,_that.batteryPercent,_that.charging,_that.motion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemberLocation extends MemberLocation {
  const _MemberLocation({@JsonKey(includeToJson: false) required this.id, @CoordinatesConverter() required this.point, required this.accuracyMetres, @ServerTimestampConverter() this.reportedAt, @InstantConverter() required this.sharingUntil, @JsonKey(unknownEnumValue: ShareMode.window) this.mode = ShareMode.window, @JsonKey(includeIfNull: false) this.batteryPercent, @JsonKey(includeIfNull: false) this.charging, @JsonKey(includeIfNull: false, unknownEnumValue: DeviceMotion.unknown) this.motion}): super._();
  factory _MemberLocation.fromJson(Map<String, dynamic> json) => _$MemberLocationFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override@CoordinatesConverter() final  Coordinates point;
@override final  int accuracyMetres;
@override@ServerTimestampConverter() final  DateTime? reportedAt;
/// When this share ends: the member's window, or the lease an always-on
/// phone renews on every write. The rules refuse any write once it has
/// passed, which is what actually stops a share.
@override@InstantConverter() final  DateTime sharingUntil;
@override@JsonKey(unknownEnumValue: ShareMode.window) final  ShareMode mode;
@override@JsonKey(includeIfNull: false) final  int? batteryPercent;
@override@JsonKey(includeIfNull: false) final  bool? charging;
@override@JsonKey(includeIfNull: false, unknownEnumValue: DeviceMotion.unknown) final  DeviceMotion? motion;

/// Create a copy of MemberLocation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberLocationCopyWith<_MemberLocation> get copyWith => __$MemberLocationCopyWithImpl<_MemberLocation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberLocationToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemberLocation&&(identical(other.id, id) || other.id == id)&&(identical(other.point, point) || other.point == point)&&(identical(other.accuracyMetres, accuracyMetres) || other.accuracyMetres == accuracyMetres)&&(identical(other.reportedAt, reportedAt) || other.reportedAt == reportedAt)&&(identical(other.sharingUntil, sharingUntil) || other.sharingUntil == sharingUntil)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.batteryPercent, batteryPercent) || other.batteryPercent == batteryPercent)&&(identical(other.charging, charging) || other.charging == charging)&&(identical(other.motion, motion) || other.motion == motion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,point,accuracyMetres,reportedAt,sharingUntil,mode,batteryPercent,charging,motion);
}

@override
String toString() {
    return 'MemberLocation(id: $id, point: $point, accuracyMetres: $accuracyMetres, reportedAt: $reportedAt, sharingUntil: $sharingUntil, mode: $mode, batteryPercent: $batteryPercent, charging: $charging, motion: $motion)';
}


}

/// @nodoc
abstract mixin class _$MemberLocationCopyWith<$Res> implements $MemberLocationCopyWith<$Res> {
  factory _$MemberLocationCopyWith(_MemberLocation value, $Res Function(_MemberLocation) _then) = __$MemberLocationCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id,@CoordinatesConverter() Coordinates point, int accuracyMetres,@ServerTimestampConverter() DateTime? reportedAt,@InstantConverter() DateTime sharingUntil,@JsonKey(unknownEnumValue: ShareMode.window) ShareMode mode,@JsonKey(includeIfNull: false) int? batteryPercent,@JsonKey(includeIfNull: false) bool? charging,@JsonKey(includeIfNull: false, unknownEnumValue: DeviceMotion.unknown) DeviceMotion? motion
});




}
/// @nodoc
class __$MemberLocationCopyWithImpl<$Res>
    implements _$MemberLocationCopyWith<$Res> {
  __$MemberLocationCopyWithImpl(this._self, this._then);

  final _MemberLocation _self;
  final $Res Function(_MemberLocation) _then;

/// Create a copy of MemberLocation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? point = null,Object? accuracyMetres = null,Object? reportedAt = freezed,Object? sharingUntil = null,Object? mode = null,Object? batteryPercent = freezed,Object? charging = freezed,Object? motion = freezed,}) {
  return _then(_MemberLocation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,point: null == point ? _self.point : point // ignore: cast_nullable_to_non_nullable
as Coordinates,accuracyMetres: null == accuracyMetres ? _self.accuracyMetres : accuracyMetres // ignore: cast_nullable_to_non_nullable
as int,reportedAt: freezed == reportedAt ? _self.reportedAt : reportedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,sharingUntil: null == sharingUntil ? _self.sharingUntil : sharingUntil // ignore: cast_nullable_to_non_nullable
as DateTime,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as ShareMode,batteryPercent: freezed == batteryPercent ? _self.batteryPercent : batteryPercent // ignore: cast_nullable_to_non_nullable
as int?,charging: freezed == charging ? _self.charging : charging // ignore: cast_nullable_to_non_nullable
as bool?,motion: freezed == motion ? _self.motion : motion // ignore: cast_nullable_to_non_nullable
as DeviceMotion?,
  ));
}


}

// dart format on

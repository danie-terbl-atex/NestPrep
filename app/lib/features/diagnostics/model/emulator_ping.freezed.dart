// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'emulator_ping.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EmulatorPing {

@JsonKey(includeToJson: false) String get id; String get sentFrom;@ServerTimestampConverter() DateTime? get sentAt;
/// Create a copy of EmulatorPing
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmulatorPingCopyWith<EmulatorPing> get copyWith => _$EmulatorPingCopyWithImpl<EmulatorPing>(this as EmulatorPing, _$identity);

  /// Serializes this EmulatorPing to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as EmulatorPing;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmulatorPing&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.sentFrom, _this.sentFrom) || other.sentFrom == _this.sentFrom)&&(identical(other.sentAt, _this.sentAt) || other.sentAt == _this.sentAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EmulatorPing;
  return Object.hash(runtimeType,_this.id,_this.sentFrom,_this.sentAt);
}

@override
String toString() {
  final _this = this as EmulatorPing;
  return 'EmulatorPing(id: ${_this.id}, sentFrom: ${_this.sentFrom}, sentAt: ${_this.sentAt})';
}


}

/// @nodoc
abstract mixin class $EmulatorPingCopyWith<$Res>  {
  factory $EmulatorPingCopyWith(EmulatorPing value, $Res Function(EmulatorPing) _then) = _$EmulatorPingCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String sentFrom,@ServerTimestampConverter() DateTime? sentAt
});




}
/// @nodoc
class _$EmulatorPingCopyWithImpl<$Res>
    implements $EmulatorPingCopyWith<$Res> {
  _$EmulatorPingCopyWithImpl(this._self, this._then);

  final EmulatorPing _self;
  final $Res Function(EmulatorPing) _then;

/// Create a copy of EmulatorPing
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sentFrom = null,Object? sentAt = freezed,}) {
  return _then(EmulatorPing(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sentFrom: null == sentFrom ? _self.sentFrom : sentFrom // ignore: cast_nullable_to_non_nullable
as String,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [EmulatorPing].
extension EmulatorPingPatterns on EmulatorPing {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmulatorPing value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmulatorPing() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmulatorPing value)  $default,){
final _that = this;
switch (_that) {
case _EmulatorPing():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmulatorPing value)?  $default,){
final _that = this;
switch (_that) {
case _EmulatorPing() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String sentFrom, @ServerTimestampConverter()  DateTime? sentAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmulatorPing() when $default != null:
return $default(_that.id,_that.sentFrom,_that.sentAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String sentFrom, @ServerTimestampConverter()  DateTime? sentAt)  $default,) {final _that = this;
switch (_that) {
case _EmulatorPing():
return $default(_that.id,_that.sentFrom,_that.sentAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String sentFrom, @ServerTimestampConverter()  DateTime? sentAt)?  $default,) {final _that = this;
switch (_that) {
case _EmulatorPing() when $default != null:
return $default(_that.id,_that.sentFrom,_that.sentAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EmulatorPing implements EmulatorPing {
  const _EmulatorPing({@JsonKey(includeToJson: false) required this.id, required this.sentFrom, @ServerTimestampConverter() this.sentAt});
  factory _EmulatorPing.fromJson(Map<String, dynamic> json) => _$EmulatorPingFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String sentFrom;
@override@ServerTimestampConverter() final  DateTime? sentAt;

/// Create a copy of EmulatorPing
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmulatorPingCopyWith<_EmulatorPing> get copyWith => __$EmulatorPingCopyWithImpl<_EmulatorPing>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EmulatorPingToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmulatorPing&&(identical(other.id, id) || other.id == id)&&(identical(other.sentFrom, sentFrom) || other.sentFrom == sentFrom)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,sentFrom,sentAt);
}

@override
String toString() {
    return 'EmulatorPing(id: $id, sentFrom: $sentFrom, sentAt: $sentAt)';
}


}

/// @nodoc
abstract mixin class _$EmulatorPingCopyWith<$Res> implements $EmulatorPingCopyWith<$Res> {
  factory _$EmulatorPingCopyWith(_EmulatorPing value, $Res Function(_EmulatorPing) _then) = __$EmulatorPingCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String sentFrom,@ServerTimestampConverter() DateTime? sentAt
});




}
/// @nodoc
class __$EmulatorPingCopyWithImpl<$Res>
    implements _$EmulatorPingCopyWith<$Res> {
  __$EmulatorPingCopyWithImpl(this._self, this._then);

  final _EmulatorPing _self;
  final $Res Function(_EmulatorPing) _then;

/// Create a copy of EmulatorPing
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sentFrom = null,Object? sentAt = freezed,}) {
  return _then(_EmulatorPing(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sentFrom: null == sentFrom ? _self.sentFrom : sentFrom // ignore: cast_nullable_to_non_nullable
as String,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

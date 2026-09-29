// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'member_health.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MemberHealth {

@JsonKey(includeToJson: false) String get id; Map<String, Medication> get medications;
/// Create a copy of MemberHealth
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberHealthCopyWith<MemberHealth> get copyWith => _$MemberHealthCopyWithImpl<MemberHealth>(this as MemberHealth, _$identity);

  /// Serializes this MemberHealth to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MemberHealth;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberHealth&&(identical(other.id, _this.id) || other.id == _this.id)&&const DeepCollectionEquality().equals(other.medications, _this.medications));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MemberHealth;
  return Object.hash(runtimeType,_this.id,const DeepCollectionEquality().hash(_this.medications));
}

@override
String toString() {
  final _this = this as MemberHealth;
  return 'MemberHealth(id: ${_this.id}, medications: ${_this.medications})';
}


}

/// @nodoc
abstract mixin class $MemberHealthCopyWith<$Res>  {
  factory $MemberHealthCopyWith(MemberHealth value, $Res Function(MemberHealth) _then) = _$MemberHealthCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, Map<String, Medication> medications
});




}
/// @nodoc
class _$MemberHealthCopyWithImpl<$Res>
    implements $MemberHealthCopyWith<$Res> {
  _$MemberHealthCopyWithImpl(this._self, this._then);

  final MemberHealth _self;
  final $Res Function(MemberHealth) _then;

/// Create a copy of MemberHealth
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? medications = null,}) {
  return _then(MemberHealth(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,medications: null == medications ? _self.medications : medications // ignore: cast_nullable_to_non_nullable
as Map<String, Medication>,
  ));
}

}


/// Adds pattern-matching-related methods to [MemberHealth].
extension MemberHealthPatterns on MemberHealth {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemberHealth value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemberHealth() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemberHealth value)  $default,){
final _that = this;
switch (_that) {
case _MemberHealth():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemberHealth value)?  $default,){
final _that = this;
switch (_that) {
case _MemberHealth() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  Map<String, Medication> medications)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemberHealth() when $default != null:
return $default(_that.id,_that.medications);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  Map<String, Medication> medications)  $default,) {final _that = this;
switch (_that) {
case _MemberHealth():
return $default(_that.id,_that.medications);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  Map<String, Medication> medications)?  $default,) {final _that = this;
switch (_that) {
case _MemberHealth() when $default != null:
return $default(_that.id,_that.medications);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemberHealth extends MemberHealth {
  const _MemberHealth({@JsonKey(includeToJson: false) required this.id,  Map<String, Medication> medications = const <String, Medication>{}}): _medications = medications,super._();
  factory _MemberHealth.fromJson(Map<String, dynamic> json) => _$MemberHealthFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
 final  Map<String, Medication> _medications;
@override@JsonKey() Map<String, Medication> get medications {
  if (_medications is EqualUnmodifiableMapView) return _medications;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_medications);
}


/// Create a copy of MemberHealth
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberHealthCopyWith<_MemberHealth> get copyWith => __$MemberHealthCopyWithImpl<_MemberHealth>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberHealthToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemberHealth&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.medications, _medications));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_medications));
}

@override
String toString() {
    return 'MemberHealth(id: $id, medications: $medications)';
}


}

/// @nodoc
abstract mixin class _$MemberHealthCopyWith<$Res> implements $MemberHealthCopyWith<$Res> {
  factory _$MemberHealthCopyWith(_MemberHealth value, $Res Function(_MemberHealth) _then) = __$MemberHealthCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, Map<String, Medication> medications
});




}
/// @nodoc
class __$MemberHealthCopyWithImpl<$Res>
    implements _$MemberHealthCopyWith<$Res> {
  __$MemberHealthCopyWithImpl(this._self, this._then);

  final _MemberHealth _self;
  final $Res Function(_MemberHealth) _then;

/// Create a copy of MemberHealth
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? medications = null,}) {
  return _then(_MemberHealth(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,medications: null == medications ? _self._medications : medications // ignore: cast_nullable_to_non_nullable
as Map<String, Medication>,
  ));
}


}

// dart format on

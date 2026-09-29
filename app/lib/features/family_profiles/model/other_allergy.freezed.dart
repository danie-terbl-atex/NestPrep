// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'other_allergy.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OtherAllergy {

 String get name;@AllergySeverityConverter() AllergySeverity get severity; String? get note;
/// Create a copy of OtherAllergy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OtherAllergyCopyWith<OtherAllergy> get copyWith => _$OtherAllergyCopyWithImpl<OtherAllergy>(this as OtherAllergy, _$identity);

  /// Serializes this OtherAllergy to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OtherAllergy;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OtherAllergy&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.severity, _this.severity) || other.severity == _this.severity)&&(identical(other.note, _this.note) || other.note == _this.note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OtherAllergy;
  return Object.hash(runtimeType,_this.name,_this.severity,_this.note);
}

@override
String toString() {
  final _this = this as OtherAllergy;
  return 'OtherAllergy(name: ${_this.name}, severity: ${_this.severity}, note: ${_this.note})';
}


}

/// @nodoc
abstract mixin class $OtherAllergyCopyWith<$Res>  {
  factory $OtherAllergyCopyWith(OtherAllergy value, $Res Function(OtherAllergy) _then) = _$OtherAllergyCopyWithImpl;
@useResult
$Res call({
 String name,@AllergySeverityConverter() AllergySeverity severity, String? note
});




}
/// @nodoc
class _$OtherAllergyCopyWithImpl<$Res>
    implements $OtherAllergyCopyWith<$Res> {
  _$OtherAllergyCopyWithImpl(this._self, this._then);

  final OtherAllergy _self;
  final $Res Function(OtherAllergy) _then;

/// Create a copy of OtherAllergy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? severity = null,Object? note = freezed,}) {
  return _then(OtherAllergy(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as AllergySeverity,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [OtherAllergy].
extension OtherAllergyPatterns on OtherAllergy {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OtherAllergy value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OtherAllergy() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OtherAllergy value)  $default,){
final _that = this;
switch (_that) {
case _OtherAllergy():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OtherAllergy value)?  $default,){
final _that = this;
switch (_that) {
case _OtherAllergy() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name, @AllergySeverityConverter()  AllergySeverity severity,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OtherAllergy() when $default != null:
return $default(_that.name,_that.severity,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name, @AllergySeverityConverter()  AllergySeverity severity,  String? note)  $default,) {final _that = this;
switch (_that) {
case _OtherAllergy():
return $default(_that.name,_that.severity,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name, @AllergySeverityConverter()  AllergySeverity severity,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _OtherAllergy() when $default != null:
return $default(_that.name,_that.severity,_that.note);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OtherAllergy implements OtherAllergy {
  const _OtherAllergy({required this.name, @AllergySeverityConverter() required this.severity, this.note});
  factory _OtherAllergy.fromJson(Map<String, dynamic> json) => _$OtherAllergyFromJson(json);

@override final  String name;
@override@AllergySeverityConverter() final  AllergySeverity severity;
@override final  String? note;

/// Create a copy of OtherAllergy
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OtherAllergyCopyWith<_OtherAllergy> get copyWith => __$OtherAllergyCopyWithImpl<_OtherAllergy>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OtherAllergyToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OtherAllergy&&(identical(other.name, name) || other.name == name)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,severity,note);
}

@override
String toString() {
    return 'OtherAllergy(name: $name, severity: $severity, note: $note)';
}


}

/// @nodoc
abstract mixin class _$OtherAllergyCopyWith<$Res> implements $OtherAllergyCopyWith<$Res> {
  factory _$OtherAllergyCopyWith(_OtherAllergy value, $Res Function(_OtherAllergy) _then) = __$OtherAllergyCopyWithImpl;
@override @useResult
$Res call({
 String name,@AllergySeverityConverter() AllergySeverity severity, String? note
});




}
/// @nodoc
class __$OtherAllergyCopyWithImpl<$Res>
    implements _$OtherAllergyCopyWith<$Res> {
  __$OtherAllergyCopyWithImpl(this._self, this._then);

  final _OtherAllergy _self;
  final $Res Function(_OtherAllergy) _then;

/// Create a copy of OtherAllergy
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? severity = null,Object? note = freezed,}) {
  return _then(_OtherAllergy(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as AllergySeverity,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'allergy_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AllergyDetail {

@AllergySeverityConverter() AllergySeverity get severity; String? get note;
/// Create a copy of AllergyDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AllergyDetailCopyWith<AllergyDetail> get copyWith => _$AllergyDetailCopyWithImpl<AllergyDetail>(this as AllergyDetail, _$identity);

  /// Serializes this AllergyDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AllergyDetail;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AllergyDetail&&(identical(other.severity, _this.severity) || other.severity == _this.severity)&&(identical(other.note, _this.note) || other.note == _this.note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AllergyDetail;
  return Object.hash(runtimeType,_this.severity,_this.note);
}

@override
String toString() {
  final _this = this as AllergyDetail;
  return 'AllergyDetail(severity: ${_this.severity}, note: ${_this.note})';
}


}

/// @nodoc
abstract mixin class $AllergyDetailCopyWith<$Res>  {
  factory $AllergyDetailCopyWith(AllergyDetail value, $Res Function(AllergyDetail) _then) = _$AllergyDetailCopyWithImpl;
@useResult
$Res call({
@AllergySeverityConverter() AllergySeverity severity, String? note
});




}
/// @nodoc
class _$AllergyDetailCopyWithImpl<$Res>
    implements $AllergyDetailCopyWith<$Res> {
  _$AllergyDetailCopyWithImpl(this._self, this._then);

  final AllergyDetail _self;
  final $Res Function(AllergyDetail) _then;

/// Create a copy of AllergyDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? severity = null,Object? note = freezed,}) {
  return _then(AllergyDetail(
severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as AllergySeverity,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AllergyDetail].
extension AllergyDetailPatterns on AllergyDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AllergyDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AllergyDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AllergyDetail value)  $default,){
final _that = this;
switch (_that) {
case _AllergyDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AllergyDetail value)?  $default,){
final _that = this;
switch (_that) {
case _AllergyDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@AllergySeverityConverter()  AllergySeverity severity,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AllergyDetail() when $default != null:
return $default(_that.severity,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@AllergySeverityConverter()  AllergySeverity severity,  String? note)  $default,) {final _that = this;
switch (_that) {
case _AllergyDetail():
return $default(_that.severity,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@AllergySeverityConverter()  AllergySeverity severity,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _AllergyDetail() when $default != null:
return $default(_that.severity,_that.note);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AllergyDetail implements AllergyDetail {
  const _AllergyDetail({@AllergySeverityConverter() required this.severity, this.note});
  factory _AllergyDetail.fromJson(Map<String, dynamic> json) => _$AllergyDetailFromJson(json);

@override@AllergySeverityConverter() final  AllergySeverity severity;
@override final  String? note;

/// Create a copy of AllergyDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AllergyDetailCopyWith<_AllergyDetail> get copyWith => __$AllergyDetailCopyWithImpl<_AllergyDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AllergyDetailToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AllergyDetail&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,severity,note);
}

@override
String toString() {
    return 'AllergyDetail(severity: $severity, note: $note)';
}


}

/// @nodoc
abstract mixin class _$AllergyDetailCopyWith<$Res> implements $AllergyDetailCopyWith<$Res> {
  factory _$AllergyDetailCopyWith(_AllergyDetail value, $Res Function(_AllergyDetail) _then) = __$AllergyDetailCopyWithImpl;
@override @useResult
$Res call({
@AllergySeverityConverter() AllergySeverity severity, String? note
});




}
/// @nodoc
class __$AllergyDetailCopyWithImpl<$Res>
    implements _$AllergyDetailCopyWith<$Res> {
  __$AllergyDetailCopyWithImpl(this._self, this._then);

  final _AllergyDetail _self;
  final $Res Function(_AllergyDetail) _then;

/// Create a copy of AllergyDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? severity = null,Object? note = freezed,}) {
  return _then(_AllergyDetail(
severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as AllergySeverity,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

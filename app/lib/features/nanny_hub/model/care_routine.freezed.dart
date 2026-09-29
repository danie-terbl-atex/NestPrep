// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'care_routine.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CareRoutine {

 String get label; int? get minuteOfDay; String? get note;
/// Create a copy of CareRoutine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CareRoutineCopyWith<CareRoutine> get copyWith => _$CareRoutineCopyWithImpl<CareRoutine>(this as CareRoutine, _$identity);

  /// Serializes this CareRoutine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CareRoutine;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CareRoutine&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.minuteOfDay, _this.minuteOfDay) || other.minuteOfDay == _this.minuteOfDay)&&(identical(other.note, _this.note) || other.note == _this.note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CareRoutine;
  return Object.hash(runtimeType,_this.label,_this.minuteOfDay,_this.note);
}

@override
String toString() {
  final _this = this as CareRoutine;
  return 'CareRoutine(label: ${_this.label}, minuteOfDay: ${_this.minuteOfDay}, note: ${_this.note})';
}


}

/// @nodoc
abstract mixin class $CareRoutineCopyWith<$Res>  {
  factory $CareRoutineCopyWith(CareRoutine value, $Res Function(CareRoutine) _then) = _$CareRoutineCopyWithImpl;
@useResult
$Res call({
 String label, int? minuteOfDay, String? note
});




}
/// @nodoc
class _$CareRoutineCopyWithImpl<$Res>
    implements $CareRoutineCopyWith<$Res> {
  _$CareRoutineCopyWithImpl(this._self, this._then);

  final CareRoutine _self;
  final $Res Function(CareRoutine) _then;

/// Create a copy of CareRoutine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? minuteOfDay = freezed,Object? note = freezed,}) {
  return _then(CareRoutine(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,minuteOfDay: freezed == minuteOfDay ? _self.minuteOfDay : minuteOfDay // ignore: cast_nullable_to_non_nullable
as int?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CareRoutine].
extension CareRoutinePatterns on CareRoutine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CareRoutine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CareRoutine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CareRoutine value)  $default,){
final _that = this;
switch (_that) {
case _CareRoutine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CareRoutine value)?  $default,){
final _that = this;
switch (_that) {
case _CareRoutine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  int? minuteOfDay,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CareRoutine() when $default != null:
return $default(_that.label,_that.minuteOfDay,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  int? minuteOfDay,  String? note)  $default,) {final _that = this;
switch (_that) {
case _CareRoutine():
return $default(_that.label,_that.minuteOfDay,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  int? minuteOfDay,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _CareRoutine() when $default != null:
return $default(_that.label,_that.minuteOfDay,_that.note);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CareRoutine extends CareRoutine {
  const _CareRoutine({required this.label, this.minuteOfDay, this.note}): super._();
  factory _CareRoutine.fromJson(Map<String, dynamic> json) => _$CareRoutineFromJson(json);

@override final  String label;
@override final  int? minuteOfDay;
@override final  String? note;

/// Create a copy of CareRoutine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CareRoutineCopyWith<_CareRoutine> get copyWith => __$CareRoutineCopyWithImpl<_CareRoutine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CareRoutineToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CareRoutine&&(identical(other.label, label) || other.label == label)&&(identical(other.minuteOfDay, minuteOfDay) || other.minuteOfDay == minuteOfDay)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,label,minuteOfDay,note);
}

@override
String toString() {
    return 'CareRoutine(label: $label, minuteOfDay: $minuteOfDay, note: $note)';
}


}

/// @nodoc
abstract mixin class _$CareRoutineCopyWith<$Res> implements $CareRoutineCopyWith<$Res> {
  factory _$CareRoutineCopyWith(_CareRoutine value, $Res Function(_CareRoutine) _then) = __$CareRoutineCopyWithImpl;
@override @useResult
$Res call({
 String label, int? minuteOfDay, String? note
});




}
/// @nodoc
class __$CareRoutineCopyWithImpl<$Res>
    implements _$CareRoutineCopyWith<$Res> {
  __$CareRoutineCopyWithImpl(this._self, this._then);

  final _CareRoutine _self;
  final $Res Function(_CareRoutine) _then;

/// Create a copy of CareRoutine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? minuteOfDay = freezed,Object? note = freezed,}) {
  return _then(_CareRoutine(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,minuteOfDay: freezed == minuteOfDay ? _self.minuteOfDay : minuteOfDay // ignore: cast_nullable_to_non_nullable
as int?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

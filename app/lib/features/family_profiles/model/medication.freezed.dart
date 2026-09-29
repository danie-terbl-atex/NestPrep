// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'medication.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Medication {

 String get name;/// Free text, because "5 ml", "one puff" and "half a tablet" are all what
/// a parent writes.
 String? get dose; List<int> get times; String? get note;
/// Create a copy of Medication
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MedicationCopyWith<Medication> get copyWith => _$MedicationCopyWithImpl<Medication>(this as Medication, _$identity);

  /// Serializes this Medication to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Medication;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Medication&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.dose, _this.dose) || other.dose == _this.dose)&&const DeepCollectionEquality().equals(other.times, _this.times)&&(identical(other.note, _this.note) || other.note == _this.note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Medication;
  return Object.hash(runtimeType,_this.name,_this.dose,const DeepCollectionEquality().hash(_this.times),_this.note);
}

@override
String toString() {
  final _this = this as Medication;
  return 'Medication(name: ${_this.name}, dose: ${_this.dose}, times: ${_this.times}, note: ${_this.note})';
}


}

/// @nodoc
abstract mixin class $MedicationCopyWith<$Res>  {
  factory $MedicationCopyWith(Medication value, $Res Function(Medication) _then) = _$MedicationCopyWithImpl;
@useResult
$Res call({
 String name, String? dose, List<int> times, String? note
});




}
/// @nodoc
class _$MedicationCopyWithImpl<$Res>
    implements $MedicationCopyWith<$Res> {
  _$MedicationCopyWithImpl(this._self, this._then);

  final Medication _self;
  final $Res Function(Medication) _then;

/// Create a copy of Medication
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? dose = freezed,Object? times = null,Object? note = freezed,}) {
  return _then(Medication(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,dose: freezed == dose ? _self.dose : dose // ignore: cast_nullable_to_non_nullable
as String?,times: null == times ? _self.times : times // ignore: cast_nullable_to_non_nullable
as List<int>,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Medication].
extension MedicationPatterns on Medication {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Medication value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Medication() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Medication value)  $default,){
final _that = this;
switch (_that) {
case _Medication():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Medication value)?  $default,){
final _that = this;
switch (_that) {
case _Medication() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String? dose,  List<int> times,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Medication() when $default != null:
return $default(_that.name,_that.dose,_that.times,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String? dose,  List<int> times,  String? note)  $default,) {final _that = this;
switch (_that) {
case _Medication():
return $default(_that.name,_that.dose,_that.times,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String? dose,  List<int> times,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _Medication() when $default != null:
return $default(_that.name,_that.dose,_that.times,_that.note);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Medication extends Medication {
  const _Medication({required this.name, this.dose,  List<int> times = const <int>[], this.note}): _times = times,super._();
  factory _Medication.fromJson(Map<String, dynamic> json) => _$MedicationFromJson(json);

@override final  String name;
/// Free text, because "5 ml", "one puff" and "half a tablet" are all what
/// a parent writes.
@override final  String? dose;
 final  List<int> _times;
@override@JsonKey() List<int> get times {
  if (_times is EqualUnmodifiableListView) return _times;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_times);
}

@override final  String? note;

/// Create a copy of Medication
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MedicationCopyWith<_Medication> get copyWith => __$MedicationCopyWithImpl<_Medication>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MedicationToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Medication&&(identical(other.name, name) || other.name == name)&&(identical(other.dose, dose) || other.dose == dose)&&const DeepCollectionEquality().equals(other.times, _times)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,dose,const DeepCollectionEquality().hash(_times),note);
}

@override
String toString() {
    return 'Medication(name: $name, dose: $dose, times: $times, note: $note)';
}


}

/// @nodoc
abstract mixin class _$MedicationCopyWith<$Res> implements $MedicationCopyWith<$Res> {
  factory _$MedicationCopyWith(_Medication value, $Res Function(_Medication) _then) = __$MedicationCopyWithImpl;
@override @useResult
$Res call({
 String name, String? dose, List<int> times, String? note
});




}
/// @nodoc
class __$MedicationCopyWithImpl<$Res>
    implements _$MedicationCopyWith<$Res> {
  __$MedicationCopyWithImpl(this._self, this._then);

  final _Medication _self;
  final $Res Function(_Medication) _then;

/// Create a copy of Medication
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? dose = freezed,Object? times = null,Object? note = freezed,}) {
  return _then(_Medication(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,dose: freezed == dose ? _self.dose : dose // ignore: cast_nullable_to_non_nullable
as String?,times: null == times ? _self._times : times // ignore: cast_nullable_to_non_nullable
as List<int>,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

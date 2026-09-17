// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'week_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WeekPlan {

/// The Monday this week starts on, `YYYY-MM-DD` — also the document id.
@JsonKey(includeToJson: false) String get id; Map<String, String> get slots;
/// Create a copy of WeekPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeekPlanCopyWith<WeekPlan> get copyWith => _$WeekPlanCopyWithImpl<WeekPlan>(this as WeekPlan, _$identity);

  /// Serializes this WeekPlan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as WeekPlan;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeekPlan&&(identical(other.id, _this.id) || other.id == _this.id)&&const DeepCollectionEquality().equals(other.slots, _this.slots));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WeekPlan;
  return Object.hash(runtimeType,_this.id,const DeepCollectionEquality().hash(_this.slots));
}

@override
String toString() {
  final _this = this as WeekPlan;
  return 'WeekPlan(id: ${_this.id}, slots: ${_this.slots})';
}


}

/// @nodoc
abstract mixin class $WeekPlanCopyWith<$Res>  {
  factory $WeekPlanCopyWith(WeekPlan value, $Res Function(WeekPlan) _then) = _$WeekPlanCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, Map<String, String> slots
});




}
/// @nodoc
class _$WeekPlanCopyWithImpl<$Res>
    implements $WeekPlanCopyWith<$Res> {
  _$WeekPlanCopyWithImpl(this._self, this._then);

  final WeekPlan _self;
  final $Res Function(WeekPlan) _then;

/// Create a copy of WeekPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slots = null,}) {
  return _then(WeekPlan(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slots: null == slots ? _self.slots : slots // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [WeekPlan].
extension WeekPlanPatterns on WeekPlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeekPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeekPlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeekPlan value)  $default,){
final _that = this;
switch (_that) {
case _WeekPlan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeekPlan value)?  $default,){
final _that = this;
switch (_that) {
case _WeekPlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  Map<String, String> slots)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeekPlan() when $default != null:
return $default(_that.id,_that.slots);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  Map<String, String> slots)  $default,) {final _that = this;
switch (_that) {
case _WeekPlan():
return $default(_that.id,_that.slots);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  Map<String, String> slots)?  $default,) {final _that = this;
switch (_that) {
case _WeekPlan() when $default != null:
return $default(_that.id,_that.slots);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeekPlan extends WeekPlan {
  const _WeekPlan({@JsonKey(includeToJson: false) required this.id,  Map<String, String> slots = const <String, String>{}}): _slots = slots,super._();
  factory _WeekPlan.fromJson(Map<String, dynamic> json) => _$WeekPlanFromJson(json);

/// The Monday this week starts on, `YYYY-MM-DD` — also the document id.
@override@JsonKey(includeToJson: false) final  String id;
 final  Map<String, String> _slots;
@override@JsonKey() Map<String, String> get slots {
  if (_slots is EqualUnmodifiableMapView) return _slots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_slots);
}


/// Create a copy of WeekPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeekPlanCopyWith<_WeekPlan> get copyWith => __$WeekPlanCopyWithImpl<_WeekPlan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeekPlanToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeekPlan&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.slots, _slots));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_slots));
}

@override
String toString() {
    return 'WeekPlan(id: $id, slots: $slots)';
}


}

/// @nodoc
abstract mixin class _$WeekPlanCopyWith<$Res> implements $WeekPlanCopyWith<$Res> {
  factory _$WeekPlanCopyWith(_WeekPlan value, $Res Function(_WeekPlan) _then) = __$WeekPlanCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, Map<String, String> slots
});




}
/// @nodoc
class __$WeekPlanCopyWithImpl<$Res>
    implements _$WeekPlanCopyWith<$Res> {
  __$WeekPlanCopyWithImpl(this._self, this._then);

  final _WeekPlan _self;
  final $Res Function(_WeekPlan) _then;

/// Create a copy of WeekPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slots = null,}) {
  return _then(_WeekPlan(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slots: null == slots ? _self._slots : slots // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

// dart format on

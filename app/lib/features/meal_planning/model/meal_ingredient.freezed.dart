// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meal_ingredient.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MealIngredient {

 String get name;/// For the meal as the household cooks it; null when nobody said.
 double? get amount;/// The unit's code as stored. Read through [unit], which is null for no
/// unit and for a code this build does not know (`BE-10`).
@JsonKey(name: 'unit') String? get unitCode;
/// Create a copy of MealIngredient
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MealIngredientCopyWith<MealIngredient> get copyWith => _$MealIngredientCopyWithImpl<MealIngredient>(this as MealIngredient, _$identity);

  /// Serializes this MealIngredient to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MealIngredient;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MealIngredient&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.unitCode, _this.unitCode) || other.unitCode == _this.unitCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MealIngredient;
  return Object.hash(runtimeType,_this.name,_this.amount,_this.unitCode);
}

@override
String toString() {
  final _this = this as MealIngredient;
  return 'MealIngredient(name: ${_this.name}, amount: ${_this.amount}, unitCode: ${_this.unitCode})';
}


}

/// @nodoc
abstract mixin class $MealIngredientCopyWith<$Res>  {
  factory $MealIngredientCopyWith(MealIngredient value, $Res Function(MealIngredient) _then) = _$MealIngredientCopyWithImpl;
@useResult
$Res call({
 String name, double? amount,@JsonKey(name: 'unit') String? unitCode
});




}
/// @nodoc
class _$MealIngredientCopyWithImpl<$Res>
    implements $MealIngredientCopyWith<$Res> {
  _$MealIngredientCopyWithImpl(this._self, this._then);

  final MealIngredient _self;
  final $Res Function(MealIngredient) _then;

/// Create a copy of MealIngredient
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? amount = freezed,Object? unitCode = freezed,}) {
  return _then(MealIngredient(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double?,unitCode: freezed == unitCode ? _self.unitCode : unitCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MealIngredient].
extension MealIngredientPatterns on MealIngredient {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MealIngredient value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MealIngredient() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MealIngredient value)  $default,){
final _that = this;
switch (_that) {
case _MealIngredient():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MealIngredient value)?  $default,){
final _that = this;
switch (_that) {
case _MealIngredient() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  double? amount, @JsonKey(name: 'unit')  String? unitCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MealIngredient() when $default != null:
return $default(_that.name,_that.amount,_that.unitCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  double? amount, @JsonKey(name: 'unit')  String? unitCode)  $default,) {final _that = this;
switch (_that) {
case _MealIngredient():
return $default(_that.name,_that.amount,_that.unitCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  double? amount, @JsonKey(name: 'unit')  String? unitCode)?  $default,) {final _that = this;
switch (_that) {
case _MealIngredient() when $default != null:
return $default(_that.name,_that.amount,_that.unitCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MealIngredient extends MealIngredient {
  const _MealIngredient({required this.name, this.amount, @JsonKey(name: 'unit') this.unitCode}): super._();
  factory _MealIngredient.fromJson(Map<String, dynamic> json) => _$MealIngredientFromJson(json);

@override final  String name;
/// For the meal as the household cooks it; null when nobody said.
@override final  double? amount;
/// The unit's code as stored. Read through [unit], which is null for no
/// unit and for a code this build does not know (`BE-10`).
@override@JsonKey(name: 'unit') final  String? unitCode;

/// Create a copy of MealIngredient
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MealIngredientCopyWith<_MealIngredient> get copyWith => __$MealIngredientCopyWithImpl<_MealIngredient>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MealIngredientToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MealIngredient&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.unitCode, unitCode) || other.unitCode == unitCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,amount,unitCode);
}

@override
String toString() {
    return 'MealIngredient(name: $name, amount: $amount, unitCode: $unitCode)';
}


}

/// @nodoc
abstract mixin class _$MealIngredientCopyWith<$Res> implements $MealIngredientCopyWith<$Res> {
  factory _$MealIngredientCopyWith(_MealIngredient value, $Res Function(_MealIngredient) _then) = __$MealIngredientCopyWithImpl;
@override @useResult
$Res call({
 String name, double? amount,@JsonKey(name: 'unit') String? unitCode
});




}
/// @nodoc
class __$MealIngredientCopyWithImpl<$Res>
    implements _$MealIngredientCopyWith<$Res> {
  __$MealIngredientCopyWithImpl(this._self, this._then);

  final _MealIngredient _self;
  final $Res Function(_MealIngredient) _then;

/// Create a copy of MealIngredient
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? amount = freezed,Object? unitCode = freezed,}) {
  return _then(_MealIngredient(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double?,unitCode: freezed == unitCode ? _self.unitCode : unitCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

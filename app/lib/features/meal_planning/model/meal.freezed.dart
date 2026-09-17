// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meal.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Meal {

@JsonKey(includeToJson: false) String get id; String get name;/// [name] normalised, stored so the household can be asked "have we typed
/// this before" in one query. It is derived, never typed — `Meal.named`
/// is the only way to make one (`ENG-02`: the same normaliser groceries
/// ranks its chips with).
 String get nameKey; String get addedBy;@ServerTimestampConverter() DateTime? get createdAt;
/// Create a copy of Meal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MealCopyWith<Meal> get copyWith => _$MealCopyWithImpl<Meal>(this as Meal, _$identity);

  /// Serializes this Meal to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Meal;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Meal&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.nameKey, _this.nameKey) || other.nameKey == _this.nameKey)&&(identical(other.addedBy, _this.addedBy) || other.addedBy == _this.addedBy)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Meal;
  return Object.hash(runtimeType,_this.id,_this.name,_this.nameKey,_this.addedBy,_this.createdAt);
}

@override
String toString() {
  final _this = this as Meal;
  return 'Meal(id: ${_this.id}, name: ${_this.name}, nameKey: ${_this.nameKey}, addedBy: ${_this.addedBy}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $MealCopyWith<$Res>  {
  factory $MealCopyWith(Meal value, $Res Function(Meal) _then) = _$MealCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String name, String nameKey, String addedBy,@ServerTimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class _$MealCopyWithImpl<$Res>
    implements $MealCopyWith<$Res> {
  _$MealCopyWithImpl(this._self, this._then);

  final Meal _self;
  final $Res Function(Meal) _then;

/// Create a copy of Meal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? nameKey = null,Object? addedBy = null,Object? createdAt = freezed,}) {
  return _then(Meal(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameKey: null == nameKey ? _self.nameKey : nameKey // ignore: cast_nullable_to_non_nullable
as String,addedBy: null == addedBy ? _self.addedBy : addedBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Meal].
extension MealPatterns on Meal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Meal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Meal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Meal value)  $default,){
final _that = this;
switch (_that) {
case _Meal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Meal value)?  $default,){
final _that = this;
switch (_that) {
case _Meal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String name,  String nameKey,  String addedBy, @ServerTimestampConverter()  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Meal() when $default != null:
return $default(_that.id,_that.name,_that.nameKey,_that.addedBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String name,  String nameKey,  String addedBy, @ServerTimestampConverter()  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _Meal():
return $default(_that.id,_that.name,_that.nameKey,_that.addedBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String name,  String nameKey,  String addedBy, @ServerTimestampConverter()  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Meal() when $default != null:
return $default(_that.id,_that.name,_that.nameKey,_that.addedBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Meal extends Meal {
  const _Meal({@JsonKey(includeToJson: false) required this.id, required this.name, required this.nameKey, required this.addedBy, @ServerTimestampConverter() this.createdAt}): super._();
  factory _Meal.fromJson(Map<String, dynamic> json) => _$MealFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String name;
/// [name] normalised, stored so the household can be asked "have we typed
/// this before" in one query. It is derived, never typed — `Meal.named`
/// is the only way to make one (`ENG-02`: the same normaliser groceries
/// ranks its chips with).
@override final  String nameKey;
@override final  String addedBy;
@override@ServerTimestampConverter() final  DateTime? createdAt;

/// Create a copy of Meal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MealCopyWith<_Meal> get copyWith => __$MealCopyWithImpl<_Meal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MealToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Meal&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameKey, nameKey) || other.nameKey == nameKey)&&(identical(other.addedBy, addedBy) || other.addedBy == addedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,nameKey,addedBy,createdAt);
}

@override
String toString() {
    return 'Meal(id: $id, name: $name, nameKey: $nameKey, addedBy: $addedBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MealCopyWith<$Res> implements $MealCopyWith<$Res> {
  factory _$MealCopyWith(_Meal value, $Res Function(_Meal) _then) = __$MealCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String name, String nameKey, String addedBy,@ServerTimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class __$MealCopyWithImpl<$Res>
    implements _$MealCopyWith<$Res> {
  __$MealCopyWithImpl(this._self, this._then);

  final _Meal _self;
  final $Res Function(_Meal) _then;

/// Create a copy of Meal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? nameKey = null,Object? addedBy = null,Object? createdAt = freezed,}) {
  return _then(_Meal(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameKey: null == nameKey ? _self.nameKey : nameKey // ignore: cast_nullable_to_non_nullable
as String,addedBy: null == addedBy ? _self.addedBy : addedBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lunch_pick.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LunchPick {

 String get itemId; String get name; List<String> get allergens;
/// Create a copy of LunchPick
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LunchPickCopyWith<LunchPick> get copyWith => _$LunchPickCopyWithImpl<LunchPick>(this as LunchPick, _$identity);

  /// Serializes this LunchPick to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LunchPick;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LunchPick&&(identical(other.itemId, _this.itemId) || other.itemId == _this.itemId)&&(identical(other.name, _this.name) || other.name == _this.name)&&const DeepCollectionEquality().equals(other.allergens, _this.allergens));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LunchPick;
  return Object.hash(runtimeType,_this.itemId,_this.name,const DeepCollectionEquality().hash(_this.allergens));
}

@override
String toString() {
  final _this = this as LunchPick;
  return 'LunchPick(itemId: ${_this.itemId}, name: ${_this.name}, allergens: ${_this.allergens})';
}


}

/// @nodoc
abstract mixin class $LunchPickCopyWith<$Res>  {
  factory $LunchPickCopyWith(LunchPick value, $Res Function(LunchPick) _then) = _$LunchPickCopyWithImpl;
@useResult
$Res call({
 String itemId, String name, List<String> allergens
});




}
/// @nodoc
class _$LunchPickCopyWithImpl<$Res>
    implements $LunchPickCopyWith<$Res> {
  _$LunchPickCopyWithImpl(this._self, this._then);

  final LunchPick _self;
  final $Res Function(LunchPick) _then;

/// Create a copy of LunchPick
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itemId = null,Object? name = null,Object? allergens = null,}) {
  return _then(LunchPick(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,allergens: null == allergens ? _self.allergens : allergens // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [LunchPick].
extension LunchPickPatterns on LunchPick {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LunchPick value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LunchPick() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LunchPick value)  $default,){
final _that = this;
switch (_that) {
case _LunchPick():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LunchPick value)?  $default,){
final _that = this;
switch (_that) {
case _LunchPick() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String itemId,  String name,  List<String> allergens)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LunchPick() when $default != null:
return $default(_that.itemId,_that.name,_that.allergens);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String itemId,  String name,  List<String> allergens)  $default,) {final _that = this;
switch (_that) {
case _LunchPick():
return $default(_that.itemId,_that.name,_that.allergens);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String itemId,  String name,  List<String> allergens)?  $default,) {final _that = this;
switch (_that) {
case _LunchPick() when $default != null:
return $default(_that.itemId,_that.name,_that.allergens);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LunchPick extends LunchPick {
  const _LunchPick({required this.itemId, required this.name,  List<String> allergens = const <String>[]}): _allergens = allergens,super._();
  factory _LunchPick.fromJson(Map<String, dynamic> json) => _$LunchPickFromJson(json);

@override final  String itemId;
@override final  String name;
 final  List<String> _allergens;
@override@JsonKey() List<String> get allergens {
  if (_allergens is EqualUnmodifiableListView) return _allergens;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allergens);
}


/// Create a copy of LunchPick
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LunchPickCopyWith<_LunchPick> get copyWith => __$LunchPickCopyWithImpl<_LunchPick>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LunchPickToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LunchPick&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.allergens, _allergens));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,itemId,name,const DeepCollectionEquality().hash(_allergens));
}

@override
String toString() {
    return 'LunchPick(itemId: $itemId, name: $name, allergens: $allergens)';
}


}

/// @nodoc
abstract mixin class _$LunchPickCopyWith<$Res> implements $LunchPickCopyWith<$Res> {
  factory _$LunchPickCopyWith(_LunchPick value, $Res Function(_LunchPick) _then) = __$LunchPickCopyWithImpl;
@override @useResult
$Res call({
 String itemId, String name, List<String> allergens
});




}
/// @nodoc
class __$LunchPickCopyWithImpl<$Res>
    implements _$LunchPickCopyWith<$Res> {
  __$LunchPickCopyWithImpl(this._self, this._then);

  final _LunchPick _self;
  final $Res Function(_LunchPick) _then;

/// Create a copy of LunchPick
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itemId = null,Object? name = null,Object? allergens = null,}) {
  return _then(_LunchPick(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,allergens: null == allergens ? _self._allergens : allergens // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on

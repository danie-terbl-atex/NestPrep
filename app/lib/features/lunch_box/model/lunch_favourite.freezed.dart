// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lunch_favourite.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LunchFavourite {

@JsonKey(includeToJson: false) String get id; String get childId; String get name;/// Slot name → what goes in it.
 Map<String, LunchPick> get picks; String get createdBy;@ServerTimestampConverter() DateTime? get createdAt;
/// Create a copy of LunchFavourite
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LunchFavouriteCopyWith<LunchFavourite> get copyWith => _$LunchFavouriteCopyWithImpl<LunchFavourite>(this as LunchFavourite, _$identity);

  /// Serializes this LunchFavourite to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LunchFavourite;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LunchFavourite&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.childId, _this.childId) || other.childId == _this.childId)&&(identical(other.name, _this.name) || other.name == _this.name)&&const DeepCollectionEquality().equals(other.picks, _this.picks)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LunchFavourite;
  return Object.hash(runtimeType,_this.id,_this.childId,_this.name,const DeepCollectionEquality().hash(_this.picks),_this.createdBy,_this.createdAt);
}

@override
String toString() {
  final _this = this as LunchFavourite;
  return 'LunchFavourite(id: ${_this.id}, childId: ${_this.childId}, name: ${_this.name}, picks: ${_this.picks}, createdBy: ${_this.createdBy}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $LunchFavouriteCopyWith<$Res>  {
  factory $LunchFavouriteCopyWith(LunchFavourite value, $Res Function(LunchFavourite) _then) = _$LunchFavouriteCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String childId, String name, Map<String, LunchPick> picks, String createdBy,@ServerTimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class _$LunchFavouriteCopyWithImpl<$Res>
    implements $LunchFavouriteCopyWith<$Res> {
  _$LunchFavouriteCopyWithImpl(this._self, this._then);

  final LunchFavourite _self;
  final $Res Function(LunchFavourite) _then;

/// Create a copy of LunchFavourite
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? childId = null,Object? name = null,Object? picks = null,Object? createdBy = null,Object? createdAt = freezed,}) {
  return _then(LunchFavourite(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,childId: null == childId ? _self.childId : childId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,picks: null == picks ? _self.picks : picks // ignore: cast_nullable_to_non_nullable
as Map<String, LunchPick>,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [LunchFavourite].
extension LunchFavouritePatterns on LunchFavourite {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LunchFavourite value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LunchFavourite() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LunchFavourite value)  $default,){
final _that = this;
switch (_that) {
case _LunchFavourite():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LunchFavourite value)?  $default,){
final _that = this;
switch (_that) {
case _LunchFavourite() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String childId,  String name,  Map<String, LunchPick> picks,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LunchFavourite() when $default != null:
return $default(_that.id,_that.childId,_that.name,_that.picks,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String childId,  String name,  Map<String, LunchPick> picks,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _LunchFavourite():
return $default(_that.id,_that.childId,_that.name,_that.picks,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String childId,  String name,  Map<String, LunchPick> picks,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _LunchFavourite() when $default != null:
return $default(_that.id,_that.childId,_that.name,_that.picks,_that.createdBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LunchFavourite extends LunchFavourite {
  const _LunchFavourite({@JsonKey(includeToJson: false) required this.id, required this.childId, required this.name,  Map<String, LunchPick> picks = const <String, LunchPick>{}, required this.createdBy, @ServerTimestampConverter() this.createdAt}): _picks = picks,super._();
  factory _LunchFavourite.fromJson(Map<String, dynamic> json) => _$LunchFavouriteFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String childId;
@override final  String name;
/// Slot name → what goes in it.
 final  Map<String, LunchPick> _picks;
/// Slot name → what goes in it.
@override@JsonKey() Map<String, LunchPick> get picks {
  if (_picks is EqualUnmodifiableMapView) return _picks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_picks);
}

@override final  String createdBy;
@override@ServerTimestampConverter() final  DateTime? createdAt;

/// Create a copy of LunchFavourite
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LunchFavouriteCopyWith<_LunchFavourite> get copyWith => __$LunchFavouriteCopyWithImpl<_LunchFavourite>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LunchFavouriteToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LunchFavourite&&(identical(other.id, id) || other.id == id)&&(identical(other.childId, childId) || other.childId == childId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.picks, _picks)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,childId,name,const DeepCollectionEquality().hash(_picks),createdBy,createdAt);
}

@override
String toString() {
    return 'LunchFavourite(id: $id, childId: $childId, name: $name, picks: $picks, createdBy: $createdBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$LunchFavouriteCopyWith<$Res> implements $LunchFavouriteCopyWith<$Res> {
  factory _$LunchFavouriteCopyWith(_LunchFavourite value, $Res Function(_LunchFavourite) _then) = __$LunchFavouriteCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String childId, String name, Map<String, LunchPick> picks, String createdBy,@ServerTimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class __$LunchFavouriteCopyWithImpl<$Res>
    implements _$LunchFavouriteCopyWith<$Res> {
  __$LunchFavouriteCopyWithImpl(this._self, this._then);

  final _LunchFavourite _self;
  final $Res Function(_LunchFavourite) _then;

/// Create a copy of LunchFavourite
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? childId = null,Object? name = null,Object? picks = null,Object? createdBy = null,Object? createdAt = freezed,}) {
  return _then(_LunchFavourite(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,childId: null == childId ? _self.childId : childId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,picks: null == picks ? _self._picks : picks // ignore: cast_nullable_to_non_nullable
as Map<String, LunchPick>,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

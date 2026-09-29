// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'child_card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChildCard {

@JsonKey(includeToJson: false) String get id; List<CareRoutine> get routines; List<String> get comfortItems;/// How to settle them when they are upset or will not sleep.
 String? get settling;/// Anything else a carer should know: a fear of the dark, a word they use.
 String? get goodToKnow;/// A photo of the child, by its Storage object name.
 String? get photoId; String? get updatedBy;@ServerTimestampConverter() DateTime? get updatedAt;
/// Create a copy of ChildCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChildCardCopyWith<ChildCard> get copyWith => _$ChildCardCopyWithImpl<ChildCard>(this as ChildCard, _$identity);

  /// Serializes this ChildCard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChildCard;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChildCard&&(identical(other.id, _this.id) || other.id == _this.id)&&const DeepCollectionEquality().equals(other.routines, _this.routines)&&const DeepCollectionEquality().equals(other.comfortItems, _this.comfortItems)&&(identical(other.settling, _this.settling) || other.settling == _this.settling)&&(identical(other.goodToKnow, _this.goodToKnow) || other.goodToKnow == _this.goodToKnow)&&(identical(other.photoId, _this.photoId) || other.photoId == _this.photoId)&&(identical(other.updatedBy, _this.updatedBy) || other.updatedBy == _this.updatedBy)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChildCard;
  return Object.hash(runtimeType,_this.id,const DeepCollectionEquality().hash(_this.routines),const DeepCollectionEquality().hash(_this.comfortItems),_this.settling,_this.goodToKnow,_this.photoId,_this.updatedBy,_this.updatedAt);
}

@override
String toString() {
  final _this = this as ChildCard;
  return 'ChildCard(id: ${_this.id}, routines: ${_this.routines}, comfortItems: ${_this.comfortItems}, settling: ${_this.settling}, goodToKnow: ${_this.goodToKnow}, photoId: ${_this.photoId}, updatedBy: ${_this.updatedBy}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $ChildCardCopyWith<$Res>  {
  factory $ChildCardCopyWith(ChildCard value, $Res Function(ChildCard) _then) = _$ChildCardCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, List<CareRoutine> routines, List<String> comfortItems, String? settling, String? goodToKnow, String? photoId, String? updatedBy,@ServerTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$ChildCardCopyWithImpl<$Res>
    implements $ChildCardCopyWith<$Res> {
  _$ChildCardCopyWithImpl(this._self, this._then);

  final ChildCard _self;
  final $Res Function(ChildCard) _then;

/// Create a copy of ChildCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? routines = null,Object? comfortItems = null,Object? settling = freezed,Object? goodToKnow = freezed,Object? photoId = freezed,Object? updatedBy = freezed,Object? updatedAt = freezed,}) {
  return _then(ChildCard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,routines: null == routines ? _self.routines : routines // ignore: cast_nullable_to_non_nullable
as List<CareRoutine>,comfortItems: null == comfortItems ? _self.comfortItems : comfortItems // ignore: cast_nullable_to_non_nullable
as List<String>,settling: freezed == settling ? _self.settling : settling // ignore: cast_nullable_to_non_nullable
as String?,goodToKnow: freezed == goodToKnow ? _self.goodToKnow : goodToKnow // ignore: cast_nullable_to_non_nullable
as String?,photoId: freezed == photoId ? _self.photoId : photoId // ignore: cast_nullable_to_non_nullable
as String?,updatedBy: freezed == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChildCard].
extension ChildCardPatterns on ChildCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChildCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChildCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChildCard value)  $default,){
final _that = this;
switch (_that) {
case _ChildCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChildCard value)?  $default,){
final _that = this;
switch (_that) {
case _ChildCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  List<CareRoutine> routines,  List<String> comfortItems,  String? settling,  String? goodToKnow,  String? photoId,  String? updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChildCard() when $default != null:
return $default(_that.id,_that.routines,_that.comfortItems,_that.settling,_that.goodToKnow,_that.photoId,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  List<CareRoutine> routines,  List<String> comfortItems,  String? settling,  String? goodToKnow,  String? photoId,  String? updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ChildCard():
return $default(_that.id,_that.routines,_that.comfortItems,_that.settling,_that.goodToKnow,_that.photoId,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  List<CareRoutine> routines,  List<String> comfortItems,  String? settling,  String? goodToKnow,  String? photoId,  String? updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ChildCard() when $default != null:
return $default(_that.id,_that.routines,_that.comfortItems,_that.settling,_that.goodToKnow,_that.photoId,_that.updatedBy,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChildCard extends ChildCard {
  const _ChildCard({@JsonKey(includeToJson: false) required this.id,  List<CareRoutine> routines = const <CareRoutine>[],  List<String> comfortItems = const <String>[], this.settling, this.goodToKnow, this.photoId, this.updatedBy, @ServerTimestampConverter() this.updatedAt}): _routines = routines,_comfortItems = comfortItems,super._();
  factory _ChildCard.fromJson(Map<String, dynamic> json) => _$ChildCardFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
 final  List<CareRoutine> _routines;
@override@JsonKey() List<CareRoutine> get routines {
  if (_routines is EqualUnmodifiableListView) return _routines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_routines);
}

 final  List<String> _comfortItems;
@override@JsonKey() List<String> get comfortItems {
  if (_comfortItems is EqualUnmodifiableListView) return _comfortItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_comfortItems);
}

/// How to settle them when they are upset or will not sleep.
@override final  String? settling;
/// Anything else a carer should know: a fear of the dark, a word they use.
@override final  String? goodToKnow;
/// A photo of the child, by its Storage object name.
@override final  String? photoId;
@override final  String? updatedBy;
@override@ServerTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of ChildCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChildCardCopyWith<_ChildCard> get copyWith => __$ChildCardCopyWithImpl<_ChildCard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChildCardToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChildCard&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.routines, _routines)&&const DeepCollectionEquality().equals(other.comfortItems, _comfortItems)&&(identical(other.settling, settling) || other.settling == settling)&&(identical(other.goodToKnow, goodToKnow) || other.goodToKnow == goodToKnow)&&(identical(other.photoId, photoId) || other.photoId == photoId)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_routines),const DeepCollectionEquality().hash(_comfortItems),settling,goodToKnow,photoId,updatedBy,updatedAt);
}

@override
String toString() {
    return 'ChildCard(id: $id, routines: $routines, comfortItems: $comfortItems, settling: $settling, goodToKnow: $goodToKnow, photoId: $photoId, updatedBy: $updatedBy, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ChildCardCopyWith<$Res> implements $ChildCardCopyWith<$Res> {
  factory _$ChildCardCopyWith(_ChildCard value, $Res Function(_ChildCard) _then) = __$ChildCardCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, List<CareRoutine> routines, List<String> comfortItems, String? settling, String? goodToKnow, String? photoId, String? updatedBy,@ServerTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$ChildCardCopyWithImpl<$Res>
    implements _$ChildCardCopyWith<$Res> {
  __$ChildCardCopyWithImpl(this._self, this._then);

  final _ChildCard _self;
  final $Res Function(_ChildCard) _then;

/// Create a copy of ChildCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? routines = null,Object? comfortItems = null,Object? settling = freezed,Object? goodToKnow = freezed,Object? photoId = freezed,Object? updatedBy = freezed,Object? updatedAt = freezed,}) {
  return _then(_ChildCard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,routines: null == routines ? _self._routines : routines // ignore: cast_nullable_to_non_nullable
as List<CareRoutine>,comfortItems: null == comfortItems ? _self._comfortItems : comfortItems // ignore: cast_nullable_to_non_nullable
as List<String>,settling: freezed == settling ? _self.settling : settling // ignore: cast_nullable_to_non_nullable
as String?,goodToKnow: freezed == goodToKnow ? _self.goodToKnow : goodToKnow // ignore: cast_nullable_to_non_nullable
as String?,photoId: freezed == photoId ? _self.photoId : photoId // ignore: cast_nullable_to_non_nullable
as String?,updatedBy: freezed == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

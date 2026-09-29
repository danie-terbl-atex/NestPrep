// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lunch_pantry_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LunchPantryEntry {

/// The lunch item's id — also the document id.
@JsonKey(includeToJson: false) String get id; int get portions; String get updatedBy;@ServerTimestampConverter() DateTime? get updatedAt;
/// Create a copy of LunchPantryEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LunchPantryEntryCopyWith<LunchPantryEntry> get copyWith => _$LunchPantryEntryCopyWithImpl<LunchPantryEntry>(this as LunchPantryEntry, _$identity);

  /// Serializes this LunchPantryEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LunchPantryEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LunchPantryEntry&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.portions, _this.portions) || other.portions == _this.portions)&&(identical(other.updatedBy, _this.updatedBy) || other.updatedBy == _this.updatedBy)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LunchPantryEntry;
  return Object.hash(runtimeType,_this.id,_this.portions,_this.updatedBy,_this.updatedAt);
}

@override
String toString() {
  final _this = this as LunchPantryEntry;
  return 'LunchPantryEntry(id: ${_this.id}, portions: ${_this.portions}, updatedBy: ${_this.updatedBy}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $LunchPantryEntryCopyWith<$Res>  {
  factory $LunchPantryEntryCopyWith(LunchPantryEntry value, $Res Function(LunchPantryEntry) _then) = _$LunchPantryEntryCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, int portions, String updatedBy,@ServerTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$LunchPantryEntryCopyWithImpl<$Res>
    implements $LunchPantryEntryCopyWith<$Res> {
  _$LunchPantryEntryCopyWithImpl(this._self, this._then);

  final LunchPantryEntry _self;
  final $Res Function(LunchPantryEntry) _then;

/// Create a copy of LunchPantryEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? portions = null,Object? updatedBy = null,Object? updatedAt = freezed,}) {
  return _then(LunchPantryEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,portions: null == portions ? _self.portions : portions // ignore: cast_nullable_to_non_nullable
as int,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [LunchPantryEntry].
extension LunchPantryEntryPatterns on LunchPantryEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LunchPantryEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LunchPantryEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LunchPantryEntry value)  $default,){
final _that = this;
switch (_that) {
case _LunchPantryEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LunchPantryEntry value)?  $default,){
final _that = this;
switch (_that) {
case _LunchPantryEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  int portions,  String updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LunchPantryEntry() when $default != null:
return $default(_that.id,_that.portions,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  int portions,  String updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _LunchPantryEntry():
return $default(_that.id,_that.portions,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  int portions,  String updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _LunchPantryEntry() when $default != null:
return $default(_that.id,_that.portions,_that.updatedBy,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LunchPantryEntry extends LunchPantryEntry {
  const _LunchPantryEntry({@JsonKey(includeToJson: false) required this.id, this.portions = 0, required this.updatedBy, @ServerTimestampConverter() this.updatedAt}): super._();
  factory _LunchPantryEntry.fromJson(Map<String, dynamic> json) => _$LunchPantryEntryFromJson(json);

/// The lunch item's id — also the document id.
@override@JsonKey(includeToJson: false) final  String id;
@override@JsonKey() final  int portions;
@override final  String updatedBy;
@override@ServerTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of LunchPantryEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LunchPantryEntryCopyWith<_LunchPantryEntry> get copyWith => __$LunchPantryEntryCopyWithImpl<_LunchPantryEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LunchPantryEntryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LunchPantryEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.portions, portions) || other.portions == portions)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,portions,updatedBy,updatedAt);
}

@override
String toString() {
    return 'LunchPantryEntry(id: $id, portions: $portions, updatedBy: $updatedBy, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$LunchPantryEntryCopyWith<$Res> implements $LunchPantryEntryCopyWith<$Res> {
  factory _$LunchPantryEntryCopyWith(_LunchPantryEntry value, $Res Function(_LunchPantryEntry) _then) = __$LunchPantryEntryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, int portions, String updatedBy,@ServerTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$LunchPantryEntryCopyWithImpl<$Res>
    implements _$LunchPantryEntryCopyWith<$Res> {
  __$LunchPantryEntryCopyWithImpl(this._self, this._then);

  final _LunchPantryEntry _self;
  final $Res Function(_LunchPantryEntry) _then;

/// Create a copy of LunchPantryEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? portions = null,Object? updatedBy = null,Object? updatedAt = freezed,}) {
  return _then(_LunchPantryEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,portions: null == portions ? _self.portions : portions // ignore: cast_nullable_to_non_nullable
as int,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

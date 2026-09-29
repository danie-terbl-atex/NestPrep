// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lunch_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LunchItem {

@JsonKey(includeToJson: false) String get id; String get name;/// [name] normalised — derived, never typed (`Meal.named`'s reasoning).
 String get nameKey;/// The slot it goes in, as stored. Read through [slot], which is null for
/// a slot this build does not know (`BE-10`).
@JsonKey(name: 'slot') String get slotName;/// Allergen codes (`Allergen.name`). Kept as stored so a code a newer
/// build added still travels into a box and still reaches the rules.
 List<String> get allergens;/// Worth making ahead on Sunday — muffins, boiled eggs, cut veg.
 bool get prepAhead;/// How to make it ahead, shown on the prep list.
 String? get prepNote; bool get archived;/// Set on the items the library was seeded with, so re-seeding recognises
/// them; null for the household's own.
 String? get seedKey; String get addedBy;@ServerTimestampConverter() DateTime? get createdAt;
/// Create a copy of LunchItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LunchItemCopyWith<LunchItem> get copyWith => _$LunchItemCopyWithImpl<LunchItem>(this as LunchItem, _$identity);

  /// Serializes this LunchItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LunchItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LunchItem&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.nameKey, _this.nameKey) || other.nameKey == _this.nameKey)&&(identical(other.slotName, _this.slotName) || other.slotName == _this.slotName)&&const DeepCollectionEquality().equals(other.allergens, _this.allergens)&&(identical(other.prepAhead, _this.prepAhead) || other.prepAhead == _this.prepAhead)&&(identical(other.prepNote, _this.prepNote) || other.prepNote == _this.prepNote)&&(identical(other.archived, _this.archived) || other.archived == _this.archived)&&(identical(other.seedKey, _this.seedKey) || other.seedKey == _this.seedKey)&&(identical(other.addedBy, _this.addedBy) || other.addedBy == _this.addedBy)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LunchItem;
  return Object.hash(runtimeType,_this.id,_this.name,_this.nameKey,_this.slotName,const DeepCollectionEquality().hash(_this.allergens),_this.prepAhead,_this.prepNote,_this.archived,_this.seedKey,_this.addedBy,_this.createdAt);
}

@override
String toString() {
  final _this = this as LunchItem;
  return 'LunchItem(id: ${_this.id}, name: ${_this.name}, nameKey: ${_this.nameKey}, slotName: ${_this.slotName}, allergens: ${_this.allergens}, prepAhead: ${_this.prepAhead}, prepNote: ${_this.prepNote}, archived: ${_this.archived}, seedKey: ${_this.seedKey}, addedBy: ${_this.addedBy}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $LunchItemCopyWith<$Res>  {
  factory $LunchItemCopyWith(LunchItem value, $Res Function(LunchItem) _then) = _$LunchItemCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String name, String nameKey,@JsonKey(name: 'slot') String slotName, List<String> allergens, bool prepAhead, String? prepNote, bool archived, String? seedKey, String addedBy,@ServerTimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class _$LunchItemCopyWithImpl<$Res>
    implements $LunchItemCopyWith<$Res> {
  _$LunchItemCopyWithImpl(this._self, this._then);

  final LunchItem _self;
  final $Res Function(LunchItem) _then;

/// Create a copy of LunchItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? nameKey = null,Object? slotName = null,Object? allergens = null,Object? prepAhead = null,Object? prepNote = freezed,Object? archived = null,Object? seedKey = freezed,Object? addedBy = null,Object? createdAt = freezed,}) {
  return _then(LunchItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameKey: null == nameKey ? _self.nameKey : nameKey // ignore: cast_nullable_to_non_nullable
as String,slotName: null == slotName ? _self.slotName : slotName // ignore: cast_nullable_to_non_nullable
as String,allergens: null == allergens ? _self.allergens : allergens // ignore: cast_nullable_to_non_nullable
as List<String>,prepAhead: null == prepAhead ? _self.prepAhead : prepAhead // ignore: cast_nullable_to_non_nullable
as bool,prepNote: freezed == prepNote ? _self.prepNote : prepNote // ignore: cast_nullable_to_non_nullable
as String?,archived: null == archived ? _self.archived : archived // ignore: cast_nullable_to_non_nullable
as bool,seedKey: freezed == seedKey ? _self.seedKey : seedKey // ignore: cast_nullable_to_non_nullable
as String?,addedBy: null == addedBy ? _self.addedBy : addedBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [LunchItem].
extension LunchItemPatterns on LunchItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LunchItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LunchItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LunchItem value)  $default,){
final _that = this;
switch (_that) {
case _LunchItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LunchItem value)?  $default,){
final _that = this;
switch (_that) {
case _LunchItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String name,  String nameKey, @JsonKey(name: 'slot')  String slotName,  List<String> allergens,  bool prepAhead,  String? prepNote,  bool archived,  String? seedKey,  String addedBy, @ServerTimestampConverter()  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LunchItem() when $default != null:
return $default(_that.id,_that.name,_that.nameKey,_that.slotName,_that.allergens,_that.prepAhead,_that.prepNote,_that.archived,_that.seedKey,_that.addedBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String name,  String nameKey, @JsonKey(name: 'slot')  String slotName,  List<String> allergens,  bool prepAhead,  String? prepNote,  bool archived,  String? seedKey,  String addedBy, @ServerTimestampConverter()  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _LunchItem():
return $default(_that.id,_that.name,_that.nameKey,_that.slotName,_that.allergens,_that.prepAhead,_that.prepNote,_that.archived,_that.seedKey,_that.addedBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String name,  String nameKey, @JsonKey(name: 'slot')  String slotName,  List<String> allergens,  bool prepAhead,  String? prepNote,  bool archived,  String? seedKey,  String addedBy, @ServerTimestampConverter()  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _LunchItem() when $default != null:
return $default(_that.id,_that.name,_that.nameKey,_that.slotName,_that.allergens,_that.prepAhead,_that.prepNote,_that.archived,_that.seedKey,_that.addedBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LunchItem extends LunchItem {
  const _LunchItem({@JsonKey(includeToJson: false) required this.id, required this.name, required this.nameKey, @JsonKey(name: 'slot') required this.slotName,  List<String> allergens = const <String>[], this.prepAhead = false, this.prepNote, this.archived = false, this.seedKey, required this.addedBy, @ServerTimestampConverter() this.createdAt}): _allergens = allergens,super._();
  factory _LunchItem.fromJson(Map<String, dynamic> json) => _$LunchItemFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String name;
/// [name] normalised — derived, never typed (`Meal.named`'s reasoning).
@override final  String nameKey;
/// The slot it goes in, as stored. Read through [slot], which is null for
/// a slot this build does not know (`BE-10`).
@override@JsonKey(name: 'slot') final  String slotName;
/// Allergen codes (`Allergen.name`). Kept as stored so a code a newer
/// build added still travels into a box and still reaches the rules.
 final  List<String> _allergens;
/// Allergen codes (`Allergen.name`). Kept as stored so a code a newer
/// build added still travels into a box and still reaches the rules.
@override@JsonKey() List<String> get allergens {
  if (_allergens is EqualUnmodifiableListView) return _allergens;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allergens);
}

/// Worth making ahead on Sunday — muffins, boiled eggs, cut veg.
@override@JsonKey() final  bool prepAhead;
/// How to make it ahead, shown on the prep list.
@override final  String? prepNote;
@override@JsonKey() final  bool archived;
/// Set on the items the library was seeded with, so re-seeding recognises
/// them; null for the household's own.
@override final  String? seedKey;
@override final  String addedBy;
@override@ServerTimestampConverter() final  DateTime? createdAt;

/// Create a copy of LunchItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LunchItemCopyWith<_LunchItem> get copyWith => __$LunchItemCopyWithImpl<_LunchItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LunchItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LunchItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameKey, nameKey) || other.nameKey == nameKey)&&(identical(other.slotName, slotName) || other.slotName == slotName)&&const DeepCollectionEquality().equals(other.allergens, _allergens)&&(identical(other.prepAhead, prepAhead) || other.prepAhead == prepAhead)&&(identical(other.prepNote, prepNote) || other.prepNote == prepNote)&&(identical(other.archived, archived) || other.archived == archived)&&(identical(other.seedKey, seedKey) || other.seedKey == seedKey)&&(identical(other.addedBy, addedBy) || other.addedBy == addedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,nameKey,slotName,const DeepCollectionEquality().hash(_allergens),prepAhead,prepNote,archived,seedKey,addedBy,createdAt);
}

@override
String toString() {
    return 'LunchItem(id: $id, name: $name, nameKey: $nameKey, slotName: $slotName, allergens: $allergens, prepAhead: $prepAhead, prepNote: $prepNote, archived: $archived, seedKey: $seedKey, addedBy: $addedBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$LunchItemCopyWith<$Res> implements $LunchItemCopyWith<$Res> {
  factory _$LunchItemCopyWith(_LunchItem value, $Res Function(_LunchItem) _then) = __$LunchItemCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String name, String nameKey,@JsonKey(name: 'slot') String slotName, List<String> allergens, bool prepAhead, String? prepNote, bool archived, String? seedKey, String addedBy,@ServerTimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class __$LunchItemCopyWithImpl<$Res>
    implements _$LunchItemCopyWith<$Res> {
  __$LunchItemCopyWithImpl(this._self, this._then);

  final _LunchItem _self;
  final $Res Function(_LunchItem) _then;

/// Create a copy of LunchItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? nameKey = null,Object? slotName = null,Object? allergens = null,Object? prepAhead = null,Object? prepNote = freezed,Object? archived = null,Object? seedKey = freezed,Object? addedBy = null,Object? createdAt = freezed,}) {
  return _then(_LunchItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameKey: null == nameKey ? _self.nameKey : nameKey // ignore: cast_nullable_to_non_nullable
as String,slotName: null == slotName ? _self.slotName : slotName // ignore: cast_nullable_to_non_nullable
as String,allergens: null == allergens ? _self._allergens : allergens // ignore: cast_nullable_to_non_nullable
as List<String>,prepAhead: null == prepAhead ? _self.prepAhead : prepAhead // ignore: cast_nullable_to_non_nullable
as bool,prepNote: freezed == prepNote ? _self.prepNote : prepNote // ignore: cast_nullable_to_non_nullable
as String?,archived: null == archived ? _self.archived : archived // ignore: cast_nullable_to_non_nullable
as bool,seedKey: freezed == seedKey ? _self.seedKey : seedKey // ignore: cast_nullable_to_non_nullable
as String?,addedBy: null == addedBy ? _self.addedBy : addedBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

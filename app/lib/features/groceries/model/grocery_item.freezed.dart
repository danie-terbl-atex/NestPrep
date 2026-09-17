// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'grocery_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GroceryItem {

@JsonKey(includeToJson: false) String get id; String get name;/// Free text, because "2 kg" and "a few" are both what people write.
 String? get quantity;/// The member profile that added it, not the account — an admin adding on
/// behalf of a child records the child.
 String get addedBy;@ServerTimestampConverter() DateTime? get addedAt;@NullableTimestampConverter() DateTime? get boughtAt; String? get boughtBy;
/// Create a copy of GroceryItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroceryItemCopyWith<GroceryItem> get copyWith => _$GroceryItemCopyWithImpl<GroceryItem>(this as GroceryItem, _$identity);

  /// Serializes this GroceryItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GroceryItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroceryItem&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.quantity, _this.quantity) || other.quantity == _this.quantity)&&(identical(other.addedBy, _this.addedBy) || other.addedBy == _this.addedBy)&&(identical(other.addedAt, _this.addedAt) || other.addedAt == _this.addedAt)&&(identical(other.boughtAt, _this.boughtAt) || other.boughtAt == _this.boughtAt)&&(identical(other.boughtBy, _this.boughtBy) || other.boughtBy == _this.boughtBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GroceryItem;
  return Object.hash(runtimeType,_this.id,_this.name,_this.quantity,_this.addedBy,_this.addedAt,_this.boughtAt,_this.boughtBy);
}

@override
String toString() {
  final _this = this as GroceryItem;
  return 'GroceryItem(id: ${_this.id}, name: ${_this.name}, quantity: ${_this.quantity}, addedBy: ${_this.addedBy}, addedAt: ${_this.addedAt}, boughtAt: ${_this.boughtAt}, boughtBy: ${_this.boughtBy})';
}


}

/// @nodoc
abstract mixin class $GroceryItemCopyWith<$Res>  {
  factory $GroceryItemCopyWith(GroceryItem value, $Res Function(GroceryItem) _then) = _$GroceryItemCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String name, String? quantity, String addedBy,@ServerTimestampConverter() DateTime? addedAt,@NullableTimestampConverter() DateTime? boughtAt, String? boughtBy
});




}
/// @nodoc
class _$GroceryItemCopyWithImpl<$Res>
    implements $GroceryItemCopyWith<$Res> {
  _$GroceryItemCopyWithImpl(this._self, this._then);

  final GroceryItem _self;
  final $Res Function(GroceryItem) _then;

/// Create a copy of GroceryItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? quantity = freezed,Object? addedBy = null,Object? addedAt = freezed,Object? boughtAt = freezed,Object? boughtBy = freezed,}) {
  return _then(GroceryItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String?,addedBy: null == addedBy ? _self.addedBy : addedBy // ignore: cast_nullable_to_non_nullable
as String,addedAt: freezed == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,boughtAt: freezed == boughtAt ? _self.boughtAt : boughtAt // ignore: cast_nullable_to_non_nullable
as DateTime?,boughtBy: freezed == boughtBy ? _self.boughtBy : boughtBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GroceryItem].
extension GroceryItemPatterns on GroceryItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroceryItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroceryItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroceryItem value)  $default,){
final _that = this;
switch (_that) {
case _GroceryItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroceryItem value)?  $default,){
final _that = this;
switch (_that) {
case _GroceryItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String name,  String? quantity,  String addedBy, @ServerTimestampConverter()  DateTime? addedAt, @NullableTimestampConverter()  DateTime? boughtAt,  String? boughtBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroceryItem() when $default != null:
return $default(_that.id,_that.name,_that.quantity,_that.addedBy,_that.addedAt,_that.boughtAt,_that.boughtBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String name,  String? quantity,  String addedBy, @ServerTimestampConverter()  DateTime? addedAt, @NullableTimestampConverter()  DateTime? boughtAt,  String? boughtBy)  $default,) {final _that = this;
switch (_that) {
case _GroceryItem():
return $default(_that.id,_that.name,_that.quantity,_that.addedBy,_that.addedAt,_that.boughtAt,_that.boughtBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String name,  String? quantity,  String addedBy, @ServerTimestampConverter()  DateTime? addedAt, @NullableTimestampConverter()  DateTime? boughtAt,  String? boughtBy)?  $default,) {final _that = this;
switch (_that) {
case _GroceryItem() when $default != null:
return $default(_that.id,_that.name,_that.quantity,_that.addedBy,_that.addedAt,_that.boughtAt,_that.boughtBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroceryItem extends GroceryItem {
  const _GroceryItem({@JsonKey(includeToJson: false) required this.id, required this.name, this.quantity, required this.addedBy, @ServerTimestampConverter() this.addedAt, @NullableTimestampConverter() this.boughtAt, this.boughtBy}): super._();
  factory _GroceryItem.fromJson(Map<String, dynamic> json) => _$GroceryItemFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String name;
/// Free text, because "2 kg" and "a few" are both what people write.
@override final  String? quantity;
/// The member profile that added it, not the account — an admin adding on
/// behalf of a child records the child.
@override final  String addedBy;
@override@ServerTimestampConverter() final  DateTime? addedAt;
@override@NullableTimestampConverter() final  DateTime? boughtAt;
@override final  String? boughtBy;

/// Create a copy of GroceryItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroceryItemCopyWith<_GroceryItem> get copyWith => __$GroceryItemCopyWithImpl<_GroceryItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroceryItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroceryItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.addedBy, addedBy) || other.addedBy == addedBy)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt)&&(identical(other.boughtAt, boughtAt) || other.boughtAt == boughtAt)&&(identical(other.boughtBy, boughtBy) || other.boughtBy == boughtBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,quantity,addedBy,addedAt,boughtAt,boughtBy);
}

@override
String toString() {
    return 'GroceryItem(id: $id, name: $name, quantity: $quantity, addedBy: $addedBy, addedAt: $addedAt, boughtAt: $boughtAt, boughtBy: $boughtBy)';
}


}

/// @nodoc
abstract mixin class _$GroceryItemCopyWith<$Res> implements $GroceryItemCopyWith<$Res> {
  factory _$GroceryItemCopyWith(_GroceryItem value, $Res Function(_GroceryItem) _then) = __$GroceryItemCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String name, String? quantity, String addedBy,@ServerTimestampConverter() DateTime? addedAt,@NullableTimestampConverter() DateTime? boughtAt, String? boughtBy
});




}
/// @nodoc
class __$GroceryItemCopyWithImpl<$Res>
    implements _$GroceryItemCopyWith<$Res> {
  __$GroceryItemCopyWithImpl(this._self, this._then);

  final _GroceryItem _self;
  final $Res Function(_GroceryItem) _then;

/// Create a copy of GroceryItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? quantity = freezed,Object? addedBy = null,Object? addedAt = freezed,Object? boughtAt = freezed,Object? boughtBy = freezed,}) {
  return _then(_GroceryItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String?,addedBy: null == addedBy ? _self.addedBy : addedBy // ignore: cast_nullable_to_non_nullable
as String,addedAt: freezed == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,boughtAt: freezed == boughtAt ? _self.boughtAt : boughtAt // ignore: cast_nullable_to_non_nullable
as DateTime?,boughtBy: freezed == boughtBy ? _self.boughtBy : boughtBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

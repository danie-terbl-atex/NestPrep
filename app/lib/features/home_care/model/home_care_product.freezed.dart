// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_care_product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HomeCareProduct {

@JsonKey(includeToJson: false) String get id; String get name;@JsonKey(unknownEnumValue: ProductKind.other) ProductKind get kind;/// Where it lives, so the helper does not have to ask.
 String? get whereKept; String? get note; bool get keepFromChildren; bool get keepFromPets;/// The member profile that added it, not the account.
 String get createdBy;@ServerTimestampConverter() DateTime? get createdAt;/// How much is left (home-care ADR-0005). Never written with the rest of
/// the product — only by its own update, so a parent's edit cannot put a
/// stale level back over the helper's. A product from before the tracker
/// has none, which reads as full (`BE-10`).
@JsonKey(includeToJson: false, unknownEnumValue: StockLevel.full) StockLevel get stock;@JsonKey(includeToJson: false) String? get stockChangedBy;@JsonKey(includeToJson: false)@NullableTimestampConverter() DateTime? get stockChangedAt;
/// Create a copy of HomeCareProduct
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeCareProductCopyWith<HomeCareProduct> get copyWith => _$HomeCareProductCopyWithImpl<HomeCareProduct>(this as HomeCareProduct, _$identity);

  /// Serializes this HomeCareProduct to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HomeCareProduct;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeCareProduct&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.whereKept, _this.whereKept) || other.whereKept == _this.whereKept)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.keepFromChildren, _this.keepFromChildren) || other.keepFromChildren == _this.keepFromChildren)&&(identical(other.keepFromPets, _this.keepFromPets) || other.keepFromPets == _this.keepFromPets)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.stock, _this.stock) || other.stock == _this.stock)&&(identical(other.stockChangedBy, _this.stockChangedBy) || other.stockChangedBy == _this.stockChangedBy)&&(identical(other.stockChangedAt, _this.stockChangedAt) || other.stockChangedAt == _this.stockChangedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HomeCareProduct;
  return Object.hash(runtimeType,_this.id,_this.name,_this.kind,_this.whereKept,_this.note,_this.keepFromChildren,_this.keepFromPets,_this.createdBy,_this.createdAt,_this.stock,_this.stockChangedBy,_this.stockChangedAt);
}

@override
String toString() {
  final _this = this as HomeCareProduct;
  return 'HomeCareProduct(id: ${_this.id}, name: ${_this.name}, kind: ${_this.kind}, whereKept: ${_this.whereKept}, note: ${_this.note}, keepFromChildren: ${_this.keepFromChildren}, keepFromPets: ${_this.keepFromPets}, createdBy: ${_this.createdBy}, createdAt: ${_this.createdAt}, stock: ${_this.stock}, stockChangedBy: ${_this.stockChangedBy}, stockChangedAt: ${_this.stockChangedAt})';
}


}

/// @nodoc
abstract mixin class $HomeCareProductCopyWith<$Res>  {
  factory $HomeCareProductCopyWith(HomeCareProduct value, $Res Function(HomeCareProduct) _then) = _$HomeCareProductCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String name,@JsonKey(unknownEnumValue: ProductKind.other) ProductKind kind, String? whereKept, String? note, bool keepFromChildren, bool keepFromPets, String createdBy,@ServerTimestampConverter() DateTime? createdAt,@JsonKey(includeToJson: false, unknownEnumValue: StockLevel.full) StockLevel stock,@JsonKey(includeToJson: false) String? stockChangedBy,@JsonKey(includeToJson: false)@NullableTimestampConverter() DateTime? stockChangedAt
});




}
/// @nodoc
class _$HomeCareProductCopyWithImpl<$Res>
    implements $HomeCareProductCopyWith<$Res> {
  _$HomeCareProductCopyWithImpl(this._self, this._then);

  final HomeCareProduct _self;
  final $Res Function(HomeCareProduct) _then;

/// Create a copy of HomeCareProduct
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? kind = null,Object? whereKept = freezed,Object? note = freezed,Object? keepFromChildren = null,Object? keepFromPets = null,Object? createdBy = null,Object? createdAt = freezed,Object? stock = null,Object? stockChangedBy = freezed,Object? stockChangedAt = freezed,}) {
  return _then(HomeCareProduct(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ProductKind,whereKept: freezed == whereKept ? _self.whereKept : whereKept // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,keepFromChildren: null == keepFromChildren ? _self.keepFromChildren : keepFromChildren // ignore: cast_nullable_to_non_nullable
as bool,keepFromPets: null == keepFromPets ? _self.keepFromPets : keepFromPets // ignore: cast_nullable_to_non_nullable
as bool,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,stock: null == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as StockLevel,stockChangedBy: freezed == stockChangedBy ? _self.stockChangedBy : stockChangedBy // ignore: cast_nullable_to_non_nullable
as String?,stockChangedAt: freezed == stockChangedAt ? _self.stockChangedAt : stockChangedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [HomeCareProduct].
extension HomeCareProductPatterns on HomeCareProduct {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeCareProduct value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeCareProduct() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeCareProduct value)  $default,){
final _that = this;
switch (_that) {
case _HomeCareProduct():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeCareProduct value)?  $default,){
final _that = this;
switch (_that) {
case _HomeCareProduct() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String name, @JsonKey(unknownEnumValue: ProductKind.other)  ProductKind kind,  String? whereKept,  String? note,  bool keepFromChildren,  bool keepFromPets,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt, @JsonKey(includeToJson: false, unknownEnumValue: StockLevel.full)  StockLevel stock, @JsonKey(includeToJson: false)  String? stockChangedBy, @JsonKey(includeToJson: false)@NullableTimestampConverter()  DateTime? stockChangedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeCareProduct() when $default != null:
return $default(_that.id,_that.name,_that.kind,_that.whereKept,_that.note,_that.keepFromChildren,_that.keepFromPets,_that.createdBy,_that.createdAt,_that.stock,_that.stockChangedBy,_that.stockChangedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String name, @JsonKey(unknownEnumValue: ProductKind.other)  ProductKind kind,  String? whereKept,  String? note,  bool keepFromChildren,  bool keepFromPets,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt, @JsonKey(includeToJson: false, unknownEnumValue: StockLevel.full)  StockLevel stock, @JsonKey(includeToJson: false)  String? stockChangedBy, @JsonKey(includeToJson: false)@NullableTimestampConverter()  DateTime? stockChangedAt)  $default,) {final _that = this;
switch (_that) {
case _HomeCareProduct():
return $default(_that.id,_that.name,_that.kind,_that.whereKept,_that.note,_that.keepFromChildren,_that.keepFromPets,_that.createdBy,_that.createdAt,_that.stock,_that.stockChangedBy,_that.stockChangedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String name, @JsonKey(unknownEnumValue: ProductKind.other)  ProductKind kind,  String? whereKept,  String? note,  bool keepFromChildren,  bool keepFromPets,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt, @JsonKey(includeToJson: false, unknownEnumValue: StockLevel.full)  StockLevel stock, @JsonKey(includeToJson: false)  String? stockChangedBy, @JsonKey(includeToJson: false)@NullableTimestampConverter()  DateTime? stockChangedAt)?  $default,) {final _that = this;
switch (_that) {
case _HomeCareProduct() when $default != null:
return $default(_that.id,_that.name,_that.kind,_that.whereKept,_that.note,_that.keepFromChildren,_that.keepFromPets,_that.createdBy,_that.createdAt,_that.stock,_that.stockChangedBy,_that.stockChangedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HomeCareProduct implements HomeCareProduct {
  const _HomeCareProduct({@JsonKey(includeToJson: false) required this.id, required this.name, @JsonKey(unknownEnumValue: ProductKind.other) required this.kind, this.whereKept, this.note, this.keepFromChildren = false, this.keepFromPets = false, required this.createdBy, @ServerTimestampConverter() this.createdAt, @JsonKey(includeToJson: false, unknownEnumValue: StockLevel.full) this.stock = StockLevel.full, @JsonKey(includeToJson: false) this.stockChangedBy, @JsonKey(includeToJson: false)@NullableTimestampConverter() this.stockChangedAt});
  factory _HomeCareProduct.fromJson(Map<String, dynamic> json) => _$HomeCareProductFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String name;
@override@JsonKey(unknownEnumValue: ProductKind.other) final  ProductKind kind;
/// Where it lives, so the helper does not have to ask.
@override final  String? whereKept;
@override final  String? note;
@override@JsonKey() final  bool keepFromChildren;
@override@JsonKey() final  bool keepFromPets;
/// The member profile that added it, not the account.
@override final  String createdBy;
@override@ServerTimestampConverter() final  DateTime? createdAt;
/// How much is left (home-care ADR-0005). Never written with the rest of
/// the product — only by its own update, so a parent's edit cannot put a
/// stale level back over the helper's. A product from before the tracker
/// has none, which reads as full (`BE-10`).
@override@JsonKey(includeToJson: false, unknownEnumValue: StockLevel.full) final  StockLevel stock;
@override@JsonKey(includeToJson: false) final  String? stockChangedBy;
@override@JsonKey(includeToJson: false)@NullableTimestampConverter() final  DateTime? stockChangedAt;

/// Create a copy of HomeCareProduct
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeCareProductCopyWith<_HomeCareProduct> get copyWith => __$HomeCareProductCopyWithImpl<_HomeCareProduct>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HomeCareProductToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeCareProduct&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.whereKept, whereKept) || other.whereKept == whereKept)&&(identical(other.note, note) || other.note == note)&&(identical(other.keepFromChildren, keepFromChildren) || other.keepFromChildren == keepFromChildren)&&(identical(other.keepFromPets, keepFromPets) || other.keepFromPets == keepFromPets)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.stock, stock) || other.stock == stock)&&(identical(other.stockChangedBy, stockChangedBy) || other.stockChangedBy == stockChangedBy)&&(identical(other.stockChangedAt, stockChangedAt) || other.stockChangedAt == stockChangedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,kind,whereKept,note,keepFromChildren,keepFromPets,createdBy,createdAt,stock,stockChangedBy,stockChangedAt);
}

@override
String toString() {
    return 'HomeCareProduct(id: $id, name: $name, kind: $kind, whereKept: $whereKept, note: $note, keepFromChildren: $keepFromChildren, keepFromPets: $keepFromPets, createdBy: $createdBy, createdAt: $createdAt, stock: $stock, stockChangedBy: $stockChangedBy, stockChangedAt: $stockChangedAt)';
}


}

/// @nodoc
abstract mixin class _$HomeCareProductCopyWith<$Res> implements $HomeCareProductCopyWith<$Res> {
  factory _$HomeCareProductCopyWith(_HomeCareProduct value, $Res Function(_HomeCareProduct) _then) = __$HomeCareProductCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String name,@JsonKey(unknownEnumValue: ProductKind.other) ProductKind kind, String? whereKept, String? note, bool keepFromChildren, bool keepFromPets, String createdBy,@ServerTimestampConverter() DateTime? createdAt,@JsonKey(includeToJson: false, unknownEnumValue: StockLevel.full) StockLevel stock,@JsonKey(includeToJson: false) String? stockChangedBy,@JsonKey(includeToJson: false)@NullableTimestampConverter() DateTime? stockChangedAt
});




}
/// @nodoc
class __$HomeCareProductCopyWithImpl<$Res>
    implements _$HomeCareProductCopyWith<$Res> {
  __$HomeCareProductCopyWithImpl(this._self, this._then);

  final _HomeCareProduct _self;
  final $Res Function(_HomeCareProduct) _then;

/// Create a copy of HomeCareProduct
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? kind = null,Object? whereKept = freezed,Object? note = freezed,Object? keepFromChildren = null,Object? keepFromPets = null,Object? createdBy = null,Object? createdAt = freezed,Object? stock = null,Object? stockChangedBy = freezed,Object? stockChangedAt = freezed,}) {
  return _then(_HomeCareProduct(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ProductKind,whereKept: freezed == whereKept ? _self.whereKept : whereKept // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,keepFromChildren: null == keepFromChildren ? _self.keepFromChildren : keepFromChildren // ignore: cast_nullable_to_non_nullable
as bool,keepFromPets: null == keepFromPets ? _self.keepFromPets : keepFromPets // ignore: cast_nullable_to_non_nullable
as bool,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,stock: null == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as StockLevel,stockChangedBy: freezed == stockChangedBy ? _self.stockChangedBy : stockChangedBy // ignore: cast_nullable_to_non_nullable
as String?,stockChangedAt: freezed == stockChangedAt ? _self.stockChangedAt : stockChangedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

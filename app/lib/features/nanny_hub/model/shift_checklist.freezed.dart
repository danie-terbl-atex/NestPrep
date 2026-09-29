// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shift_checklist.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShiftChecklist {

@JsonKey(includeToJson: false) String get id; List<ChecklistItem> get items; String? get updatedBy;@ServerTimestampConverter() DateTime? get updatedAt;
/// Create a copy of ShiftChecklist
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShiftChecklistCopyWith<ShiftChecklist> get copyWith => _$ShiftChecklistCopyWithImpl<ShiftChecklist>(this as ShiftChecklist, _$identity);

  /// Serializes this ShiftChecklist to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ShiftChecklist;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShiftChecklist&&(identical(other.id, _this.id) || other.id == _this.id)&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.updatedBy, _this.updatedBy) || other.updatedBy == _this.updatedBy)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ShiftChecklist;
  return Object.hash(runtimeType,_this.id,const DeepCollectionEquality().hash(_this.items),_this.updatedBy,_this.updatedAt);
}

@override
String toString() {
  final _this = this as ShiftChecklist;
  return 'ShiftChecklist(id: ${_this.id}, items: ${_this.items}, updatedBy: ${_this.updatedBy}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $ShiftChecklistCopyWith<$Res>  {
  factory $ShiftChecklistCopyWith(ShiftChecklist value, $Res Function(ShiftChecklist) _then) = _$ShiftChecklistCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, List<ChecklistItem> items, String? updatedBy,@ServerTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$ShiftChecklistCopyWithImpl<$Res>
    implements $ShiftChecklistCopyWith<$Res> {
  _$ShiftChecklistCopyWithImpl(this._self, this._then);

  final ShiftChecklist _self;
  final $Res Function(ShiftChecklist) _then;

/// Create a copy of ShiftChecklist
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? items = null,Object? updatedBy = freezed,Object? updatedAt = freezed,}) {
  return _then(ShiftChecklist(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ChecklistItem>,updatedBy: freezed == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ShiftChecklist].
extension ShiftChecklistPatterns on ShiftChecklist {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShiftChecklist value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShiftChecklist() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShiftChecklist value)  $default,){
final _that = this;
switch (_that) {
case _ShiftChecklist():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShiftChecklist value)?  $default,){
final _that = this;
switch (_that) {
case _ShiftChecklist() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  List<ChecklistItem> items,  String? updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShiftChecklist() when $default != null:
return $default(_that.id,_that.items,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  List<ChecklistItem> items,  String? updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ShiftChecklist():
return $default(_that.id,_that.items,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  List<ChecklistItem> items,  String? updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ShiftChecklist() when $default != null:
return $default(_that.id,_that.items,_that.updatedBy,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShiftChecklist extends ShiftChecklist {
  const _ShiftChecklist({@JsonKey(includeToJson: false) required this.id,  List<ChecklistItem> items = const <ChecklistItem>[], this.updatedBy, @ServerTimestampConverter() this.updatedAt}): _items = items,super._();
  factory _ShiftChecklist.fromJson(Map<String, dynamic> json) => _$ShiftChecklistFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
 final  List<ChecklistItem> _items;
@override@JsonKey() List<ChecklistItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? updatedBy;
@override@ServerTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of ShiftChecklist
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShiftChecklistCopyWith<_ShiftChecklist> get copyWith => __$ShiftChecklistCopyWithImpl<_ShiftChecklist>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShiftChecklistToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShiftChecklist&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_items),updatedBy,updatedAt);
}

@override
String toString() {
    return 'ShiftChecklist(id: $id, items: $items, updatedBy: $updatedBy, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ShiftChecklistCopyWith<$Res> implements $ShiftChecklistCopyWith<$Res> {
  factory _$ShiftChecklistCopyWith(_ShiftChecklist value, $Res Function(_ShiftChecklist) _then) = __$ShiftChecklistCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, List<ChecklistItem> items, String? updatedBy,@ServerTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$ShiftChecklistCopyWithImpl<$Res>
    implements _$ShiftChecklistCopyWith<$Res> {
  __$ShiftChecklistCopyWithImpl(this._self, this._then);

  final _ShiftChecklist _self;
  final $Res Function(_ShiftChecklist) _then;

/// Create a copy of ShiftChecklist
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? items = null,Object? updatedBy = freezed,Object? updatedAt = freezed,}) {
  return _then(_ShiftChecklist(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ChecklistItem>,updatedBy: freezed == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

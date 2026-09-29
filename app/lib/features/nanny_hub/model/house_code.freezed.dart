// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'house_code.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HouseCode {

@JsonKey(includeToJson: false) String get id; String get label; String get value; String? get note; String get createdBy;@ServerTimestampConverter() DateTime? get createdAt;
/// Create a copy of HouseCode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HouseCodeCopyWith<HouseCode> get copyWith => _$HouseCodeCopyWithImpl<HouseCode>(this as HouseCode, _$identity);

  /// Serializes this HouseCode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HouseCode;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HouseCode&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.value, _this.value) || other.value == _this.value)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HouseCode;
  return Object.hash(runtimeType,_this.id,_this.label,_this.value,_this.note,_this.createdBy,_this.createdAt);
}

@override
String toString() {
  final _this = this as HouseCode;
  return 'HouseCode(id: ${_this.id}, label: ${_this.label}, value: ${_this.value}, note: ${_this.note}, createdBy: ${_this.createdBy}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $HouseCodeCopyWith<$Res>  {
  factory $HouseCodeCopyWith(HouseCode value, $Res Function(HouseCode) _then) = _$HouseCodeCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String label, String value, String? note, String createdBy,@ServerTimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class _$HouseCodeCopyWithImpl<$Res>
    implements $HouseCodeCopyWith<$Res> {
  _$HouseCodeCopyWithImpl(this._self, this._then);

  final HouseCode _self;
  final $Res Function(HouseCode) _then;

/// Create a copy of HouseCode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? value = null,Object? note = freezed,Object? createdBy = null,Object? createdAt = freezed,}) {
  return _then(HouseCode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [HouseCode].
extension HouseCodePatterns on HouseCode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HouseCode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HouseCode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HouseCode value)  $default,){
final _that = this;
switch (_that) {
case _HouseCode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HouseCode value)?  $default,){
final _that = this;
switch (_that) {
case _HouseCode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String label,  String value,  String? note,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HouseCode() when $default != null:
return $default(_that.id,_that.label,_that.value,_that.note,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String label,  String value,  String? note,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _HouseCode():
return $default(_that.id,_that.label,_that.value,_that.note,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String label,  String value,  String? note,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _HouseCode() when $default != null:
return $default(_that.id,_that.label,_that.value,_that.note,_that.createdBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HouseCode implements HouseCode {
  const _HouseCode({@JsonKey(includeToJson: false) required this.id, required this.label, required this.value, this.note, required this.createdBy, @ServerTimestampConverter() this.createdAt});
  factory _HouseCode.fromJson(Map<String, dynamic> json) => _$HouseCodeFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String label;
@override final  String value;
@override final  String? note;
@override final  String createdBy;
@override@ServerTimestampConverter() final  DateTime? createdAt;

/// Create a copy of HouseCode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HouseCodeCopyWith<_HouseCode> get copyWith => __$HouseCodeCopyWithImpl<_HouseCode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HouseCodeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HouseCode&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value)&&(identical(other.note, note) || other.note == note)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,label,value,note,createdBy,createdAt);
}

@override
String toString() {
    return 'HouseCode(id: $id, label: $label, value: $value, note: $note, createdBy: $createdBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$HouseCodeCopyWith<$Res> implements $HouseCodeCopyWith<$Res> {
  factory _$HouseCodeCopyWith(_HouseCode value, $Res Function(_HouseCode) _then) = __$HouseCodeCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String label, String value, String? note, String createdBy,@ServerTimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class __$HouseCodeCopyWithImpl<$Res>
    implements _$HouseCodeCopyWith<$Res> {
  __$HouseCodeCopyWithImpl(this._self, this._then);

  final _HouseCode _self;
  final $Res Function(_HouseCode) _then;

/// Create a copy of HouseCode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? value = null,Object? note = freezed,Object? createdBy = null,Object? createdAt = freezed,}) {
  return _then(_HouseCode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

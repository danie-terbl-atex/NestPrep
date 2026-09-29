// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'guide_spot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GuideSpot {

@JsonKey(includeToJson: false) String get id; String get title; String? get note; String? get photoId; String get createdBy;@ServerTimestampConverter() DateTime? get createdAt;
/// Create a copy of GuideSpot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuideSpotCopyWith<GuideSpot> get copyWith => _$GuideSpotCopyWithImpl<GuideSpot>(this as GuideSpot, _$identity);

  /// Serializes this GuideSpot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GuideSpot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuideSpot&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.photoId, _this.photoId) || other.photoId == _this.photoId)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GuideSpot;
  return Object.hash(runtimeType,_this.id,_this.title,_this.note,_this.photoId,_this.createdBy,_this.createdAt);
}

@override
String toString() {
  final _this = this as GuideSpot;
  return 'GuideSpot(id: ${_this.id}, title: ${_this.title}, note: ${_this.note}, photoId: ${_this.photoId}, createdBy: ${_this.createdBy}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $GuideSpotCopyWith<$Res>  {
  factory $GuideSpotCopyWith(GuideSpot value, $Res Function(GuideSpot) _then) = _$GuideSpotCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String title, String? note, String? photoId, String createdBy,@ServerTimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class _$GuideSpotCopyWithImpl<$Res>
    implements $GuideSpotCopyWith<$Res> {
  _$GuideSpotCopyWithImpl(this._self, this._then);

  final GuideSpot _self;
  final $Res Function(GuideSpot) _then;

/// Create a copy of GuideSpot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? note = freezed,Object? photoId = freezed,Object? createdBy = null,Object? createdAt = freezed,}) {
  return _then(GuideSpot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,photoId: freezed == photoId ? _self.photoId : photoId // ignore: cast_nullable_to_non_nullable
as String?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [GuideSpot].
extension GuideSpotPatterns on GuideSpot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GuideSpot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GuideSpot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GuideSpot value)  $default,){
final _that = this;
switch (_that) {
case _GuideSpot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GuideSpot value)?  $default,){
final _that = this;
switch (_that) {
case _GuideSpot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String title,  String? note,  String? photoId,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GuideSpot() when $default != null:
return $default(_that.id,_that.title,_that.note,_that.photoId,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String title,  String? note,  String? photoId,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _GuideSpot():
return $default(_that.id,_that.title,_that.note,_that.photoId,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String title,  String? note,  String? photoId,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _GuideSpot() when $default != null:
return $default(_that.id,_that.title,_that.note,_that.photoId,_that.createdBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GuideSpot implements GuideSpot {
  const _GuideSpot({@JsonKey(includeToJson: false) required this.id, required this.title, this.note, this.photoId, required this.createdBy, @ServerTimestampConverter() this.createdAt});
  factory _GuideSpot.fromJson(Map<String, dynamic> json) => _$GuideSpotFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String title;
@override final  String? note;
@override final  String? photoId;
@override final  String createdBy;
@override@ServerTimestampConverter() final  DateTime? createdAt;

/// Create a copy of GuideSpot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuideSpotCopyWith<_GuideSpot> get copyWith => __$GuideSpotCopyWithImpl<_GuideSpot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuideSpotToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuideSpot&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.note, note) || other.note == note)&&(identical(other.photoId, photoId) || other.photoId == photoId)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,note,photoId,createdBy,createdAt);
}

@override
String toString() {
    return 'GuideSpot(id: $id, title: $title, note: $note, photoId: $photoId, createdBy: $createdBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$GuideSpotCopyWith<$Res> implements $GuideSpotCopyWith<$Res> {
  factory _$GuideSpotCopyWith(_GuideSpot value, $Res Function(_GuideSpot) _then) = __$GuideSpotCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String title, String? note, String? photoId, String createdBy,@ServerTimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class __$GuideSpotCopyWithImpl<$Res>
    implements _$GuideSpotCopyWith<$Res> {
  __$GuideSpotCopyWithImpl(this._self, this._then);

  final _GuideSpot _self;
  final $Res Function(_GuideSpot) _then;

/// Create a copy of GuideSpot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? note = freezed,Object? photoId = freezed,Object? createdBy = null,Object? createdAt = freezed,}) {
  return _then(_GuideSpot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,photoId: freezed == photoId ? _self.photoId : photoId // ignore: cast_nullable_to_non_nullable
as String?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

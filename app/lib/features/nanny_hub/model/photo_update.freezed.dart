// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'photo_update.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PhotoUpdate {

@JsonKey(includeToJson: false) String get id; String get photoId; String? get caption; List<String> get childIds; String get byMemberId;@ServerTimestampConverter() DateTime? get createdAt;
/// Create a copy of PhotoUpdate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PhotoUpdateCopyWith<PhotoUpdate> get copyWith => _$PhotoUpdateCopyWithImpl<PhotoUpdate>(this as PhotoUpdate, _$identity);

  /// Serializes this PhotoUpdate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PhotoUpdate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PhotoUpdate&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.photoId, _this.photoId) || other.photoId == _this.photoId)&&(identical(other.caption, _this.caption) || other.caption == _this.caption)&&const DeepCollectionEquality().equals(other.childIds, _this.childIds)&&(identical(other.byMemberId, _this.byMemberId) || other.byMemberId == _this.byMemberId)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PhotoUpdate;
  return Object.hash(runtimeType,_this.id,_this.photoId,_this.caption,const DeepCollectionEquality().hash(_this.childIds),_this.byMemberId,_this.createdAt);
}

@override
String toString() {
  final _this = this as PhotoUpdate;
  return 'PhotoUpdate(id: ${_this.id}, photoId: ${_this.photoId}, caption: ${_this.caption}, childIds: ${_this.childIds}, byMemberId: ${_this.byMemberId}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $PhotoUpdateCopyWith<$Res>  {
  factory $PhotoUpdateCopyWith(PhotoUpdate value, $Res Function(PhotoUpdate) _then) = _$PhotoUpdateCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String photoId, String? caption, List<String> childIds, String byMemberId,@ServerTimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class _$PhotoUpdateCopyWithImpl<$Res>
    implements $PhotoUpdateCopyWith<$Res> {
  _$PhotoUpdateCopyWithImpl(this._self, this._then);

  final PhotoUpdate _self;
  final $Res Function(PhotoUpdate) _then;

/// Create a copy of PhotoUpdate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? photoId = null,Object? caption = freezed,Object? childIds = null,Object? byMemberId = null,Object? createdAt = freezed,}) {
  return _then(PhotoUpdate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,photoId: null == photoId ? _self.photoId : photoId // ignore: cast_nullable_to_non_nullable
as String,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,childIds: null == childIds ? _self.childIds : childIds // ignore: cast_nullable_to_non_nullable
as List<String>,byMemberId: null == byMemberId ? _self.byMemberId : byMemberId // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PhotoUpdate].
extension PhotoUpdatePatterns on PhotoUpdate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PhotoUpdate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PhotoUpdate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PhotoUpdate value)  $default,){
final _that = this;
switch (_that) {
case _PhotoUpdate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PhotoUpdate value)?  $default,){
final _that = this;
switch (_that) {
case _PhotoUpdate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String photoId,  String? caption,  List<String> childIds,  String byMemberId, @ServerTimestampConverter()  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PhotoUpdate() when $default != null:
return $default(_that.id,_that.photoId,_that.caption,_that.childIds,_that.byMemberId,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String photoId,  String? caption,  List<String> childIds,  String byMemberId, @ServerTimestampConverter()  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _PhotoUpdate():
return $default(_that.id,_that.photoId,_that.caption,_that.childIds,_that.byMemberId,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String photoId,  String? caption,  List<String> childIds,  String byMemberId, @ServerTimestampConverter()  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _PhotoUpdate() when $default != null:
return $default(_that.id,_that.photoId,_that.caption,_that.childIds,_that.byMemberId,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PhotoUpdate implements PhotoUpdate {
  const _PhotoUpdate({@JsonKey(includeToJson: false) required this.id, required this.photoId, this.caption,  List<String> childIds = const <String>[], required this.byMemberId, @ServerTimestampConverter() this.createdAt}): _childIds = childIds;
  factory _PhotoUpdate.fromJson(Map<String, dynamic> json) => _$PhotoUpdateFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String photoId;
@override final  String? caption;
 final  List<String> _childIds;
@override@JsonKey() List<String> get childIds {
  if (_childIds is EqualUnmodifiableListView) return _childIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_childIds);
}

@override final  String byMemberId;
@override@ServerTimestampConverter() final  DateTime? createdAt;

/// Create a copy of PhotoUpdate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PhotoUpdateCopyWith<_PhotoUpdate> get copyWith => __$PhotoUpdateCopyWithImpl<_PhotoUpdate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PhotoUpdateToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PhotoUpdate&&(identical(other.id, id) || other.id == id)&&(identical(other.photoId, photoId) || other.photoId == photoId)&&(identical(other.caption, caption) || other.caption == caption)&&const DeepCollectionEquality().equals(other.childIds, _childIds)&&(identical(other.byMemberId, byMemberId) || other.byMemberId == byMemberId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,photoId,caption,const DeepCollectionEquality().hash(_childIds),byMemberId,createdAt);
}

@override
String toString() {
    return 'PhotoUpdate(id: $id, photoId: $photoId, caption: $caption, childIds: $childIds, byMemberId: $byMemberId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PhotoUpdateCopyWith<$Res> implements $PhotoUpdateCopyWith<$Res> {
  factory _$PhotoUpdateCopyWith(_PhotoUpdate value, $Res Function(_PhotoUpdate) _then) = __$PhotoUpdateCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String photoId, String? caption, List<String> childIds, String byMemberId,@ServerTimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class __$PhotoUpdateCopyWithImpl<$Res>
    implements _$PhotoUpdateCopyWith<$Res> {
  __$PhotoUpdateCopyWithImpl(this._self, this._then);

  final _PhotoUpdate _self;
  final $Res Function(_PhotoUpdate) _then;

/// Create a copy of PhotoUpdate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? photoId = null,Object? caption = freezed,Object? childIds = null,Object? byMemberId = null,Object? createdAt = freezed,}) {
  return _then(_PhotoUpdate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,photoId: null == photoId ? _self.photoId : photoId // ignore: cast_nullable_to_non_nullable
as String,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,childIds: null == childIds ? _self._childIds : childIds // ignore: cast_nullable_to_non_nullable
as List<String>,byMemberId: null == byMemberId ? _self.byMemberId : byMemberId // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

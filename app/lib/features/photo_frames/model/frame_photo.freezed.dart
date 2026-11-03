// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'frame_photo.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FramePhoto {

 String get id; String? get uploadedByUid; DateTime? get createdAt;
/// Create a copy of FramePhoto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FramePhotoCopyWith<FramePhoto> get copyWith => _$FramePhotoCopyWithImpl<FramePhoto>(this as FramePhoto, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FramePhoto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FramePhoto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.uploadedByUid, _this.uploadedByUid) || other.uploadedByUid == _this.uploadedByUid)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}


@override
int get hashCode {
  final _this = this as FramePhoto;
  return Object.hash(runtimeType,_this.id,_this.uploadedByUid,_this.createdAt);
}

@override
String toString() {
  final _this = this as FramePhoto;
  return 'FramePhoto(id: ${_this.id}, uploadedByUid: ${_this.uploadedByUid}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $FramePhotoCopyWith<$Res>  {
  factory $FramePhotoCopyWith(FramePhoto value, $Res Function(FramePhoto) _then) = _$FramePhotoCopyWithImpl;
@useResult
$Res call({
 String id, String? uploadedByUid, DateTime? createdAt
});




}
/// @nodoc
class _$FramePhotoCopyWithImpl<$Res>
    implements $FramePhotoCopyWith<$Res> {
  _$FramePhotoCopyWithImpl(this._self, this._then);

  final FramePhoto _self;
  final $Res Function(FramePhoto) _then;

/// Create a copy of FramePhoto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? uploadedByUid = freezed,Object? createdAt = freezed,}) {
  return _then(FramePhoto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,uploadedByUid: freezed == uploadedByUid ? _self.uploadedByUid : uploadedByUid // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [FramePhoto].
extension FramePhotoPatterns on FramePhoto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FramePhoto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FramePhoto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FramePhoto value)  $default,){
final _that = this;
switch (_that) {
case _FramePhoto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FramePhoto value)?  $default,){
final _that = this;
switch (_that) {
case _FramePhoto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? uploadedByUid,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FramePhoto() when $default != null:
return $default(_that.id,_that.uploadedByUid,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? uploadedByUid,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _FramePhoto():
return $default(_that.id,_that.uploadedByUid,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? uploadedByUid,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _FramePhoto() when $default != null:
return $default(_that.id,_that.uploadedByUid,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _FramePhoto implements FramePhoto {
  const _FramePhoto({required this.id, this.uploadedByUid, this.createdAt});
  

@override final  String id;
@override final  String? uploadedByUid;
@override final  DateTime? createdAt;

/// Create a copy of FramePhoto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FramePhotoCopyWith<_FramePhoto> get copyWith => __$FramePhotoCopyWithImpl<_FramePhoto>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FramePhoto&&(identical(other.id, id) || other.id == id)&&(identical(other.uploadedByUid, uploadedByUid) || other.uploadedByUid == uploadedByUid)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,uploadedByUid,createdAt);
}

@override
String toString() {
    return 'FramePhoto(id: $id, uploadedByUid: $uploadedByUid, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$FramePhotoCopyWith<$Res> implements $FramePhotoCopyWith<$Res> {
  factory _$FramePhotoCopyWith(_FramePhoto value, $Res Function(_FramePhoto) _then) = __$FramePhotoCopyWithImpl;
@override @useResult
$Res call({
 String id, String? uploadedByUid, DateTime? createdAt
});




}
/// @nodoc
class __$FramePhotoCopyWithImpl<$Res>
    implements _$FramePhotoCopyWith<$Res> {
  __$FramePhotoCopyWithImpl(this._self, this._then);

  final _FramePhoto _self;
  final $Res Function(_FramePhoto) _then;

/// Create a copy of FramePhoto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? uploadedByUid = freezed,Object? createdAt = freezed,}) {
  return _then(_FramePhoto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,uploadedByUid: freezed == uploadedByUid ? _self.uploadedByUid : uploadedByUid // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

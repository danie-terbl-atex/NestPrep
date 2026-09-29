// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'job_photo.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JobPhoto {

 String get photoId; int get width; int get height;
/// Create a copy of JobPhoto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JobPhotoCopyWith<JobPhoto> get copyWith => _$JobPhotoCopyWithImpl<JobPhoto>(this as JobPhoto, _$identity);

  /// Serializes this JobPhoto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as JobPhoto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JobPhoto&&(identical(other.photoId, _this.photoId) || other.photoId == _this.photoId)&&(identical(other.width, _this.width) || other.width == _this.width)&&(identical(other.height, _this.height) || other.height == _this.height));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as JobPhoto;
  return Object.hash(runtimeType,_this.photoId,_this.width,_this.height);
}

@override
String toString() {
  final _this = this as JobPhoto;
  return 'JobPhoto(photoId: ${_this.photoId}, width: ${_this.width}, height: ${_this.height})';
}


}

/// @nodoc
abstract mixin class $JobPhotoCopyWith<$Res>  {
  factory $JobPhotoCopyWith(JobPhoto value, $Res Function(JobPhoto) _then) = _$JobPhotoCopyWithImpl;
@useResult
$Res call({
 String photoId, int width, int height
});




}
/// @nodoc
class _$JobPhotoCopyWithImpl<$Res>
    implements $JobPhotoCopyWith<$Res> {
  _$JobPhotoCopyWithImpl(this._self, this._then);

  final JobPhoto _self;
  final $Res Function(JobPhoto) _then;

/// Create a copy of JobPhoto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? photoId = null,Object? width = null,Object? height = null,}) {
  return _then(JobPhoto(
photoId: null == photoId ? _self.photoId : photoId // ignore: cast_nullable_to_non_nullable
as String,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [JobPhoto].
extension JobPhotoPatterns on JobPhoto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JobPhoto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JobPhoto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JobPhoto value)  $default,){
final _that = this;
switch (_that) {
case _JobPhoto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JobPhoto value)?  $default,){
final _that = this;
switch (_that) {
case _JobPhoto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String photoId,  int width,  int height)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JobPhoto() when $default != null:
return $default(_that.photoId,_that.width,_that.height);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String photoId,  int width,  int height)  $default,) {final _that = this;
switch (_that) {
case _JobPhoto():
return $default(_that.photoId,_that.width,_that.height);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String photoId,  int width,  int height)?  $default,) {final _that = this;
switch (_that) {
case _JobPhoto() when $default != null:
return $default(_that.photoId,_that.width,_that.height);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JobPhoto extends JobPhoto {
  const _JobPhoto({required this.photoId, required this.width, required this.height}): super._();
  factory _JobPhoto.fromJson(Map<String, dynamic> json) => _$JobPhotoFromJson(json);

@override final  String photoId;
@override final  int width;
@override final  int height;

/// Create a copy of JobPhoto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JobPhotoCopyWith<_JobPhoto> get copyWith => __$JobPhotoCopyWithImpl<_JobPhoto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JobPhotoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _JobPhoto&&(identical(other.photoId, photoId) || other.photoId == photoId)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,photoId,width,height);
}

@override
String toString() {
    return 'JobPhoto(photoId: $photoId, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class _$JobPhotoCopyWith<$Res> implements $JobPhotoCopyWith<$Res> {
  factory _$JobPhotoCopyWith(_JobPhoto value, $Res Function(_JobPhoto) _then) = __$JobPhotoCopyWithImpl;
@override @useResult
$Res call({
 String photoId, int width, int height
});




}
/// @nodoc
class __$JobPhotoCopyWithImpl<$Res>
    implements _$JobPhotoCopyWith<$Res> {
  __$JobPhotoCopyWithImpl(this._self, this._then);

  final _JobPhoto _self;
  final $Res Function(_JobPhoto) _then;

/// Create a copy of JobPhoto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? photoId = null,Object? width = null,Object? height = null,}) {
  return _then(_JobPhoto(
photoId: null == photoId ? _self.photoId : photoId // ignore: cast_nullable_to_non_nullable
as String,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

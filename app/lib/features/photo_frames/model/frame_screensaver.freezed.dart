// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'frame_screensaver.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FrameScreensaver {

 int get idleMinutes; int get secondsPerPhoto;
/// Create a copy of FrameScreensaver
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FrameScreensaverCopyWith<FrameScreensaver> get copyWith => _$FrameScreensaverCopyWithImpl<FrameScreensaver>(this as FrameScreensaver, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FrameScreensaver;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FrameScreensaver&&(identical(other.idleMinutes, _this.idleMinutes) || other.idleMinutes == _this.idleMinutes)&&(identical(other.secondsPerPhoto, _this.secondsPerPhoto) || other.secondsPerPhoto == _this.secondsPerPhoto));
}


@override
int get hashCode {
  final _this = this as FrameScreensaver;
  return Object.hash(runtimeType,_this.idleMinutes,_this.secondsPerPhoto);
}

@override
String toString() {
  final _this = this as FrameScreensaver;
  return 'FrameScreensaver(idleMinutes: ${_this.idleMinutes}, secondsPerPhoto: ${_this.secondsPerPhoto})';
}


}

/// @nodoc
abstract mixin class $FrameScreensaverCopyWith<$Res>  {
  factory $FrameScreensaverCopyWith(FrameScreensaver value, $Res Function(FrameScreensaver) _then) = _$FrameScreensaverCopyWithImpl;
@useResult
$Res call({
 int idleMinutes, int secondsPerPhoto
});




}
/// @nodoc
class _$FrameScreensaverCopyWithImpl<$Res>
    implements $FrameScreensaverCopyWith<$Res> {
  _$FrameScreensaverCopyWithImpl(this._self, this._then);

  final FrameScreensaver _self;
  final $Res Function(FrameScreensaver) _then;

/// Create a copy of FrameScreensaver
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? idleMinutes = null,Object? secondsPerPhoto = null,}) {
  return _then(FrameScreensaver(
idleMinutes: null == idleMinutes ? _self.idleMinutes : idleMinutes // ignore: cast_nullable_to_non_nullable
as int,secondsPerPhoto: null == secondsPerPhoto ? _self.secondsPerPhoto : secondsPerPhoto // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FrameScreensaver].
extension FrameScreensaverPatterns on FrameScreensaver {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FrameScreensaver value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FrameScreensaver() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FrameScreensaver value)  $default,){
final _that = this;
switch (_that) {
case _FrameScreensaver():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FrameScreensaver value)?  $default,){
final _that = this;
switch (_that) {
case _FrameScreensaver() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int idleMinutes,  int secondsPerPhoto)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FrameScreensaver() when $default != null:
return $default(_that.idleMinutes,_that.secondsPerPhoto);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int idleMinutes,  int secondsPerPhoto)  $default,) {final _that = this;
switch (_that) {
case _FrameScreensaver():
return $default(_that.idleMinutes,_that.secondsPerPhoto);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int idleMinutes,  int secondsPerPhoto)?  $default,) {final _that = this;
switch (_that) {
case _FrameScreensaver() when $default != null:
return $default(_that.idleMinutes,_that.secondsPerPhoto);case _:
  return null;

}
}

}

/// @nodoc


class _FrameScreensaver extends FrameScreensaver {
  const _FrameScreensaver({this.idleMinutes = 0, this.secondsPerPhoto = FrameScreensaver.defaultSecondsPerPhoto}): super._();
  

@override@JsonKey() final  int idleMinutes;
@override@JsonKey() final  int secondsPerPhoto;

/// Create a copy of FrameScreensaver
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FrameScreensaverCopyWith<_FrameScreensaver> get copyWith => __$FrameScreensaverCopyWithImpl<_FrameScreensaver>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FrameScreensaver&&(identical(other.idleMinutes, idleMinutes) || other.idleMinutes == idleMinutes)&&(identical(other.secondsPerPhoto, secondsPerPhoto) || other.secondsPerPhoto == secondsPerPhoto));
}


@override
int get hashCode {
    return Object.hash(runtimeType,idleMinutes,secondsPerPhoto);
}

@override
String toString() {
    return 'FrameScreensaver(idleMinutes: $idleMinutes, secondsPerPhoto: $secondsPerPhoto)';
}


}

/// @nodoc
abstract mixin class _$FrameScreensaverCopyWith<$Res> implements $FrameScreensaverCopyWith<$Res> {
  factory _$FrameScreensaverCopyWith(_FrameScreensaver value, $Res Function(_FrameScreensaver) _then) = __$FrameScreensaverCopyWithImpl;
@override @useResult
$Res call({
 int idleMinutes, int secondsPerPhoto
});




}
/// @nodoc
class __$FrameScreensaverCopyWithImpl<$Res>
    implements _$FrameScreensaverCopyWith<$Res> {
  __$FrameScreensaverCopyWithImpl(this._self, this._then);

  final _FrameScreensaver _self;
  final $Res Function(_FrameScreensaver) _then;

/// Create a copy of FrameScreensaver
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? idleMinutes = null,Object? secondsPerPhoto = null,}) {
  return _then(_FrameScreensaver(
idleMinutes: null == idleMinutes ? _self.idleMinutes : idleMinutes // ignore: cast_nullable_to_non_nullable
as int,secondsPerPhoto: null == secondsPerPhoto ? _self.secondsPerPhoto : secondsPerPhoto // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

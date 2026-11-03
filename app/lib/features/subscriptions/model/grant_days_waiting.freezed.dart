// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'grant_days_waiting.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GrantDaysWaiting {

 int get referral; int get frame; int get code;
/// Create a copy of GrantDaysWaiting
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GrantDaysWaitingCopyWith<GrantDaysWaiting> get copyWith => _$GrantDaysWaitingCopyWithImpl<GrantDaysWaiting>(this as GrantDaysWaiting, _$identity);

  /// Serializes this GrantDaysWaiting to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GrantDaysWaiting;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GrantDaysWaiting&&(identical(other.referral, _this.referral) || other.referral == _this.referral)&&(identical(other.frame, _this.frame) || other.frame == _this.frame)&&(identical(other.code, _this.code) || other.code == _this.code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GrantDaysWaiting;
  return Object.hash(runtimeType,_this.referral,_this.frame,_this.code);
}

@override
String toString() {
  final _this = this as GrantDaysWaiting;
  return 'GrantDaysWaiting(referral: ${_this.referral}, frame: ${_this.frame}, code: ${_this.code})';
}


}

/// @nodoc
abstract mixin class $GrantDaysWaitingCopyWith<$Res>  {
  factory $GrantDaysWaitingCopyWith(GrantDaysWaiting value, $Res Function(GrantDaysWaiting) _then) = _$GrantDaysWaitingCopyWithImpl;
@useResult
$Res call({
 int referral, int frame, int code
});




}
/// @nodoc
class _$GrantDaysWaitingCopyWithImpl<$Res>
    implements $GrantDaysWaitingCopyWith<$Res> {
  _$GrantDaysWaitingCopyWithImpl(this._self, this._then);

  final GrantDaysWaiting _self;
  final $Res Function(GrantDaysWaiting) _then;

/// Create a copy of GrantDaysWaiting
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? referral = null,Object? frame = null,Object? code = null,}) {
  return _then(GrantDaysWaiting(
referral: null == referral ? _self.referral : referral // ignore: cast_nullable_to_non_nullable
as int,frame: null == frame ? _self.frame : frame // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [GrantDaysWaiting].
extension GrantDaysWaitingPatterns on GrantDaysWaiting {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GrantDaysWaiting value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GrantDaysWaiting() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GrantDaysWaiting value)  $default,){
final _that = this;
switch (_that) {
case _GrantDaysWaiting():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GrantDaysWaiting value)?  $default,){
final _that = this;
switch (_that) {
case _GrantDaysWaiting() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int referral,  int frame,  int code)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GrantDaysWaiting() when $default != null:
return $default(_that.referral,_that.frame,_that.code);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int referral,  int frame,  int code)  $default,) {final _that = this;
switch (_that) {
case _GrantDaysWaiting():
return $default(_that.referral,_that.frame,_that.code);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int referral,  int frame,  int code)?  $default,) {final _that = this;
switch (_that) {
case _GrantDaysWaiting() when $default != null:
return $default(_that.referral,_that.frame,_that.code);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GrantDaysWaiting extends GrantDaysWaiting {
  const _GrantDaysWaiting({this.referral = 0, this.frame = 0, this.code = 0}): super._();
  factory _GrantDaysWaiting.fromJson(Map<String, dynamic> json) => _$GrantDaysWaitingFromJson(json);

@override@JsonKey() final  int referral;
@override@JsonKey() final  int frame;
@override@JsonKey() final  int code;

/// Create a copy of GrantDaysWaiting
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GrantDaysWaitingCopyWith<_GrantDaysWaiting> get copyWith => __$GrantDaysWaitingCopyWithImpl<_GrantDaysWaiting>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GrantDaysWaitingToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GrantDaysWaiting&&(identical(other.referral, referral) || other.referral == referral)&&(identical(other.frame, frame) || other.frame == frame)&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,referral,frame,code);
}

@override
String toString() {
    return 'GrantDaysWaiting(referral: $referral, frame: $frame, code: $code)';
}


}

/// @nodoc
abstract mixin class _$GrantDaysWaitingCopyWith<$Res> implements $GrantDaysWaitingCopyWith<$Res> {
  factory _$GrantDaysWaitingCopyWith(_GrantDaysWaiting value, $Res Function(_GrantDaysWaiting) _then) = __$GrantDaysWaitingCopyWithImpl;
@override @useResult
$Res call({
 int referral, int frame, int code
});




}
/// @nodoc
class __$GrantDaysWaitingCopyWithImpl<$Res>
    implements _$GrantDaysWaitingCopyWith<$Res> {
  __$GrantDaysWaitingCopyWithImpl(this._self, this._then);

  final _GrantDaysWaiting _self;
  final $Res Function(_GrantDaysWaiting) _then;

/// Create a copy of GrantDaysWaiting
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? referral = null,Object? frame = null,Object? code = null,}) {
  return _then(_GrantDaysWaiting(
referral: null == referral ? _self.referral : referral // ignore: cast_nullable_to_non_nullable
as int,frame: null == frame ? _self.frame : frame // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

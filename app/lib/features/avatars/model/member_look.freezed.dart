// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'member_look.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MemberLook {

 AvatarBase get base; int get stage; Map<AvatarSlot, String> get wear;
/// Create a copy of MemberLook
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberLookCopyWith<MemberLook> get copyWith => _$MemberLookCopyWithImpl<MemberLook>(this as MemberLook, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MemberLook;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberLook&&(identical(other.base, _this.base) || other.base == _this.base)&&(identical(other.stage, _this.stage) || other.stage == _this.stage)&&const DeepCollectionEquality().equals(other.wear, _this.wear));
}


@override
int get hashCode {
  final _this = this as MemberLook;
  return Object.hash(runtimeType,_this.base,_this.stage,const DeepCollectionEquality().hash(_this.wear));
}

@override
String toString() {
  final _this = this as MemberLook;
  return 'MemberLook(base: ${_this.base}, stage: ${_this.stage}, wear: ${_this.wear})';
}


}

/// @nodoc
abstract mixin class $MemberLookCopyWith<$Res>  {
  factory $MemberLookCopyWith(MemberLook value, $Res Function(MemberLook) _then) = _$MemberLookCopyWithImpl;
@useResult
$Res call({
 AvatarBase base, int stage, Map<AvatarSlot, String> wear
});




}
/// @nodoc
class _$MemberLookCopyWithImpl<$Res>
    implements $MemberLookCopyWith<$Res> {
  _$MemberLookCopyWithImpl(this._self, this._then);

  final MemberLook _self;
  final $Res Function(MemberLook) _then;

/// Create a copy of MemberLook
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? base = null,Object? stage = null,Object? wear = null,}) {
  return _then(MemberLook(
base: null == base ? _self.base : base // ignore: cast_nullable_to_non_nullable
as AvatarBase,stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as int,wear: null == wear ? _self.wear : wear // ignore: cast_nullable_to_non_nullable
as Map<AvatarSlot, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [MemberLook].
extension MemberLookPatterns on MemberLook {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemberLook value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemberLook() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemberLook value)  $default,){
final _that = this;
switch (_that) {
case _MemberLook():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemberLook value)?  $default,){
final _that = this;
switch (_that) {
case _MemberLook() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AvatarBase base,  int stage,  Map<AvatarSlot, String> wear)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemberLook() when $default != null:
return $default(_that.base,_that.stage,_that.wear);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AvatarBase base,  int stage,  Map<AvatarSlot, String> wear)  $default,) {final _that = this;
switch (_that) {
case _MemberLook():
return $default(_that.base,_that.stage,_that.wear);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AvatarBase base,  int stage,  Map<AvatarSlot, String> wear)?  $default,) {final _that = this;
switch (_that) {
case _MemberLook() when $default != null:
return $default(_that.base,_that.stage,_that.wear);case _:
  return null;

}
}

}

/// @nodoc


class _MemberLook extends MemberLook {
  const _MemberLook({this.base = const InitialBase(), this.stage = AvatarStage.egg,  Map<AvatarSlot, String> wear = const <AvatarSlot, String>{}}): _wear = wear,super._();
  

@override@JsonKey() final  AvatarBase base;
@override@JsonKey() final  int stage;
 final  Map<AvatarSlot, String> _wear;
@override@JsonKey() Map<AvatarSlot, String> get wear {
  if (_wear is EqualUnmodifiableMapView) return _wear;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_wear);
}


/// Create a copy of MemberLook
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberLookCopyWith<_MemberLook> get copyWith => __$MemberLookCopyWithImpl<_MemberLook>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemberLook&&(identical(other.base, base) || other.base == base)&&(identical(other.stage, stage) || other.stage == stage)&&const DeepCollectionEquality().equals(other.wear, _wear));
}


@override
int get hashCode {
    return Object.hash(runtimeType,base,stage,const DeepCollectionEquality().hash(_wear));
}

@override
String toString() {
    return 'MemberLook(base: $base, stage: $stage, wear: $wear)';
}


}

/// @nodoc
abstract mixin class _$MemberLookCopyWith<$Res> implements $MemberLookCopyWith<$Res> {
  factory _$MemberLookCopyWith(_MemberLook value, $Res Function(_MemberLook) _then) = __$MemberLookCopyWithImpl;
@override @useResult
$Res call({
 AvatarBase base, int stage, Map<AvatarSlot, String> wear
});




}
/// @nodoc
class __$MemberLookCopyWithImpl<$Res>
    implements _$MemberLookCopyWith<$Res> {
  __$MemberLookCopyWithImpl(this._self, this._then);

  final _MemberLook _self;
  final $Res Function(_MemberLook) _then;

/// Create a copy of MemberLook
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? base = null,Object? stage = null,Object? wear = null,}) {
  return _then(_MemberLook(
base: null == base ? _self.base : base // ignore: cast_nullable_to_non_nullable
as AvatarBase,stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as int,wear: null == wear ? _self._wear : wear // ignore: cast_nullable_to_non_nullable
as Map<AvatarSlot, String>,
  ));
}


}

// dart format on

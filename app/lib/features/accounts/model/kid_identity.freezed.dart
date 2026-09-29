// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kid_identity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$KidIdentity {

 String get householdId; String get memberId;
/// Create a copy of KidIdentity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KidIdentityCopyWith<KidIdentity> get copyWith => _$KidIdentityCopyWithImpl<KidIdentity>(this as KidIdentity, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as KidIdentity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KidIdentity&&(identical(other.householdId, _this.householdId) || other.householdId == _this.householdId)&&(identical(other.memberId, _this.memberId) || other.memberId == _this.memberId));
}


@override
int get hashCode {
  final _this = this as KidIdentity;
  return Object.hash(runtimeType,_this.householdId,_this.memberId);
}

@override
String toString() {
  final _this = this as KidIdentity;
  return 'KidIdentity(householdId: ${_this.householdId}, memberId: ${_this.memberId})';
}


}

/// @nodoc
abstract mixin class $KidIdentityCopyWith<$Res>  {
  factory $KidIdentityCopyWith(KidIdentity value, $Res Function(KidIdentity) _then) = _$KidIdentityCopyWithImpl;
@useResult
$Res call({
 String householdId, String memberId
});




}
/// @nodoc
class _$KidIdentityCopyWithImpl<$Res>
    implements $KidIdentityCopyWith<$Res> {
  _$KidIdentityCopyWithImpl(this._self, this._then);

  final KidIdentity _self;
  final $Res Function(KidIdentity) _then;

/// Create a copy of KidIdentity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? householdId = null,Object? memberId = null,}) {
  return _then(KidIdentity(
householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [KidIdentity].
extension KidIdentityPatterns on KidIdentity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KidIdentity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KidIdentity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KidIdentity value)  $default,){
final _that = this;
switch (_that) {
case _KidIdentity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KidIdentity value)?  $default,){
final _that = this;
switch (_that) {
case _KidIdentity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String householdId,  String memberId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KidIdentity() when $default != null:
return $default(_that.householdId,_that.memberId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String householdId,  String memberId)  $default,) {final _that = this;
switch (_that) {
case _KidIdentity():
return $default(_that.householdId,_that.memberId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String householdId,  String memberId)?  $default,) {final _that = this;
switch (_that) {
case _KidIdentity() when $default != null:
return $default(_that.householdId,_that.memberId);case _:
  return null;

}
}

}

/// @nodoc


class _KidIdentity implements KidIdentity {
  const _KidIdentity({required this.householdId, required this.memberId});
  

@override final  String householdId;
@override final  String memberId;

/// Create a copy of KidIdentity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KidIdentityCopyWith<_KidIdentity> get copyWith => __$KidIdentityCopyWithImpl<_KidIdentity>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _KidIdentity&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.memberId, memberId) || other.memberId == memberId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,householdId,memberId);
}

@override
String toString() {
    return 'KidIdentity(householdId: $householdId, memberId: $memberId)';
}


}

/// @nodoc
abstract mixin class _$KidIdentityCopyWith<$Res> implements $KidIdentityCopyWith<$Res> {
  factory _$KidIdentityCopyWith(_KidIdentity value, $Res Function(_KidIdentity) _then) = __$KidIdentityCopyWithImpl;
@override @useResult
$Res call({
 String householdId, String memberId
});




}
/// @nodoc
class __$KidIdentityCopyWithImpl<$Res>
    implements _$KidIdentityCopyWith<$Res> {
  __$KidIdentityCopyWithImpl(this._self, this._then);

  final _KidIdentity _self;
  final $Res Function(_KidIdentity) _then;

/// Create a copy of KidIdentity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? householdId = null,Object? memberId = null,}) {
  return _then(_KidIdentity(
householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

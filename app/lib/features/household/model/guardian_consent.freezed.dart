// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'guardian_consent.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GuardianConsent {

 String get byMemberId; int get version;@ServerTimestampConverter() DateTime? get at;
/// Create a copy of GuardianConsent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuardianConsentCopyWith<GuardianConsent> get copyWith => _$GuardianConsentCopyWithImpl<GuardianConsent>(this as GuardianConsent, _$identity);

  /// Serializes this GuardianConsent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GuardianConsent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuardianConsent&&(identical(other.byMemberId, _this.byMemberId) || other.byMemberId == _this.byMemberId)&&(identical(other.version, _this.version) || other.version == _this.version)&&(identical(other.at, _this.at) || other.at == _this.at));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GuardianConsent;
  return Object.hash(runtimeType,_this.byMemberId,_this.version,_this.at);
}

@override
String toString() {
  final _this = this as GuardianConsent;
  return 'GuardianConsent(byMemberId: ${_this.byMemberId}, version: ${_this.version}, at: ${_this.at})';
}


}

/// @nodoc
abstract mixin class $GuardianConsentCopyWith<$Res>  {
  factory $GuardianConsentCopyWith(GuardianConsent value, $Res Function(GuardianConsent) _then) = _$GuardianConsentCopyWithImpl;
@useResult
$Res call({
 String byMemberId, int version,@ServerTimestampConverter() DateTime? at
});




}
/// @nodoc
class _$GuardianConsentCopyWithImpl<$Res>
    implements $GuardianConsentCopyWith<$Res> {
  _$GuardianConsentCopyWithImpl(this._self, this._then);

  final GuardianConsent _self;
  final $Res Function(GuardianConsent) _then;

/// Create a copy of GuardianConsent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? byMemberId = null,Object? version = null,Object? at = freezed,}) {
  return _then(GuardianConsent(
byMemberId: null == byMemberId ? _self.byMemberId : byMemberId // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,at: freezed == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [GuardianConsent].
extension GuardianConsentPatterns on GuardianConsent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GuardianConsent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GuardianConsent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GuardianConsent value)  $default,){
final _that = this;
switch (_that) {
case _GuardianConsent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GuardianConsent value)?  $default,){
final _that = this;
switch (_that) {
case _GuardianConsent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String byMemberId,  int version, @ServerTimestampConverter()  DateTime? at)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GuardianConsent() when $default != null:
return $default(_that.byMemberId,_that.version,_that.at);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String byMemberId,  int version, @ServerTimestampConverter()  DateTime? at)  $default,) {final _that = this;
switch (_that) {
case _GuardianConsent():
return $default(_that.byMemberId,_that.version,_that.at);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String byMemberId,  int version, @ServerTimestampConverter()  DateTime? at)?  $default,) {final _that = this;
switch (_that) {
case _GuardianConsent() when $default != null:
return $default(_that.byMemberId,_that.version,_that.at);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GuardianConsent extends GuardianConsent {
  const _GuardianConsent({required this.byMemberId, required this.version, @ServerTimestampConverter() this.at}): super._();
  factory _GuardianConsent.fromJson(Map<String, dynamic> json) => _$GuardianConsentFromJson(json);

@override final  String byMemberId;
@override final  int version;
@override@ServerTimestampConverter() final  DateTime? at;

/// Create a copy of GuardianConsent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuardianConsentCopyWith<_GuardianConsent> get copyWith => __$GuardianConsentCopyWithImpl<_GuardianConsent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuardianConsentToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuardianConsent&&(identical(other.byMemberId, byMemberId) || other.byMemberId == byMemberId)&&(identical(other.version, version) || other.version == version)&&(identical(other.at, at) || other.at == at));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,byMemberId,version,at);
}

@override
String toString() {
    return 'GuardianConsent(byMemberId: $byMemberId, version: $version, at: $at)';
}


}

/// @nodoc
abstract mixin class _$GuardianConsentCopyWith<$Res> implements $GuardianConsentCopyWith<$Res> {
  factory _$GuardianConsentCopyWith(_GuardianConsent value, $Res Function(_GuardianConsent) _then) = __$GuardianConsentCopyWithImpl;
@override @useResult
$Res call({
 String byMemberId, int version,@ServerTimestampConverter() DateTime? at
});




}
/// @nodoc
class __$GuardianConsentCopyWithImpl<$Res>
    implements _$GuardianConsentCopyWith<$Res> {
  __$GuardianConsentCopyWithImpl(this._self, this._then);

  final _GuardianConsent _self;
  final $Res Function(_GuardianConsent) _then;

/// Create a copy of GuardianConsent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? byMemberId = null,Object? version = null,Object? at = freezed,}) {
  return _then(_GuardianConsent(
byMemberId: null == byMemberId ? _self.byMemberId : byMemberId // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,at: freezed == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

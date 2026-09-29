// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'legal_consent.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LegalConsent {

 int get termsVersion; int get privacyVersion;@ServerTimestampConverter() DateTime? get acceptedAt;
/// Create a copy of LegalConsent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LegalConsentCopyWith<LegalConsent> get copyWith => _$LegalConsentCopyWithImpl<LegalConsent>(this as LegalConsent, _$identity);

  /// Serializes this LegalConsent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LegalConsent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LegalConsent&&(identical(other.termsVersion, _this.termsVersion) || other.termsVersion == _this.termsVersion)&&(identical(other.privacyVersion, _this.privacyVersion) || other.privacyVersion == _this.privacyVersion)&&(identical(other.acceptedAt, _this.acceptedAt) || other.acceptedAt == _this.acceptedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LegalConsent;
  return Object.hash(runtimeType,_this.termsVersion,_this.privacyVersion,_this.acceptedAt);
}

@override
String toString() {
  final _this = this as LegalConsent;
  return 'LegalConsent(termsVersion: ${_this.termsVersion}, privacyVersion: ${_this.privacyVersion}, acceptedAt: ${_this.acceptedAt})';
}


}

/// @nodoc
abstract mixin class $LegalConsentCopyWith<$Res>  {
  factory $LegalConsentCopyWith(LegalConsent value, $Res Function(LegalConsent) _then) = _$LegalConsentCopyWithImpl;
@useResult
$Res call({
 int termsVersion, int privacyVersion,@ServerTimestampConverter() DateTime? acceptedAt
});




}
/// @nodoc
class _$LegalConsentCopyWithImpl<$Res>
    implements $LegalConsentCopyWith<$Res> {
  _$LegalConsentCopyWithImpl(this._self, this._then);

  final LegalConsent _self;
  final $Res Function(LegalConsent) _then;

/// Create a copy of LegalConsent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? termsVersion = null,Object? privacyVersion = null,Object? acceptedAt = freezed,}) {
  return _then(LegalConsent(
termsVersion: null == termsVersion ? _self.termsVersion : termsVersion // ignore: cast_nullable_to_non_nullable
as int,privacyVersion: null == privacyVersion ? _self.privacyVersion : privacyVersion // ignore: cast_nullable_to_non_nullable
as int,acceptedAt: freezed == acceptedAt ? _self.acceptedAt : acceptedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [LegalConsent].
extension LegalConsentPatterns on LegalConsent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LegalConsent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LegalConsent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LegalConsent value)  $default,){
final _that = this;
switch (_that) {
case _LegalConsent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LegalConsent value)?  $default,){
final _that = this;
switch (_that) {
case _LegalConsent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int termsVersion,  int privacyVersion, @ServerTimestampConverter()  DateTime? acceptedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LegalConsent() when $default != null:
return $default(_that.termsVersion,_that.privacyVersion,_that.acceptedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int termsVersion,  int privacyVersion, @ServerTimestampConverter()  DateTime? acceptedAt)  $default,) {final _that = this;
switch (_that) {
case _LegalConsent():
return $default(_that.termsVersion,_that.privacyVersion,_that.acceptedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int termsVersion,  int privacyVersion, @ServerTimestampConverter()  DateTime? acceptedAt)?  $default,) {final _that = this;
switch (_that) {
case _LegalConsent() when $default != null:
return $default(_that.termsVersion,_that.privacyVersion,_that.acceptedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LegalConsent extends LegalConsent {
  const _LegalConsent({required this.termsVersion, required this.privacyVersion, @ServerTimestampConverter() this.acceptedAt}): super._();
  factory _LegalConsent.fromJson(Map<String, dynamic> json) => _$LegalConsentFromJson(json);

@override final  int termsVersion;
@override final  int privacyVersion;
@override@ServerTimestampConverter() final  DateTime? acceptedAt;

/// Create a copy of LegalConsent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LegalConsentCopyWith<_LegalConsent> get copyWith => __$LegalConsentCopyWithImpl<_LegalConsent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LegalConsentToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LegalConsent&&(identical(other.termsVersion, termsVersion) || other.termsVersion == termsVersion)&&(identical(other.privacyVersion, privacyVersion) || other.privacyVersion == privacyVersion)&&(identical(other.acceptedAt, acceptedAt) || other.acceptedAt == acceptedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,termsVersion,privacyVersion,acceptedAt);
}

@override
String toString() {
    return 'LegalConsent(termsVersion: $termsVersion, privacyVersion: $privacyVersion, acceptedAt: $acceptedAt)';
}


}

/// @nodoc
abstract mixin class _$LegalConsentCopyWith<$Res> implements $LegalConsentCopyWith<$Res> {
  factory _$LegalConsentCopyWith(_LegalConsent value, $Res Function(_LegalConsent) _then) = __$LegalConsentCopyWithImpl;
@override @useResult
$Res call({
 int termsVersion, int privacyVersion,@ServerTimestampConverter() DateTime? acceptedAt
});




}
/// @nodoc
class __$LegalConsentCopyWithImpl<$Res>
    implements _$LegalConsentCopyWith<$Res> {
  __$LegalConsentCopyWithImpl(this._self, this._then);

  final _LegalConsent _self;
  final $Res Function(_LegalConsent) _then;

/// Create a copy of LegalConsent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? termsVersion = null,Object? privacyVersion = null,Object? acceptedAt = freezed,}) {
  return _then(_LegalConsent(
termsVersion: null == termsVersion ? _self.termsVersion : termsVersion // ignore: cast_nullable_to_non_nullable
as int,privacyVersion: null == privacyVersion ? _self.privacyVersion : privacyVersion // ignore: cast_nullable_to_non_nullable
as int,acceptedAt: freezed == acceptedAt ? _self.acceptedAt : acceptedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'helper_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HelperProfile {

/// The member profile it belongs to.
@JsonKey(includeToJson: false) String get id;@HelperLanguageConverter() HelperLanguage get language;/// Who chose it — she, or family on her behalf.
 String get updatedBy;@ServerTimestampConverter() DateTime? get updatedAt;
/// Create a copy of HelperProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HelperProfileCopyWith<HelperProfile> get copyWith => _$HelperProfileCopyWithImpl<HelperProfile>(this as HelperProfile, _$identity);

  /// Serializes this HelperProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HelperProfile;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HelperProfile&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.updatedBy, _this.updatedBy) || other.updatedBy == _this.updatedBy)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HelperProfile;
  return Object.hash(runtimeType,_this.id,_this.language,_this.updatedBy,_this.updatedAt);
}

@override
String toString() {
  final _this = this as HelperProfile;
  return 'HelperProfile(id: ${_this.id}, language: ${_this.language}, updatedBy: ${_this.updatedBy}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $HelperProfileCopyWith<$Res>  {
  factory $HelperProfileCopyWith(HelperProfile value, $Res Function(HelperProfile) _then) = _$HelperProfileCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id,@HelperLanguageConverter() HelperLanguage language, String updatedBy,@ServerTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$HelperProfileCopyWithImpl<$Res>
    implements $HelperProfileCopyWith<$Res> {
  _$HelperProfileCopyWithImpl(this._self, this._then);

  final HelperProfile _self;
  final $Res Function(HelperProfile) _then;

/// Create a copy of HelperProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? language = null,Object? updatedBy = null,Object? updatedAt = freezed,}) {
  return _then(HelperProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as HelperLanguage,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [HelperProfile].
extension HelperProfilePatterns on HelperProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HelperProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HelperProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HelperProfile value)  $default,){
final _that = this;
switch (_that) {
case _HelperProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HelperProfile value)?  $default,){
final _that = this;
switch (_that) {
case _HelperProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id, @HelperLanguageConverter()  HelperLanguage language,  String updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HelperProfile() when $default != null:
return $default(_that.id,_that.language,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id, @HelperLanguageConverter()  HelperLanguage language,  String updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _HelperProfile():
return $default(_that.id,_that.language,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id, @HelperLanguageConverter()  HelperLanguage language,  String updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _HelperProfile() when $default != null:
return $default(_that.id,_that.language,_that.updatedBy,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HelperProfile implements HelperProfile {
  const _HelperProfile({@JsonKey(includeToJson: false) required this.id, @HelperLanguageConverter() required this.language, required this.updatedBy, @ServerTimestampConverter() this.updatedAt});
  factory _HelperProfile.fromJson(Map<String, dynamic> json) => _$HelperProfileFromJson(json);

/// The member profile it belongs to.
@override@JsonKey(includeToJson: false) final  String id;
@override@HelperLanguageConverter() final  HelperLanguage language;
/// Who chose it — she, or family on her behalf.
@override final  String updatedBy;
@override@ServerTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of HelperProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HelperProfileCopyWith<_HelperProfile> get copyWith => __$HelperProfileCopyWithImpl<_HelperProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HelperProfileToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HelperProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.language, language) || other.language == language)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,language,updatedBy,updatedAt);
}

@override
String toString() {
    return 'HelperProfile(id: $id, language: $language, updatedBy: $updatedBy, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$HelperProfileCopyWith<$Res> implements $HelperProfileCopyWith<$Res> {
  factory _$HelperProfileCopyWith(_HelperProfile value, $Res Function(_HelperProfile) _then) = __$HelperProfileCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id,@HelperLanguageConverter() HelperLanguage language, String updatedBy,@ServerTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$HelperProfileCopyWithImpl<$Res>
    implements _$HelperProfileCopyWith<$Res> {
  __$HelperProfileCopyWithImpl(this._self, this._then);

  final _HelperProfile _self;
  final $Res Function(_HelperProfile) _then;

/// Create a copy of HelperProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? language = null,Object? updatedBy = null,Object? updatedAt = freezed,}) {
  return _then(_HelperProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as HelperLanguage,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

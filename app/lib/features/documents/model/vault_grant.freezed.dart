// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vault_grant.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VaultGrant {

/// The grantee's uid — the document id.
@JsonKey(includeToJson: false) String get id;/// The grantee's member profile.
 String get memberId;/// The member who granted it.
 String get grantedBy;@ServerTimestampConverter() DateTime? get grantedAt;
/// Create a copy of VaultGrant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VaultGrantCopyWith<VaultGrant> get copyWith => _$VaultGrantCopyWithImpl<VaultGrant>(this as VaultGrant, _$identity);

  /// Serializes this VaultGrant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as VaultGrant;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VaultGrant&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.memberId, _this.memberId) || other.memberId == _this.memberId)&&(identical(other.grantedBy, _this.grantedBy) || other.grantedBy == _this.grantedBy)&&(identical(other.grantedAt, _this.grantedAt) || other.grantedAt == _this.grantedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as VaultGrant;
  return Object.hash(runtimeType,_this.id,_this.memberId,_this.grantedBy,_this.grantedAt);
}

@override
String toString() {
  final _this = this as VaultGrant;
  return 'VaultGrant(id: ${_this.id}, memberId: ${_this.memberId}, grantedBy: ${_this.grantedBy}, grantedAt: ${_this.grantedAt})';
}


}

/// @nodoc
abstract mixin class $VaultGrantCopyWith<$Res>  {
  factory $VaultGrantCopyWith(VaultGrant value, $Res Function(VaultGrant) _then) = _$VaultGrantCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String memberId, String grantedBy,@ServerTimestampConverter() DateTime? grantedAt
});




}
/// @nodoc
class _$VaultGrantCopyWithImpl<$Res>
    implements $VaultGrantCopyWith<$Res> {
  _$VaultGrantCopyWithImpl(this._self, this._then);

  final VaultGrant _self;
  final $Res Function(VaultGrant) _then;

/// Create a copy of VaultGrant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? memberId = null,Object? grantedBy = null,Object? grantedAt = freezed,}) {
  return _then(VaultGrant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,grantedBy: null == grantedBy ? _self.grantedBy : grantedBy // ignore: cast_nullable_to_non_nullable
as String,grantedAt: freezed == grantedAt ? _self.grantedAt : grantedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [VaultGrant].
extension VaultGrantPatterns on VaultGrant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VaultGrant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VaultGrant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VaultGrant value)  $default,){
final _that = this;
switch (_that) {
case _VaultGrant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VaultGrant value)?  $default,){
final _that = this;
switch (_that) {
case _VaultGrant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String memberId,  String grantedBy, @ServerTimestampConverter()  DateTime? grantedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VaultGrant() when $default != null:
return $default(_that.id,_that.memberId,_that.grantedBy,_that.grantedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String memberId,  String grantedBy, @ServerTimestampConverter()  DateTime? grantedAt)  $default,) {final _that = this;
switch (_that) {
case _VaultGrant():
return $default(_that.id,_that.memberId,_that.grantedBy,_that.grantedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String memberId,  String grantedBy, @ServerTimestampConverter()  DateTime? grantedAt)?  $default,) {final _that = this;
switch (_that) {
case _VaultGrant() when $default != null:
return $default(_that.id,_that.memberId,_that.grantedBy,_that.grantedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VaultGrant extends VaultGrant {
  const _VaultGrant({@JsonKey(includeToJson: false) required this.id, required this.memberId, required this.grantedBy, @ServerTimestampConverter() this.grantedAt}): super._();
  factory _VaultGrant.fromJson(Map<String, dynamic> json) => _$VaultGrantFromJson(json);

/// The grantee's uid — the document id.
@override@JsonKey(includeToJson: false) final  String id;
/// The grantee's member profile.
@override final  String memberId;
/// The member who granted it.
@override final  String grantedBy;
@override@ServerTimestampConverter() final  DateTime? grantedAt;

/// Create a copy of VaultGrant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VaultGrantCopyWith<_VaultGrant> get copyWith => __$VaultGrantCopyWithImpl<_VaultGrant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VaultGrantToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _VaultGrant&&(identical(other.id, id) || other.id == id)&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.grantedBy, grantedBy) || other.grantedBy == grantedBy)&&(identical(other.grantedAt, grantedAt) || other.grantedAt == grantedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,memberId,grantedBy,grantedAt);
}

@override
String toString() {
    return 'VaultGrant(id: $id, memberId: $memberId, grantedBy: $grantedBy, grantedAt: $grantedAt)';
}


}

/// @nodoc
abstract mixin class _$VaultGrantCopyWith<$Res> implements $VaultGrantCopyWith<$Res> {
  factory _$VaultGrantCopyWith(_VaultGrant value, $Res Function(_VaultGrant) _then) = __$VaultGrantCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String memberId, String grantedBy,@ServerTimestampConverter() DateTime? grantedAt
});




}
/// @nodoc
class __$VaultGrantCopyWithImpl<$Res>
    implements _$VaultGrantCopyWith<$Res> {
  __$VaultGrantCopyWithImpl(this._self, this._then);

  final _VaultGrant _self;
  final $Res Function(_VaultGrant) _then;

/// Create a copy of VaultGrant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? memberId = null,Object? grantedBy = null,Object? grantedAt = freezed,}) {
  return _then(_VaultGrant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,grantedBy: null == grantedBy ? _self.grantedBy : grantedBy // ignore: cast_nullable_to_non_nullable
as String,grantedAt: freezed == grantedAt ? _self.grantedAt : grantedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

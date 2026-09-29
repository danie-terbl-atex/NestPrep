// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'offline_copy.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OfflineCopy {

 String get householdId;/// The vault it came from, or null for a household document.
 String? get ownerMemberId; String get documentId; String get name; String get contentType; int get sizeBytes; DateTime get savedAt;
/// Create a copy of OfflineCopy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OfflineCopyCopyWith<OfflineCopy> get copyWith => _$OfflineCopyCopyWithImpl<OfflineCopy>(this as OfflineCopy, _$identity);

  /// Serializes this OfflineCopy to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OfflineCopy;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OfflineCopy&&(identical(other.householdId, _this.householdId) || other.householdId == _this.householdId)&&(identical(other.ownerMemberId, _this.ownerMemberId) || other.ownerMemberId == _this.ownerMemberId)&&(identical(other.documentId, _this.documentId) || other.documentId == _this.documentId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.contentType, _this.contentType) || other.contentType == _this.contentType)&&(identical(other.sizeBytes, _this.sizeBytes) || other.sizeBytes == _this.sizeBytes)&&(identical(other.savedAt, _this.savedAt) || other.savedAt == _this.savedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OfflineCopy;
  return Object.hash(runtimeType,_this.householdId,_this.ownerMemberId,_this.documentId,_this.name,_this.contentType,_this.sizeBytes,_this.savedAt);
}

@override
String toString() {
  final _this = this as OfflineCopy;
  return 'OfflineCopy(householdId: ${_this.householdId}, ownerMemberId: ${_this.ownerMemberId}, documentId: ${_this.documentId}, name: ${_this.name}, contentType: ${_this.contentType}, sizeBytes: ${_this.sizeBytes}, savedAt: ${_this.savedAt})';
}


}

/// @nodoc
abstract mixin class $OfflineCopyCopyWith<$Res>  {
  factory $OfflineCopyCopyWith(OfflineCopy value, $Res Function(OfflineCopy) _then) = _$OfflineCopyCopyWithImpl;
@useResult
$Res call({
 String householdId, String? ownerMemberId, String documentId, String name, String contentType, int sizeBytes, DateTime savedAt
});




}
/// @nodoc
class _$OfflineCopyCopyWithImpl<$Res>
    implements $OfflineCopyCopyWith<$Res> {
  _$OfflineCopyCopyWithImpl(this._self, this._then);

  final OfflineCopy _self;
  final $Res Function(OfflineCopy) _then;

/// Create a copy of OfflineCopy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? householdId = null,Object? ownerMemberId = freezed,Object? documentId = null,Object? name = null,Object? contentType = null,Object? sizeBytes = null,Object? savedAt = null,}) {
  return _then(OfflineCopy(
householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,ownerMemberId: freezed == ownerMemberId ? _self.ownerMemberId : ownerMemberId // ignore: cast_nullable_to_non_nullable
as String?,documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,savedAt: null == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [OfflineCopy].
extension OfflineCopyPatterns on OfflineCopy {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OfflineCopy value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OfflineCopy() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OfflineCopy value)  $default,){
final _that = this;
switch (_that) {
case _OfflineCopy():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OfflineCopy value)?  $default,){
final _that = this;
switch (_that) {
case _OfflineCopy() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String householdId,  String? ownerMemberId,  String documentId,  String name,  String contentType,  int sizeBytes,  DateTime savedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OfflineCopy() when $default != null:
return $default(_that.householdId,_that.ownerMemberId,_that.documentId,_that.name,_that.contentType,_that.sizeBytes,_that.savedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String householdId,  String? ownerMemberId,  String documentId,  String name,  String contentType,  int sizeBytes,  DateTime savedAt)  $default,) {final _that = this;
switch (_that) {
case _OfflineCopy():
return $default(_that.householdId,_that.ownerMemberId,_that.documentId,_that.name,_that.contentType,_that.sizeBytes,_that.savedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String householdId,  String? ownerMemberId,  String documentId,  String name,  String contentType,  int sizeBytes,  DateTime savedAt)?  $default,) {final _that = this;
switch (_that) {
case _OfflineCopy() when $default != null:
return $default(_that.householdId,_that.ownerMemberId,_that.documentId,_that.name,_that.contentType,_that.sizeBytes,_that.savedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OfflineCopy extends OfflineCopy {
  const _OfflineCopy({required this.householdId, this.ownerMemberId, required this.documentId, required this.name, required this.contentType, required this.sizeBytes, required this.savedAt}): super._();
  factory _OfflineCopy.fromJson(Map<String, dynamic> json) => _$OfflineCopyFromJson(json);

@override final  String householdId;
/// The vault it came from, or null for a household document.
@override final  String? ownerMemberId;
@override final  String documentId;
@override final  String name;
@override final  String contentType;
@override final  int sizeBytes;
@override final  DateTime savedAt;

/// Create a copy of OfflineCopy
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OfflineCopyCopyWith<_OfflineCopy> get copyWith => __$OfflineCopyCopyWithImpl<_OfflineCopy>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OfflineCopyToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OfflineCopy&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.ownerMemberId, ownerMemberId) || other.ownerMemberId == ownerMemberId)&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.name, name) || other.name == name)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,householdId,ownerMemberId,documentId,name,contentType,sizeBytes,savedAt);
}

@override
String toString() {
    return 'OfflineCopy(householdId: $householdId, ownerMemberId: $ownerMemberId, documentId: $documentId, name: $name, contentType: $contentType, sizeBytes: $sizeBytes, savedAt: $savedAt)';
}


}

/// @nodoc
abstract mixin class _$OfflineCopyCopyWith<$Res> implements $OfflineCopyCopyWith<$Res> {
  factory _$OfflineCopyCopyWith(_OfflineCopy value, $Res Function(_OfflineCopy) _then) = __$OfflineCopyCopyWithImpl;
@override @useResult
$Res call({
 String householdId, String? ownerMemberId, String documentId, String name, String contentType, int sizeBytes, DateTime savedAt
});




}
/// @nodoc
class __$OfflineCopyCopyWithImpl<$Res>
    implements _$OfflineCopyCopyWith<$Res> {
  __$OfflineCopyCopyWithImpl(this._self, this._then);

  final _OfflineCopy _self;
  final $Res Function(_OfflineCopy) _then;

/// Create a copy of OfflineCopy
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? householdId = null,Object? ownerMemberId = freezed,Object? documentId = null,Object? name = null,Object? contentType = null,Object? sizeBytes = null,Object? savedAt = null,}) {
  return _then(_OfflineCopy(
householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,ownerMemberId: freezed == ownerMemberId ? _self.ownerMemberId : ownerMemberId // ignore: cast_nullable_to_non_nullable
as String?,documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,savedAt: null == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on

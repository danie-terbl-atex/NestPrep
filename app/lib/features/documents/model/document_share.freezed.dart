// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document_share.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DocumentShare {

@JsonKey(includeToJson: false) String get id;/// `household` for a folder's document, `vault` for a person's.
 String get scope;/// The vault it came from, or null for a household document.
 String? get ownerMemberId; String get documentId;/// The document's name when the link was made.
 String get documentName; String get contentType;/// The member who made it, or null for an account with no profile.
 String? get createdBy; String get createdByUid;@NullableTimestampConverter() DateTime? get createdAt;/// When it stops working at the latest (`ENG-21`).
@InstantConverter() DateTime get expiresAt;/// The nanny-hub shift it ends with, if it was made for one.
 String? get shiftId; bool get hasPin; String get status; int get openCount;@NullableTimestampConverter() DateTime? get lastOpenedAt;
/// Create a copy of DocumentShare
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentShareCopyWith<DocumentShare> get copyWith => _$DocumentShareCopyWithImpl<DocumentShare>(this as DocumentShare, _$identity);

  /// Serializes this DocumentShare to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DocumentShare;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentShare&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.scope, _this.scope) || other.scope == _this.scope)&&(identical(other.ownerMemberId, _this.ownerMemberId) || other.ownerMemberId == _this.ownerMemberId)&&(identical(other.documentId, _this.documentId) || other.documentId == _this.documentId)&&(identical(other.documentName, _this.documentName) || other.documentName == _this.documentName)&&(identical(other.contentType, _this.contentType) || other.contentType == _this.contentType)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.createdByUid, _this.createdByUid) || other.createdByUid == _this.createdByUid)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.shiftId, _this.shiftId) || other.shiftId == _this.shiftId)&&(identical(other.hasPin, _this.hasPin) || other.hasPin == _this.hasPin)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.openCount, _this.openCount) || other.openCount == _this.openCount)&&(identical(other.lastOpenedAt, _this.lastOpenedAt) || other.lastOpenedAt == _this.lastOpenedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DocumentShare;
  return Object.hash(runtimeType,_this.id,_this.scope,_this.ownerMemberId,_this.documentId,_this.documentName,_this.contentType,_this.createdBy,_this.createdByUid,_this.createdAt,_this.expiresAt,_this.shiftId,_this.hasPin,_this.status,_this.openCount,_this.lastOpenedAt);
}

@override
String toString() {
  final _this = this as DocumentShare;
  return 'DocumentShare(id: ${_this.id}, scope: ${_this.scope}, ownerMemberId: ${_this.ownerMemberId}, documentId: ${_this.documentId}, documentName: ${_this.documentName}, contentType: ${_this.contentType}, createdBy: ${_this.createdBy}, createdByUid: ${_this.createdByUid}, createdAt: ${_this.createdAt}, expiresAt: ${_this.expiresAt}, shiftId: ${_this.shiftId}, hasPin: ${_this.hasPin}, status: ${_this.status}, openCount: ${_this.openCount}, lastOpenedAt: ${_this.lastOpenedAt})';
}


}

/// @nodoc
abstract mixin class $DocumentShareCopyWith<$Res>  {
  factory $DocumentShareCopyWith(DocumentShare value, $Res Function(DocumentShare) _then) = _$DocumentShareCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String scope, String? ownerMemberId, String documentId, String documentName, String contentType, String? createdBy, String createdByUid,@NullableTimestampConverter() DateTime? createdAt,@InstantConverter() DateTime expiresAt, String? shiftId, bool hasPin, String status, int openCount,@NullableTimestampConverter() DateTime? lastOpenedAt
});




}
/// @nodoc
class _$DocumentShareCopyWithImpl<$Res>
    implements $DocumentShareCopyWith<$Res> {
  _$DocumentShareCopyWithImpl(this._self, this._then);

  final DocumentShare _self;
  final $Res Function(DocumentShare) _then;

/// Create a copy of DocumentShare
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? scope = null,Object? ownerMemberId = freezed,Object? documentId = null,Object? documentName = null,Object? contentType = null,Object? createdBy = freezed,Object? createdByUid = null,Object? createdAt = freezed,Object? expiresAt = null,Object? shiftId = freezed,Object? hasPin = null,Object? status = null,Object? openCount = null,Object? lastOpenedAt = freezed,}) {
  return _then(DocumentShare(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as String,ownerMemberId: freezed == ownerMemberId ? _self.ownerMemberId : ownerMemberId // ignore: cast_nullable_to_non_nullable
as String?,documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,documentName: null == documentName ? _self.documentName : documentName // ignore: cast_nullable_to_non_nullable
as String,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdByUid: null == createdByUid ? _self.createdByUid : createdByUid // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,shiftId: freezed == shiftId ? _self.shiftId : shiftId // ignore: cast_nullable_to_non_nullable
as String?,hasPin: null == hasPin ? _self.hasPin : hasPin // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,openCount: null == openCount ? _self.openCount : openCount // ignore: cast_nullable_to_non_nullable
as int,lastOpenedAt: freezed == lastOpenedAt ? _self.lastOpenedAt : lastOpenedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentShare].
extension DocumentSharePatterns on DocumentShare {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentShare value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentShare() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentShare value)  $default,){
final _that = this;
switch (_that) {
case _DocumentShare():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentShare value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentShare() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String scope,  String? ownerMemberId,  String documentId,  String documentName,  String contentType,  String? createdBy,  String createdByUid, @NullableTimestampConverter()  DateTime? createdAt, @InstantConverter()  DateTime expiresAt,  String? shiftId,  bool hasPin,  String status,  int openCount, @NullableTimestampConverter()  DateTime? lastOpenedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentShare() when $default != null:
return $default(_that.id,_that.scope,_that.ownerMemberId,_that.documentId,_that.documentName,_that.contentType,_that.createdBy,_that.createdByUid,_that.createdAt,_that.expiresAt,_that.shiftId,_that.hasPin,_that.status,_that.openCount,_that.lastOpenedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String scope,  String? ownerMemberId,  String documentId,  String documentName,  String contentType,  String? createdBy,  String createdByUid, @NullableTimestampConverter()  DateTime? createdAt, @InstantConverter()  DateTime expiresAt,  String? shiftId,  bool hasPin,  String status,  int openCount, @NullableTimestampConverter()  DateTime? lastOpenedAt)  $default,) {final _that = this;
switch (_that) {
case _DocumentShare():
return $default(_that.id,_that.scope,_that.ownerMemberId,_that.documentId,_that.documentName,_that.contentType,_that.createdBy,_that.createdByUid,_that.createdAt,_that.expiresAt,_that.shiftId,_that.hasPin,_that.status,_that.openCount,_that.lastOpenedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String scope,  String? ownerMemberId,  String documentId,  String documentName,  String contentType,  String? createdBy,  String createdByUid, @NullableTimestampConverter()  DateTime? createdAt, @InstantConverter()  DateTime expiresAt,  String? shiftId,  bool hasPin,  String status,  int openCount, @NullableTimestampConverter()  DateTime? lastOpenedAt)?  $default,) {final _that = this;
switch (_that) {
case _DocumentShare() when $default != null:
return $default(_that.id,_that.scope,_that.ownerMemberId,_that.documentId,_that.documentName,_that.contentType,_that.createdBy,_that.createdByUid,_that.createdAt,_that.expiresAt,_that.shiftId,_that.hasPin,_that.status,_that.openCount,_that.lastOpenedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DocumentShare extends DocumentShare {
  const _DocumentShare({@JsonKey(includeToJson: false) required this.id, required this.scope, this.ownerMemberId, required this.documentId, required this.documentName, required this.contentType, this.createdBy, required this.createdByUid, @NullableTimestampConverter() this.createdAt, @InstantConverter() required this.expiresAt, this.shiftId, required this.hasPin, this.status = DocumentShare.active, this.openCount = 0, @NullableTimestampConverter() this.lastOpenedAt}): super._();
  factory _DocumentShare.fromJson(Map<String, dynamic> json) => _$DocumentShareFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
/// `household` for a folder's document, `vault` for a person's.
@override final  String scope;
/// The vault it came from, or null for a household document.
@override final  String? ownerMemberId;
@override final  String documentId;
/// The document's name when the link was made.
@override final  String documentName;
@override final  String contentType;
/// The member who made it, or null for an account with no profile.
@override final  String? createdBy;
@override final  String createdByUid;
@override@NullableTimestampConverter() final  DateTime? createdAt;
/// When it stops working at the latest (`ENG-21`).
@override@InstantConverter() final  DateTime expiresAt;
/// The nanny-hub shift it ends with, if it was made for one.
@override final  String? shiftId;
@override final  bool hasPin;
@override@JsonKey() final  String status;
@override@JsonKey() final  int openCount;
@override@NullableTimestampConverter() final  DateTime? lastOpenedAt;

/// Create a copy of DocumentShare
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentShareCopyWith<_DocumentShare> get copyWith => __$DocumentShareCopyWithImpl<_DocumentShare>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocumentShareToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentShare&&(identical(other.id, id) || other.id == id)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.ownerMemberId, ownerMemberId) || other.ownerMemberId == ownerMemberId)&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.documentName, documentName) || other.documentName == documentName)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdByUid, createdByUid) || other.createdByUid == createdByUid)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.shiftId, shiftId) || other.shiftId == shiftId)&&(identical(other.hasPin, hasPin) || other.hasPin == hasPin)&&(identical(other.status, status) || other.status == status)&&(identical(other.openCount, openCount) || other.openCount == openCount)&&(identical(other.lastOpenedAt, lastOpenedAt) || other.lastOpenedAt == lastOpenedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,scope,ownerMemberId,documentId,documentName,contentType,createdBy,createdByUid,createdAt,expiresAt,shiftId,hasPin,status,openCount,lastOpenedAt);
}

@override
String toString() {
    return 'DocumentShare(id: $id, scope: $scope, ownerMemberId: $ownerMemberId, documentId: $documentId, documentName: $documentName, contentType: $contentType, createdBy: $createdBy, createdByUid: $createdByUid, createdAt: $createdAt, expiresAt: $expiresAt, shiftId: $shiftId, hasPin: $hasPin, status: $status, openCount: $openCount, lastOpenedAt: $lastOpenedAt)';
}


}

/// @nodoc
abstract mixin class _$DocumentShareCopyWith<$Res> implements $DocumentShareCopyWith<$Res> {
  factory _$DocumentShareCopyWith(_DocumentShare value, $Res Function(_DocumentShare) _then) = __$DocumentShareCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String scope, String? ownerMemberId, String documentId, String documentName, String contentType, String? createdBy, String createdByUid,@NullableTimestampConverter() DateTime? createdAt,@InstantConverter() DateTime expiresAt, String? shiftId, bool hasPin, String status, int openCount,@NullableTimestampConverter() DateTime? lastOpenedAt
});




}
/// @nodoc
class __$DocumentShareCopyWithImpl<$Res>
    implements _$DocumentShareCopyWith<$Res> {
  __$DocumentShareCopyWithImpl(this._self, this._then);

  final _DocumentShare _self;
  final $Res Function(_DocumentShare) _then;

/// Create a copy of DocumentShare
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? scope = null,Object? ownerMemberId = freezed,Object? documentId = null,Object? documentName = null,Object? contentType = null,Object? createdBy = freezed,Object? createdByUid = null,Object? createdAt = freezed,Object? expiresAt = null,Object? shiftId = freezed,Object? hasPin = null,Object? status = null,Object? openCount = null,Object? lastOpenedAt = freezed,}) {
  return _then(_DocumentShare(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as String,ownerMemberId: freezed == ownerMemberId ? _self.ownerMemberId : ownerMemberId // ignore: cast_nullable_to_non_nullable
as String?,documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,documentName: null == documentName ? _self.documentName : documentName // ignore: cast_nullable_to_non_nullable
as String,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdByUid: null == createdByUid ? _self.createdByUid : createdByUid // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,shiftId: freezed == shiftId ? _self.shiftId : shiftId // ignore: cast_nullable_to_non_nullable
as String?,hasPin: null == hasPin ? _self.hasPin : hasPin // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,openCount: null == openCount ? _self.openCount : openCount // ignore: cast_nullable_to_non_nullable
as int,lastOpenedAt: freezed == lastOpenedAt ? _self.lastOpenedAt : lastOpenedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

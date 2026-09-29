// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vault_view.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VaultView {

@JsonKey(includeToJson: false) String get id;/// The vault it belongs to, from the path; never stored.
@JsonKey(includeToJson: false, includeFromJson: false) String get ownerMemberId; String get documentId;/// The name when it was opened; a later rename does not rewrite history.
 String get documentName;/// Who opened it, or null for an account with no profile of its own —
/// and for somebody who opened it through a shared link.
 String? get viewerMemberId;/// The shared link it was opened through, if it was (documents
/// ADR-0006). Absent on every entry written before links (`BE-10`).
 String? get shareId;@ServerTimestampConverter() DateTime? get viewedAt;
/// Create a copy of VaultView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VaultViewCopyWith<VaultView> get copyWith => _$VaultViewCopyWithImpl<VaultView>(this as VaultView, _$identity);

  /// Serializes this VaultView to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as VaultView;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VaultView&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.ownerMemberId, _this.ownerMemberId) || other.ownerMemberId == _this.ownerMemberId)&&(identical(other.documentId, _this.documentId) || other.documentId == _this.documentId)&&(identical(other.documentName, _this.documentName) || other.documentName == _this.documentName)&&(identical(other.viewerMemberId, _this.viewerMemberId) || other.viewerMemberId == _this.viewerMemberId)&&(identical(other.shareId, _this.shareId) || other.shareId == _this.shareId)&&(identical(other.viewedAt, _this.viewedAt) || other.viewedAt == _this.viewedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as VaultView;
  return Object.hash(runtimeType,_this.id,_this.ownerMemberId,_this.documentId,_this.documentName,_this.viewerMemberId,_this.shareId,_this.viewedAt);
}

@override
String toString() {
  final _this = this as VaultView;
  return 'VaultView(id: ${_this.id}, ownerMemberId: ${_this.ownerMemberId}, documentId: ${_this.documentId}, documentName: ${_this.documentName}, viewerMemberId: ${_this.viewerMemberId}, shareId: ${_this.shareId}, viewedAt: ${_this.viewedAt})';
}


}

/// @nodoc
abstract mixin class $VaultViewCopyWith<$Res>  {
  factory $VaultViewCopyWith(VaultView value, $Res Function(VaultView) _then) = _$VaultViewCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id,@JsonKey(includeToJson: false, includeFromJson: false) String ownerMemberId, String documentId, String documentName, String? viewerMemberId, String? shareId,@ServerTimestampConverter() DateTime? viewedAt
});




}
/// @nodoc
class _$VaultViewCopyWithImpl<$Res>
    implements $VaultViewCopyWith<$Res> {
  _$VaultViewCopyWithImpl(this._self, this._then);

  final VaultView _self;
  final $Res Function(VaultView) _then;

/// Create a copy of VaultView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ownerMemberId = null,Object? documentId = null,Object? documentName = null,Object? viewerMemberId = freezed,Object? shareId = freezed,Object? viewedAt = freezed,}) {
  return _then(VaultView(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownerMemberId: null == ownerMemberId ? _self.ownerMemberId : ownerMemberId // ignore: cast_nullable_to_non_nullable
as String,documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,documentName: null == documentName ? _self.documentName : documentName // ignore: cast_nullable_to_non_nullable
as String,viewerMemberId: freezed == viewerMemberId ? _self.viewerMemberId : viewerMemberId // ignore: cast_nullable_to_non_nullable
as String?,shareId: freezed == shareId ? _self.shareId : shareId // ignore: cast_nullable_to_non_nullable
as String?,viewedAt: freezed == viewedAt ? _self.viewedAt : viewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [VaultView].
extension VaultViewPatterns on VaultView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VaultView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VaultView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VaultView value)  $default,){
final _that = this;
switch (_that) {
case _VaultView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VaultView value)?  $default,){
final _that = this;
switch (_that) {
case _VaultView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id, @JsonKey(includeToJson: false, includeFromJson: false)  String ownerMemberId,  String documentId,  String documentName,  String? viewerMemberId,  String? shareId, @ServerTimestampConverter()  DateTime? viewedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VaultView() when $default != null:
return $default(_that.id,_that.ownerMemberId,_that.documentId,_that.documentName,_that.viewerMemberId,_that.shareId,_that.viewedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id, @JsonKey(includeToJson: false, includeFromJson: false)  String ownerMemberId,  String documentId,  String documentName,  String? viewerMemberId,  String? shareId, @ServerTimestampConverter()  DateTime? viewedAt)  $default,) {final _that = this;
switch (_that) {
case _VaultView():
return $default(_that.id,_that.ownerMemberId,_that.documentId,_that.documentName,_that.viewerMemberId,_that.shareId,_that.viewedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id, @JsonKey(includeToJson: false, includeFromJson: false)  String ownerMemberId,  String documentId,  String documentName,  String? viewerMemberId,  String? shareId, @ServerTimestampConverter()  DateTime? viewedAt)?  $default,) {final _that = this;
switch (_that) {
case _VaultView() when $default != null:
return $default(_that.id,_that.ownerMemberId,_that.documentId,_that.documentName,_that.viewerMemberId,_that.shareId,_that.viewedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VaultView extends VaultView {
  const _VaultView({@JsonKey(includeToJson: false) required this.id, @JsonKey(includeToJson: false, includeFromJson: false) this.ownerMemberId = '', required this.documentId, required this.documentName, this.viewerMemberId, this.shareId, @ServerTimestampConverter() this.viewedAt}): super._();
  factory _VaultView.fromJson(Map<String, dynamic> json) => _$VaultViewFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
/// The vault it belongs to, from the path; never stored.
@override@JsonKey(includeToJson: false, includeFromJson: false) final  String ownerMemberId;
@override final  String documentId;
/// The name when it was opened; a later rename does not rewrite history.
@override final  String documentName;
/// Who opened it, or null for an account with no profile of its own —
/// and for somebody who opened it through a shared link.
@override final  String? viewerMemberId;
/// The shared link it was opened through, if it was (documents
/// ADR-0006). Absent on every entry written before links (`BE-10`).
@override final  String? shareId;
@override@ServerTimestampConverter() final  DateTime? viewedAt;

/// Create a copy of VaultView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VaultViewCopyWith<_VaultView> get copyWith => __$VaultViewCopyWithImpl<_VaultView>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VaultViewToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _VaultView&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerMemberId, ownerMemberId) || other.ownerMemberId == ownerMemberId)&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.documentName, documentName) || other.documentName == documentName)&&(identical(other.viewerMemberId, viewerMemberId) || other.viewerMemberId == viewerMemberId)&&(identical(other.shareId, shareId) || other.shareId == shareId)&&(identical(other.viewedAt, viewedAt) || other.viewedAt == viewedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,ownerMemberId,documentId,documentName,viewerMemberId,shareId,viewedAt);
}

@override
String toString() {
    return 'VaultView(id: $id, ownerMemberId: $ownerMemberId, documentId: $documentId, documentName: $documentName, viewerMemberId: $viewerMemberId, shareId: $shareId, viewedAt: $viewedAt)';
}


}

/// @nodoc
abstract mixin class _$VaultViewCopyWith<$Res> implements $VaultViewCopyWith<$Res> {
  factory _$VaultViewCopyWith(_VaultView value, $Res Function(_VaultView) _then) = __$VaultViewCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id,@JsonKey(includeToJson: false, includeFromJson: false) String ownerMemberId, String documentId, String documentName, String? viewerMemberId, String? shareId,@ServerTimestampConverter() DateTime? viewedAt
});




}
/// @nodoc
class __$VaultViewCopyWithImpl<$Res>
    implements _$VaultViewCopyWith<$Res> {
  __$VaultViewCopyWithImpl(this._self, this._then);

  final _VaultView _self;
  final $Res Function(_VaultView) _then;

/// Create a copy of VaultView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ownerMemberId = null,Object? documentId = null,Object? documentName = null,Object? viewerMemberId = freezed,Object? shareId = freezed,Object? viewedAt = freezed,}) {
  return _then(_VaultView(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownerMemberId: null == ownerMemberId ? _self.ownerMemberId : ownerMemberId // ignore: cast_nullable_to_non_nullable
as String,documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,documentName: null == documentName ? _self.documentName : documentName // ignore: cast_nullable_to_non_nullable
as String,viewerMemberId: freezed == viewerMemberId ? _self.viewerMemberId : viewerMemberId // ignore: cast_nullable_to_non_nullable
as String?,shareId: freezed == shareId ? _self.shareId : shareId // ignore: cast_nullable_to_non_nullable
as String?,viewedAt: freezed == viewedAt ? _self.viewedAt : viewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

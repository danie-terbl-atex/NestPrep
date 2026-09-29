// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'household_document.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HouseholdDocument {

@JsonKey(includeToJson: false) String get id;/// The folder it is filed in. A document is always in exactly one.
 String get folderId; String get name; String get contentType; int get sizeBytes;/// The member profile that added it, not the account.
 String get uploadedBy;@ServerTimestampConverter() DateTime? get uploadedAt;/// Free-text labels a person searches by (documents ADR-0005). Absent on
/// every row written before phase 2, which reads as none (`BE-10`).
 List<String> get tags;/// The day it stops being valid, in the household's zone, if it has one.
@NullableCalendarDateConverter() CalendarDate? get expiresOn;
/// Create a copy of HouseholdDocument
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HouseholdDocumentCopyWith<HouseholdDocument> get copyWith => _$HouseholdDocumentCopyWithImpl<HouseholdDocument>(this as HouseholdDocument, _$identity);

  /// Serializes this HouseholdDocument to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HouseholdDocument;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HouseholdDocument&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.folderId, _this.folderId) || other.folderId == _this.folderId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.contentType, _this.contentType) || other.contentType == _this.contentType)&&(identical(other.sizeBytes, _this.sizeBytes) || other.sizeBytes == _this.sizeBytes)&&(identical(other.uploadedBy, _this.uploadedBy) || other.uploadedBy == _this.uploadedBy)&&(identical(other.uploadedAt, _this.uploadedAt) || other.uploadedAt == _this.uploadedAt)&&const DeepCollectionEquality().equals(other.tags, _this.tags)&&(identical(other.expiresOn, _this.expiresOn) || other.expiresOn == _this.expiresOn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HouseholdDocument;
  return Object.hash(runtimeType,_this.id,_this.folderId,_this.name,_this.contentType,_this.sizeBytes,_this.uploadedBy,_this.uploadedAt,const DeepCollectionEquality().hash(_this.tags),_this.expiresOn);
}

@override
String toString() {
  final _this = this as HouseholdDocument;
  return 'HouseholdDocument(id: ${_this.id}, folderId: ${_this.folderId}, name: ${_this.name}, contentType: ${_this.contentType}, sizeBytes: ${_this.sizeBytes}, uploadedBy: ${_this.uploadedBy}, uploadedAt: ${_this.uploadedAt}, tags: ${_this.tags}, expiresOn: ${_this.expiresOn})';
}


}

/// @nodoc
abstract mixin class $HouseholdDocumentCopyWith<$Res>  {
  factory $HouseholdDocumentCopyWith(HouseholdDocument value, $Res Function(HouseholdDocument) _then) = _$HouseholdDocumentCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String folderId, String name, String contentType, int sizeBytes, String uploadedBy,@ServerTimestampConverter() DateTime? uploadedAt, List<String> tags,@NullableCalendarDateConverter() CalendarDate? expiresOn
});




}
/// @nodoc
class _$HouseholdDocumentCopyWithImpl<$Res>
    implements $HouseholdDocumentCopyWith<$Res> {
  _$HouseholdDocumentCopyWithImpl(this._self, this._then);

  final HouseholdDocument _self;
  final $Res Function(HouseholdDocument) _then;

/// Create a copy of HouseholdDocument
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? folderId = null,Object? name = null,Object? contentType = null,Object? sizeBytes = null,Object? uploadedBy = null,Object? uploadedAt = freezed,Object? tags = null,Object? expiresOn = freezed,}) {
  return _then(HouseholdDocument(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,folderId: null == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,uploadedBy: null == uploadedBy ? _self.uploadedBy : uploadedBy // ignore: cast_nullable_to_non_nullable
as String,uploadedAt: freezed == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,expiresOn: freezed == expiresOn ? _self.expiresOn : expiresOn // ignore: cast_nullable_to_non_nullable
as CalendarDate?,
  ));
}

}


/// Adds pattern-matching-related methods to [HouseholdDocument].
extension HouseholdDocumentPatterns on HouseholdDocument {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HouseholdDocument value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HouseholdDocument() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HouseholdDocument value)  $default,){
final _that = this;
switch (_that) {
case _HouseholdDocument():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HouseholdDocument value)?  $default,){
final _that = this;
switch (_that) {
case _HouseholdDocument() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String folderId,  String name,  String contentType,  int sizeBytes,  String uploadedBy, @ServerTimestampConverter()  DateTime? uploadedAt,  List<String> tags, @NullableCalendarDateConverter()  CalendarDate? expiresOn)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HouseholdDocument() when $default != null:
return $default(_that.id,_that.folderId,_that.name,_that.contentType,_that.sizeBytes,_that.uploadedBy,_that.uploadedAt,_that.tags,_that.expiresOn);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String folderId,  String name,  String contentType,  int sizeBytes,  String uploadedBy, @ServerTimestampConverter()  DateTime? uploadedAt,  List<String> tags, @NullableCalendarDateConverter()  CalendarDate? expiresOn)  $default,) {final _that = this;
switch (_that) {
case _HouseholdDocument():
return $default(_that.id,_that.folderId,_that.name,_that.contentType,_that.sizeBytes,_that.uploadedBy,_that.uploadedAt,_that.tags,_that.expiresOn);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String folderId,  String name,  String contentType,  int sizeBytes,  String uploadedBy, @ServerTimestampConverter()  DateTime? uploadedAt,  List<String> tags, @NullableCalendarDateConverter()  CalendarDate? expiresOn)?  $default,) {final _that = this;
switch (_that) {
case _HouseholdDocument() when $default != null:
return $default(_that.id,_that.folderId,_that.name,_that.contentType,_that.sizeBytes,_that.uploadedBy,_that.uploadedAt,_that.tags,_that.expiresOn);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HouseholdDocument extends HouseholdDocument {
  const _HouseholdDocument({@JsonKey(includeToJson: false) required this.id, required this.folderId, required this.name, required this.contentType, required this.sizeBytes, required this.uploadedBy, @ServerTimestampConverter() this.uploadedAt,  List<String> tags = const <String>[], @NullableCalendarDateConverter() this.expiresOn}): _tags = tags,super._();
  factory _HouseholdDocument.fromJson(Map<String, dynamic> json) => _$HouseholdDocumentFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
/// The folder it is filed in. A document is always in exactly one.
@override final  String folderId;
@override final  String name;
@override final  String contentType;
@override final  int sizeBytes;
/// The member profile that added it, not the account.
@override final  String uploadedBy;
@override@ServerTimestampConverter() final  DateTime? uploadedAt;
/// Free-text labels a person searches by (documents ADR-0005). Absent on
/// every row written before phase 2, which reads as none (`BE-10`).
 final  List<String> _tags;
/// Free-text labels a person searches by (documents ADR-0005). Absent on
/// every row written before phase 2, which reads as none (`BE-10`).
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

/// The day it stops being valid, in the household's zone, if it has one.
@override@NullableCalendarDateConverter() final  CalendarDate? expiresOn;

/// Create a copy of HouseholdDocument
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HouseholdDocumentCopyWith<_HouseholdDocument> get copyWith => __$HouseholdDocumentCopyWithImpl<_HouseholdDocument>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HouseholdDocumentToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HouseholdDocument&&(identical(other.id, id) || other.id == id)&&(identical(other.folderId, folderId) || other.folderId == folderId)&&(identical(other.name, name) || other.name == name)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.uploadedBy, uploadedBy) || other.uploadedBy == uploadedBy)&&(identical(other.uploadedAt, uploadedAt) || other.uploadedAt == uploadedAt)&&const DeepCollectionEquality().equals(other.tags, _tags)&&(identical(other.expiresOn, expiresOn) || other.expiresOn == expiresOn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,folderId,name,contentType,sizeBytes,uploadedBy,uploadedAt,const DeepCollectionEquality().hash(_tags),expiresOn);
}

@override
String toString() {
    return 'HouseholdDocument(id: $id, folderId: $folderId, name: $name, contentType: $contentType, sizeBytes: $sizeBytes, uploadedBy: $uploadedBy, uploadedAt: $uploadedAt, tags: $tags, expiresOn: $expiresOn)';
}


}

/// @nodoc
abstract mixin class _$HouseholdDocumentCopyWith<$Res> implements $HouseholdDocumentCopyWith<$Res> {
  factory _$HouseholdDocumentCopyWith(_HouseholdDocument value, $Res Function(_HouseholdDocument) _then) = __$HouseholdDocumentCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String folderId, String name, String contentType, int sizeBytes, String uploadedBy,@ServerTimestampConverter() DateTime? uploadedAt, List<String> tags,@NullableCalendarDateConverter() CalendarDate? expiresOn
});




}
/// @nodoc
class __$HouseholdDocumentCopyWithImpl<$Res>
    implements _$HouseholdDocumentCopyWith<$Res> {
  __$HouseholdDocumentCopyWithImpl(this._self, this._then);

  final _HouseholdDocument _self;
  final $Res Function(_HouseholdDocument) _then;

/// Create a copy of HouseholdDocument
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? folderId = null,Object? name = null,Object? contentType = null,Object? sizeBytes = null,Object? uploadedBy = null,Object? uploadedAt = freezed,Object? tags = null,Object? expiresOn = freezed,}) {
  return _then(_HouseholdDocument(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,folderId: null == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,uploadedBy: null == uploadedBy ? _self.uploadedBy : uploadedBy // ignore: cast_nullable_to_non_nullable
as String,uploadedAt: freezed == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,expiresOn: freezed == expiresOn ? _self.expiresOn : expiresOn // ignore: cast_nullable_to_non_nullable
as CalendarDate?,
  ));
}


}

// dart format on

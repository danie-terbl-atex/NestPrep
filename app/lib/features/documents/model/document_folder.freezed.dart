// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document_folder.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DocumentFolder {

@JsonKey(includeToJson: false) String get id; String get name;/// The member profile that made it, not the account.
 String get createdBy;@ServerTimestampConverter() DateTime? get createdAt;
/// Create a copy of DocumentFolder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentFolderCopyWith<DocumentFolder> get copyWith => _$DocumentFolderCopyWithImpl<DocumentFolder>(this as DocumentFolder, _$identity);

  /// Serializes this DocumentFolder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DocumentFolder;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentFolder&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DocumentFolder;
  return Object.hash(runtimeType,_this.id,_this.name,_this.createdBy,_this.createdAt);
}

@override
String toString() {
  final _this = this as DocumentFolder;
  return 'DocumentFolder(id: ${_this.id}, name: ${_this.name}, createdBy: ${_this.createdBy}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $DocumentFolderCopyWith<$Res>  {
  factory $DocumentFolderCopyWith(DocumentFolder value, $Res Function(DocumentFolder) _then) = _$DocumentFolderCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String name, String createdBy,@ServerTimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class _$DocumentFolderCopyWithImpl<$Res>
    implements $DocumentFolderCopyWith<$Res> {
  _$DocumentFolderCopyWithImpl(this._self, this._then);

  final DocumentFolder _self;
  final $Res Function(DocumentFolder) _then;

/// Create a copy of DocumentFolder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? createdBy = null,Object? createdAt = freezed,}) {
  return _then(DocumentFolder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentFolder].
extension DocumentFolderPatterns on DocumentFolder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentFolder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentFolder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentFolder value)  $default,){
final _that = this;
switch (_that) {
case _DocumentFolder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentFolder value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentFolder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String name,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentFolder() when $default != null:
return $default(_that.id,_that.name,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String name,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _DocumentFolder():
return $default(_that.id,_that.name,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String name,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _DocumentFolder() when $default != null:
return $default(_that.id,_that.name,_that.createdBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DocumentFolder extends DocumentFolder {
  const _DocumentFolder({@JsonKey(includeToJson: false) required this.id, required this.name, required this.createdBy, @ServerTimestampConverter() this.createdAt}): super._();
  factory _DocumentFolder.fromJson(Map<String, dynamic> json) => _$DocumentFolderFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String name;
/// The member profile that made it, not the account.
@override final  String createdBy;
@override@ServerTimestampConverter() final  DateTime? createdAt;

/// Create a copy of DocumentFolder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentFolderCopyWith<_DocumentFolder> get copyWith => __$DocumentFolderCopyWithImpl<_DocumentFolder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocumentFolderToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentFolder&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,createdBy,createdAt);
}

@override
String toString() {
    return 'DocumentFolder(id: $id, name: $name, createdBy: $createdBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$DocumentFolderCopyWith<$Res> implements $DocumentFolderCopyWith<$Res> {
  factory _$DocumentFolderCopyWith(_DocumentFolder value, $Res Function(_DocumentFolder) _then) = __$DocumentFolderCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String name, String createdBy,@ServerTimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class __$DocumentFolderCopyWithImpl<$Res>
    implements _$DocumentFolderCopyWith<$Res> {
  __$DocumentFolderCopyWithImpl(this._self, this._then);

  final _DocumentFolder _self;
  final $Res Function(_DocumentFolder) _then;

/// Create a copy of DocumentFolder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? createdBy = null,Object? createdAt = freezed,}) {
  return _then(_DocumentFolder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

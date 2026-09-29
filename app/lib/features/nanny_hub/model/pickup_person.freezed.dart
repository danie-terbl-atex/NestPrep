// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pickup_person.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PickupPerson {

@JsonKey(includeToJson: false) String get id; String get name;/// "Gogo", "Uncle Thabo", "Lebo's mom".
 String get relationship;/// How to be sure at the door: "Shows her ID; drives a white Polo".
 String? get idNote; String? get phone; String? get photoId; List<String> get childIds; String get createdBy;@ServerTimestampConverter() DateTime? get createdAt;
/// Create a copy of PickupPerson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PickupPersonCopyWith<PickupPerson> get copyWith => _$PickupPersonCopyWithImpl<PickupPerson>(this as PickupPerson, _$identity);

  /// Serializes this PickupPerson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PickupPerson;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PickupPerson&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.relationship, _this.relationship) || other.relationship == _this.relationship)&&(identical(other.idNote, _this.idNote) || other.idNote == _this.idNote)&&(identical(other.phone, _this.phone) || other.phone == _this.phone)&&(identical(other.photoId, _this.photoId) || other.photoId == _this.photoId)&&const DeepCollectionEquality().equals(other.childIds, _this.childIds)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PickupPerson;
  return Object.hash(runtimeType,_this.id,_this.name,_this.relationship,_this.idNote,_this.phone,_this.photoId,const DeepCollectionEquality().hash(_this.childIds),_this.createdBy,_this.createdAt);
}

@override
String toString() {
  final _this = this as PickupPerson;
  return 'PickupPerson(id: ${_this.id}, name: ${_this.name}, relationship: ${_this.relationship}, idNote: ${_this.idNote}, phone: ${_this.phone}, photoId: ${_this.photoId}, childIds: ${_this.childIds}, createdBy: ${_this.createdBy}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $PickupPersonCopyWith<$Res>  {
  factory $PickupPersonCopyWith(PickupPerson value, $Res Function(PickupPerson) _then) = _$PickupPersonCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String name, String relationship, String? idNote, String? phone, String? photoId, List<String> childIds, String createdBy,@ServerTimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class _$PickupPersonCopyWithImpl<$Res>
    implements $PickupPersonCopyWith<$Res> {
  _$PickupPersonCopyWithImpl(this._self, this._then);

  final PickupPerson _self;
  final $Res Function(PickupPerson) _then;

/// Create a copy of PickupPerson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? relationship = null,Object? idNote = freezed,Object? phone = freezed,Object? photoId = freezed,Object? childIds = null,Object? createdBy = null,Object? createdAt = freezed,}) {
  return _then(PickupPerson(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,relationship: null == relationship ? _self.relationship : relationship // ignore: cast_nullable_to_non_nullable
as String,idNote: freezed == idNote ? _self.idNote : idNote // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,photoId: freezed == photoId ? _self.photoId : photoId // ignore: cast_nullable_to_non_nullable
as String?,childIds: null == childIds ? _self.childIds : childIds // ignore: cast_nullable_to_non_nullable
as List<String>,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PickupPerson].
extension PickupPersonPatterns on PickupPerson {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PickupPerson value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PickupPerson() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PickupPerson value)  $default,){
final _that = this;
switch (_that) {
case _PickupPerson():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PickupPerson value)?  $default,){
final _that = this;
switch (_that) {
case _PickupPerson() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String name,  String relationship,  String? idNote,  String? phone,  String? photoId,  List<String> childIds,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PickupPerson() when $default != null:
return $default(_that.id,_that.name,_that.relationship,_that.idNote,_that.phone,_that.photoId,_that.childIds,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String name,  String relationship,  String? idNote,  String? phone,  String? photoId,  List<String> childIds,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _PickupPerson():
return $default(_that.id,_that.name,_that.relationship,_that.idNote,_that.phone,_that.photoId,_that.childIds,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String name,  String relationship,  String? idNote,  String? phone,  String? photoId,  List<String> childIds,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _PickupPerson() when $default != null:
return $default(_that.id,_that.name,_that.relationship,_that.idNote,_that.phone,_that.photoId,_that.childIds,_that.createdBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PickupPerson extends PickupPerson {
  const _PickupPerson({@JsonKey(includeToJson: false) required this.id, required this.name, required this.relationship, this.idNote, this.phone, this.photoId,  List<String> childIds = const <String>[], required this.createdBy, @ServerTimestampConverter() this.createdAt}): _childIds = childIds,super._();
  factory _PickupPerson.fromJson(Map<String, dynamic> json) => _$PickupPersonFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String name;
/// "Gogo", "Uncle Thabo", "Lebo's mom".
@override final  String relationship;
/// How to be sure at the door: "Shows her ID; drives a white Polo".
@override final  String? idNote;
@override final  String? phone;
@override final  String? photoId;
 final  List<String> _childIds;
@override@JsonKey() List<String> get childIds {
  if (_childIds is EqualUnmodifiableListView) return _childIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_childIds);
}

@override final  String createdBy;
@override@ServerTimestampConverter() final  DateTime? createdAt;

/// Create a copy of PickupPerson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PickupPersonCopyWith<_PickupPerson> get copyWith => __$PickupPersonCopyWithImpl<_PickupPerson>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PickupPersonToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PickupPerson&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.relationship, relationship) || other.relationship == relationship)&&(identical(other.idNote, idNote) || other.idNote == idNote)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.photoId, photoId) || other.photoId == photoId)&&const DeepCollectionEquality().equals(other.childIds, _childIds)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,relationship,idNote,phone,photoId,const DeepCollectionEquality().hash(_childIds),createdBy,createdAt);
}

@override
String toString() {
    return 'PickupPerson(id: $id, name: $name, relationship: $relationship, idNote: $idNote, phone: $phone, photoId: $photoId, childIds: $childIds, createdBy: $createdBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PickupPersonCopyWith<$Res> implements $PickupPersonCopyWith<$Res> {
  factory _$PickupPersonCopyWith(_PickupPerson value, $Res Function(_PickupPerson) _then) = __$PickupPersonCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String name, String relationship, String? idNote, String? phone, String? photoId, List<String> childIds, String createdBy,@ServerTimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class __$PickupPersonCopyWithImpl<$Res>
    implements _$PickupPersonCopyWith<$Res> {
  __$PickupPersonCopyWithImpl(this._self, this._then);

  final _PickupPerson _self;
  final $Res Function(_PickupPerson) _then;

/// Create a copy of PickupPerson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? relationship = null,Object? idNote = freezed,Object? phone = freezed,Object? photoId = freezed,Object? childIds = null,Object? createdBy = null,Object? createdAt = freezed,}) {
  return _then(_PickupPerson(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,relationship: null == relationship ? _self.relationship : relationship // ignore: cast_nullable_to_non_nullable
as String,idNote: freezed == idNote ? _self.idNote : idNote // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,photoId: freezed == photoId ? _self.photoId : photoId // ignore: cast_nullable_to_non_nullable
as String?,childIds: null == childIds ? _self._childIds : childIds // ignore: cast_nullable_to_non_nullable
as List<String>,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

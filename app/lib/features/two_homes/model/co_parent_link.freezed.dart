// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'co_parent_link.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CoParentLink {

@JsonKey(includeToJson: false) String get id;@JsonKey(unknownEnumValue: LinkStatus.ended) LinkStatus get status; CustodySide get ownSide;/// This household's own kid profile for the child.
 String get childMemberId;/// The child's first name, as the home that made the code wrote it.
 String get childName; CoParentHomes get homes; CustodySchedule get schedule;/// Days an accepted swap moved: `YYYY-MM-DD` → side.
 Map<String, String> get overrides;@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) CustodySide? get awaitingSide;@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) CustodySide? get endedBySide;@ServerTimestampConverter() DateTime? get createdAt;@ServerTimestampConverter() DateTime? get updatedAt;
/// Create a copy of CoParentLink
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoParentLinkCopyWith<CoParentLink> get copyWith => _$CoParentLinkCopyWithImpl<CoParentLink>(this as CoParentLink, _$identity);

  /// Serializes this CoParentLink to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CoParentLink;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoParentLink&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.ownSide, _this.ownSide) || other.ownSide == _this.ownSide)&&(identical(other.childMemberId, _this.childMemberId) || other.childMemberId == _this.childMemberId)&&(identical(other.childName, _this.childName) || other.childName == _this.childName)&&(identical(other.homes, _this.homes) || other.homes == _this.homes)&&(identical(other.schedule, _this.schedule) || other.schedule == _this.schedule)&&const DeepCollectionEquality().equals(other.overrides, _this.overrides)&&(identical(other.awaitingSide, _this.awaitingSide) || other.awaitingSide == _this.awaitingSide)&&(identical(other.endedBySide, _this.endedBySide) || other.endedBySide == _this.endedBySide)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CoParentLink;
  return Object.hash(runtimeType,_this.id,_this.status,_this.ownSide,_this.childMemberId,_this.childName,_this.homes,_this.schedule,const DeepCollectionEquality().hash(_this.overrides),_this.awaitingSide,_this.endedBySide,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as CoParentLink;
  return 'CoParentLink(id: ${_this.id}, status: ${_this.status}, ownSide: ${_this.ownSide}, childMemberId: ${_this.childMemberId}, childName: ${_this.childName}, homes: ${_this.homes}, schedule: ${_this.schedule}, overrides: ${_this.overrides}, awaitingSide: ${_this.awaitingSide}, endedBySide: ${_this.endedBySide}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $CoParentLinkCopyWith<$Res>  {
  factory $CoParentLinkCopyWith(CoParentLink value, $Res Function(CoParentLink) _then) = _$CoParentLinkCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id,@JsonKey(unknownEnumValue: LinkStatus.ended) LinkStatus status, CustodySide ownSide, String childMemberId, String childName, CoParentHomes homes, CustodySchedule schedule, Map<String, String> overrides,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) CustodySide? awaitingSide,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) CustodySide? endedBySide,@ServerTimestampConverter() DateTime? createdAt,@ServerTimestampConverter() DateTime? updatedAt
});


$CoParentHomesCopyWith<$Res> get homes;$CustodyScheduleCopyWith<$Res> get schedule;

}
/// @nodoc
class _$CoParentLinkCopyWithImpl<$Res>
    implements $CoParentLinkCopyWith<$Res> {
  _$CoParentLinkCopyWithImpl(this._self, this._then);

  final CoParentLink _self;
  final $Res Function(CoParentLink) _then;

/// Create a copy of CoParentLink
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? ownSide = null,Object? childMemberId = null,Object? childName = null,Object? homes = null,Object? schedule = null,Object? overrides = null,Object? awaitingSide = freezed,Object? endedBySide = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(CoParentLink(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LinkStatus,ownSide: null == ownSide ? _self.ownSide : ownSide // ignore: cast_nullable_to_non_nullable
as CustodySide,childMemberId: null == childMemberId ? _self.childMemberId : childMemberId // ignore: cast_nullable_to_non_nullable
as String,childName: null == childName ? _self.childName : childName // ignore: cast_nullable_to_non_nullable
as String,homes: null == homes ? _self.homes : homes // ignore: cast_nullable_to_non_nullable
as CoParentHomes,schedule: null == schedule ? _self.schedule : schedule // ignore: cast_nullable_to_non_nullable
as CustodySchedule,overrides: null == overrides ? _self.overrides : overrides // ignore: cast_nullable_to_non_nullable
as Map<String, String>,awaitingSide: freezed == awaitingSide ? _self.awaitingSide : awaitingSide // ignore: cast_nullable_to_non_nullable
as CustodySide?,endedBySide: freezed == endedBySide ? _self.endedBySide : endedBySide // ignore: cast_nullable_to_non_nullable
as CustodySide?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of CoParentLink
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoParentHomesCopyWith<$Res> get homes {
  
  return $CoParentHomesCopyWith<$Res>(_self.homes, (value) {
    return _then(_self.copyWith(homes: value));
  });
}/// Create a copy of CoParentLink
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustodyScheduleCopyWith<$Res> get schedule {
  
  return $CustodyScheduleCopyWith<$Res>(_self.schedule, (value) {
    return _then(_self.copyWith(schedule: value));
  });
}
}


/// Adds pattern-matching-related methods to [CoParentLink].
extension CoParentLinkPatterns on CoParentLink {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoParentLink value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoParentLink() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoParentLink value)  $default,){
final _that = this;
switch (_that) {
case _CoParentLink():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoParentLink value)?  $default,){
final _that = this;
switch (_that) {
case _CoParentLink() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id, @JsonKey(unknownEnumValue: LinkStatus.ended)  LinkStatus status,  CustodySide ownSide,  String childMemberId,  String childName,  CoParentHomes homes,  CustodySchedule schedule,  Map<String, String> overrides, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  CustodySide? awaitingSide, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  CustodySide? endedBySide, @ServerTimestampConverter()  DateTime? createdAt, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoParentLink() when $default != null:
return $default(_that.id,_that.status,_that.ownSide,_that.childMemberId,_that.childName,_that.homes,_that.schedule,_that.overrides,_that.awaitingSide,_that.endedBySide,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id, @JsonKey(unknownEnumValue: LinkStatus.ended)  LinkStatus status,  CustodySide ownSide,  String childMemberId,  String childName,  CoParentHomes homes,  CustodySchedule schedule,  Map<String, String> overrides, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  CustodySide? awaitingSide, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  CustodySide? endedBySide, @ServerTimestampConverter()  DateTime? createdAt, @ServerTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _CoParentLink():
return $default(_that.id,_that.status,_that.ownSide,_that.childMemberId,_that.childName,_that.homes,_that.schedule,_that.overrides,_that.awaitingSide,_that.endedBySide,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id, @JsonKey(unknownEnumValue: LinkStatus.ended)  LinkStatus status,  CustodySide ownSide,  String childMemberId,  String childName,  CoParentHomes homes,  CustodySchedule schedule,  Map<String, String> overrides, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  CustodySide? awaitingSide, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  CustodySide? endedBySide, @ServerTimestampConverter()  DateTime? createdAt, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _CoParentLink() when $default != null:
return $default(_that.id,_that.status,_that.ownSide,_that.childMemberId,_that.childName,_that.homes,_that.schedule,_that.overrides,_that.awaitingSide,_that.endedBySide,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CoParentLink extends CoParentLink {
  const _CoParentLink({@JsonKey(includeToJson: false) required this.id, @JsonKey(unknownEnumValue: LinkStatus.ended) required this.status, required this.ownSide, required this.childMemberId, required this.childName, required this.homes, required this.schedule,  Map<String, String> overrides = const <String, String>{}, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) this.awaitingSide, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) this.endedBySide, @ServerTimestampConverter() this.createdAt, @ServerTimestampConverter() this.updatedAt}): _overrides = overrides,super._();
  factory _CoParentLink.fromJson(Map<String, dynamic> json) => _$CoParentLinkFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override@JsonKey(unknownEnumValue: LinkStatus.ended) final  LinkStatus status;
@override final  CustodySide ownSide;
/// This household's own kid profile for the child.
@override final  String childMemberId;
/// The child's first name, as the home that made the code wrote it.
@override final  String childName;
@override final  CoParentHomes homes;
@override final  CustodySchedule schedule;
/// Days an accepted swap moved: `YYYY-MM-DD` → side.
 final  Map<String, String> _overrides;
/// Days an accepted swap moved: `YYYY-MM-DD` → side.
@override@JsonKey() Map<String, String> get overrides {
  if (_overrides is EqualUnmodifiableMapView) return _overrides;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_overrides);
}

@override@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) final  CustodySide? awaitingSide;
@override@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) final  CustodySide? endedBySide;
@override@ServerTimestampConverter() final  DateTime? createdAt;
@override@ServerTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of CoParentLink
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoParentLinkCopyWith<_CoParentLink> get copyWith => __$CoParentLinkCopyWithImpl<_CoParentLink>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CoParentLinkToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoParentLink&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.ownSide, ownSide) || other.ownSide == ownSide)&&(identical(other.childMemberId, childMemberId) || other.childMemberId == childMemberId)&&(identical(other.childName, childName) || other.childName == childName)&&(identical(other.homes, homes) || other.homes == homes)&&(identical(other.schedule, schedule) || other.schedule == schedule)&&const DeepCollectionEquality().equals(other.overrides, _overrides)&&(identical(other.awaitingSide, awaitingSide) || other.awaitingSide == awaitingSide)&&(identical(other.endedBySide, endedBySide) || other.endedBySide == endedBySide)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,status,ownSide,childMemberId,childName,homes,schedule,const DeepCollectionEquality().hash(_overrides),awaitingSide,endedBySide,createdAt,updatedAt);
}

@override
String toString() {
    return 'CoParentLink(id: $id, status: $status, ownSide: $ownSide, childMemberId: $childMemberId, childName: $childName, homes: $homes, schedule: $schedule, overrides: $overrides, awaitingSide: $awaitingSide, endedBySide: $endedBySide, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$CoParentLinkCopyWith<$Res> implements $CoParentLinkCopyWith<$Res> {
  factory _$CoParentLinkCopyWith(_CoParentLink value, $Res Function(_CoParentLink) _then) = __$CoParentLinkCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id,@JsonKey(unknownEnumValue: LinkStatus.ended) LinkStatus status, CustodySide ownSide, String childMemberId, String childName, CoParentHomes homes, CustodySchedule schedule, Map<String, String> overrides,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) CustodySide? awaitingSide,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) CustodySide? endedBySide,@ServerTimestampConverter() DateTime? createdAt,@ServerTimestampConverter() DateTime? updatedAt
});


@override $CoParentHomesCopyWith<$Res> get homes;@override $CustodyScheduleCopyWith<$Res> get schedule;

}
/// @nodoc
class __$CoParentLinkCopyWithImpl<$Res>
    implements _$CoParentLinkCopyWith<$Res> {
  __$CoParentLinkCopyWithImpl(this._self, this._then);

  final _CoParentLink _self;
  final $Res Function(_CoParentLink) _then;

/// Create a copy of CoParentLink
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? ownSide = null,Object? childMemberId = null,Object? childName = null,Object? homes = null,Object? schedule = null,Object? overrides = null,Object? awaitingSide = freezed,Object? endedBySide = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_CoParentLink(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LinkStatus,ownSide: null == ownSide ? _self.ownSide : ownSide // ignore: cast_nullable_to_non_nullable
as CustodySide,childMemberId: null == childMemberId ? _self.childMemberId : childMemberId // ignore: cast_nullable_to_non_nullable
as String,childName: null == childName ? _self.childName : childName // ignore: cast_nullable_to_non_nullable
as String,homes: null == homes ? _self.homes : homes // ignore: cast_nullable_to_non_nullable
as CoParentHomes,schedule: null == schedule ? _self.schedule : schedule // ignore: cast_nullable_to_non_nullable
as CustodySchedule,overrides: null == overrides ? _self._overrides : overrides // ignore: cast_nullable_to_non_nullable
as Map<String, String>,awaitingSide: freezed == awaitingSide ? _self.awaitingSide : awaitingSide // ignore: cast_nullable_to_non_nullable
as CustodySide?,endedBySide: freezed == endedBySide ? _self.endedBySide : endedBySide // ignore: cast_nullable_to_non_nullable
as CustodySide?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of CoParentLink
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoParentHomesCopyWith<$Res> get homes {
  
  return $CoParentHomesCopyWith<$Res>(_self.homes, (value) {
    return _then(_self.copyWith(homes: value));
  });
}/// Create a copy of CoParentLink
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustodyScheduleCopyWith<$Res> get schedule {
  
  return $CustodyScheduleCopyWith<$Res>(_self.schedule, (value) {
    return _then(_self.copyWith(schedule: value));
  });
}
}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'household.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Household {

@JsonKey(includeToJson: false) String get id; String get name; String get timeZone; Map<String, String> get members;/// uid → the grant a kid, helper or carer holds, and uid → the profile
/// that uid claimed (household ADR-0003). Both written only by Functions.
///
/// Never written by the client, so never serialised (household ADR-0002).
@JsonKey(includeToJson: false)@GrantsByUidConverter() Map<String, AccessGrant> get access;@JsonKey(includeToJson: false) Map<String, String> get profiles;/// memberId → true for a carer who sees the household only during a
/// shift a parent booked for them (nanny-hub ADR-0006). Written only by
/// `setCarerShiftOnly`; the rules read it on every request.
@JsonKey(includeToJson: false) Map<String, bool> get shiftOnly;/// `invitePeople` while a new household's admin has not yet finished or
/// skipped the invite step (household ADR-0003).
@JsonKey(includeToJson: false) String? get pendingSetupStep; String? get createdBy;@ServerTimestampConverter() DateTime? get createdAt;
/// Create a copy of Household
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HouseholdCopyWith<Household> get copyWith => _$HouseholdCopyWithImpl<Household>(this as Household, _$identity);

  /// Serializes this Household to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Household;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Household&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.timeZone, _this.timeZone) || other.timeZone == _this.timeZone)&&const DeepCollectionEquality().equals(other.members, _this.members)&&const DeepCollectionEquality().equals(other.access, _this.access)&&const DeepCollectionEquality().equals(other.profiles, _this.profiles)&&const DeepCollectionEquality().equals(other.shiftOnly, _this.shiftOnly)&&(identical(other.pendingSetupStep, _this.pendingSetupStep) || other.pendingSetupStep == _this.pendingSetupStep)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Household;
  return Object.hash(runtimeType,_this.id,_this.name,_this.timeZone,const DeepCollectionEquality().hash(_this.members),const DeepCollectionEquality().hash(_this.access),const DeepCollectionEquality().hash(_this.profiles),const DeepCollectionEquality().hash(_this.shiftOnly),_this.pendingSetupStep,_this.createdBy,_this.createdAt);
}

@override
String toString() {
  final _this = this as Household;
  return 'Household(id: ${_this.id}, name: ${_this.name}, timeZone: ${_this.timeZone}, members: ${_this.members}, access: ${_this.access}, profiles: ${_this.profiles}, shiftOnly: ${_this.shiftOnly}, pendingSetupStep: ${_this.pendingSetupStep}, createdBy: ${_this.createdBy}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $HouseholdCopyWith<$Res>  {
  factory $HouseholdCopyWith(Household value, $Res Function(Household) _then) = _$HouseholdCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String name, String timeZone, Map<String, String> members,@JsonKey(includeToJson: false)@GrantsByUidConverter() Map<String, AccessGrant> access,@JsonKey(includeToJson: false) Map<String, String> profiles,@JsonKey(includeToJson: false) Map<String, bool> shiftOnly,@JsonKey(includeToJson: false) String? pendingSetupStep, String? createdBy,@ServerTimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class _$HouseholdCopyWithImpl<$Res>
    implements $HouseholdCopyWith<$Res> {
  _$HouseholdCopyWithImpl(this._self, this._then);

  final Household _self;
  final $Res Function(Household) _then;

/// Create a copy of Household
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? timeZone = null,Object? members = null,Object? access = null,Object? profiles = null,Object? shiftOnly = null,Object? pendingSetupStep = freezed,Object? createdBy = freezed,Object? createdAt = freezed,}) {
  return _then(Household(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,timeZone: null == timeZone ? _self.timeZone : timeZone // ignore: cast_nullable_to_non_nullable
as String,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as Map<String, String>,access: null == access ? _self.access : access // ignore: cast_nullable_to_non_nullable
as Map<String, AccessGrant>,profiles: null == profiles ? _self.profiles : profiles // ignore: cast_nullable_to_non_nullable
as Map<String, String>,shiftOnly: null == shiftOnly ? _self.shiftOnly : shiftOnly // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,pendingSetupStep: freezed == pendingSetupStep ? _self.pendingSetupStep : pendingSetupStep // ignore: cast_nullable_to_non_nullable
as String?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Household].
extension HouseholdPatterns on Household {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Household value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Household() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Household value)  $default,){
final _that = this;
switch (_that) {
case _Household():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Household value)?  $default,){
final _that = this;
switch (_that) {
case _Household() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String name,  String timeZone,  Map<String, String> members, @JsonKey(includeToJson: false)@GrantsByUidConverter()  Map<String, AccessGrant> access, @JsonKey(includeToJson: false)  Map<String, String> profiles, @JsonKey(includeToJson: false)  Map<String, bool> shiftOnly, @JsonKey(includeToJson: false)  String? pendingSetupStep,  String? createdBy, @ServerTimestampConverter()  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Household() when $default != null:
return $default(_that.id,_that.name,_that.timeZone,_that.members,_that.access,_that.profiles,_that.shiftOnly,_that.pendingSetupStep,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String name,  String timeZone,  Map<String, String> members, @JsonKey(includeToJson: false)@GrantsByUidConverter()  Map<String, AccessGrant> access, @JsonKey(includeToJson: false)  Map<String, String> profiles, @JsonKey(includeToJson: false)  Map<String, bool> shiftOnly, @JsonKey(includeToJson: false)  String? pendingSetupStep,  String? createdBy, @ServerTimestampConverter()  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _Household():
return $default(_that.id,_that.name,_that.timeZone,_that.members,_that.access,_that.profiles,_that.shiftOnly,_that.pendingSetupStep,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String name,  String timeZone,  Map<String, String> members, @JsonKey(includeToJson: false)@GrantsByUidConverter()  Map<String, AccessGrant> access, @JsonKey(includeToJson: false)  Map<String, String> profiles, @JsonKey(includeToJson: false)  Map<String, bool> shiftOnly, @JsonKey(includeToJson: false)  String? pendingSetupStep,  String? createdBy, @ServerTimestampConverter()  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Household() when $default != null:
return $default(_that.id,_that.name,_that.timeZone,_that.members,_that.access,_that.profiles,_that.shiftOnly,_that.pendingSetupStep,_that.createdBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Household extends Household {
  const _Household({@JsonKey(includeToJson: false) required this.id, required this.name, required this.timeZone,  Map<String, String> members = const <String, String>{}, @JsonKey(includeToJson: false)@GrantsByUidConverter()  Map<String, AccessGrant> access = const <String, AccessGrant>{}, @JsonKey(includeToJson: false)  Map<String, String> profiles = const <String, String>{}, @JsonKey(includeToJson: false)  Map<String, bool> shiftOnly = const <String, bool>{}, @JsonKey(includeToJson: false) this.pendingSetupStep, this.createdBy, @ServerTimestampConverter() this.createdAt}): _members = members,_access = access,_profiles = profiles,_shiftOnly = shiftOnly,super._();
  factory _Household.fromJson(Map<String, dynamic> json) => _$HouseholdFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String name;
@override final  String timeZone;
 final  Map<String, String> _members;
@override@JsonKey() Map<String, String> get members {
  if (_members is EqualUnmodifiableMapView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_members);
}

/// uid → the grant a kid, helper or carer holds, and uid → the profile
/// that uid claimed (household ADR-0003). Both written only by Functions.
///
/// Never written by the client, so never serialised (household ADR-0002).
 final  Map<String, AccessGrant> _access;
/// uid → the grant a kid, helper or carer holds, and uid → the profile
/// that uid claimed (household ADR-0003). Both written only by Functions.
///
/// Never written by the client, so never serialised (household ADR-0002).
@override@JsonKey(includeToJson: false)@GrantsByUidConverter() Map<String, AccessGrant> get access {
  if (_access is EqualUnmodifiableMapView) return _access;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_access);
}

 final  Map<String, String> _profiles;
@override@JsonKey(includeToJson: false) Map<String, String> get profiles {
  if (_profiles is EqualUnmodifiableMapView) return _profiles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_profiles);
}

/// memberId → true for a carer who sees the household only during a
/// shift a parent booked for them (nanny-hub ADR-0006). Written only by
/// `setCarerShiftOnly`; the rules read it on every request.
 final  Map<String, bool> _shiftOnly;
/// memberId → true for a carer who sees the household only during a
/// shift a parent booked for them (nanny-hub ADR-0006). Written only by
/// `setCarerShiftOnly`; the rules read it on every request.
@override@JsonKey(includeToJson: false) Map<String, bool> get shiftOnly {
  if (_shiftOnly is EqualUnmodifiableMapView) return _shiftOnly;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_shiftOnly);
}

/// `invitePeople` while a new household's admin has not yet finished or
/// skipped the invite step (household ADR-0003).
@override@JsonKey(includeToJson: false) final  String? pendingSetupStep;
@override final  String? createdBy;
@override@ServerTimestampConverter() final  DateTime? createdAt;

/// Create a copy of Household
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HouseholdCopyWith<_Household> get copyWith => __$HouseholdCopyWithImpl<_Household>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HouseholdToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Household&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.timeZone, timeZone) || other.timeZone == timeZone)&&const DeepCollectionEquality().equals(other.members, _members)&&const DeepCollectionEquality().equals(other.access, _access)&&const DeepCollectionEquality().equals(other.profiles, _profiles)&&const DeepCollectionEquality().equals(other.shiftOnly, _shiftOnly)&&(identical(other.pendingSetupStep, pendingSetupStep) || other.pendingSetupStep == pendingSetupStep)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,timeZone,const DeepCollectionEquality().hash(_members),const DeepCollectionEquality().hash(_access),const DeepCollectionEquality().hash(_profiles),const DeepCollectionEquality().hash(_shiftOnly),pendingSetupStep,createdBy,createdAt);
}

@override
String toString() {
    return 'Household(id: $id, name: $name, timeZone: $timeZone, members: $members, access: $access, profiles: $profiles, shiftOnly: $shiftOnly, pendingSetupStep: $pendingSetupStep, createdBy: $createdBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$HouseholdCopyWith<$Res> implements $HouseholdCopyWith<$Res> {
  factory _$HouseholdCopyWith(_Household value, $Res Function(_Household) _then) = __$HouseholdCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String name, String timeZone, Map<String, String> members,@JsonKey(includeToJson: false)@GrantsByUidConverter() Map<String, AccessGrant> access,@JsonKey(includeToJson: false) Map<String, String> profiles,@JsonKey(includeToJson: false) Map<String, bool> shiftOnly,@JsonKey(includeToJson: false) String? pendingSetupStep, String? createdBy,@ServerTimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class __$HouseholdCopyWithImpl<$Res>
    implements _$HouseholdCopyWith<$Res> {
  __$HouseholdCopyWithImpl(this._self, this._then);

  final _Household _self;
  final $Res Function(_Household) _then;

/// Create a copy of Household
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? timeZone = null,Object? members = null,Object? access = null,Object? profiles = null,Object? shiftOnly = null,Object? pendingSetupStep = freezed,Object? createdBy = freezed,Object? createdAt = freezed,}) {
  return _then(_Household(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,timeZone: null == timeZone ? _self.timeZone : timeZone // ignore: cast_nullable_to_non_nullable
as String,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as Map<String, String>,access: null == access ? _self._access : access // ignore: cast_nullable_to_non_nullable
as Map<String, AccessGrant>,profiles: null == profiles ? _self._profiles : profiles // ignore: cast_nullable_to_non_nullable
as Map<String, String>,shiftOnly: null == shiftOnly ? _self._shiftOnly : shiftOnly // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,pendingSetupStep: freezed == pendingSetupStep ? _self.pendingSetupStep : pendingSetupStep // ignore: cast_nullable_to_non_nullable
as String?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

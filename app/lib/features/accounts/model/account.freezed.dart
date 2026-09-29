// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Account {

@JsonKey(includeToJson: false) String get id; String get displayName; String? get photoUrl; List<String> get householdIds; String? get activeHouseholdId;@ServerTimestampConverter() DateTime? get createdAt;@ServerTimestampConverter() DateTime? get lastSignedInAt;/// What this person agreed to (accounts ADR-0005). Read here, never
/// written with the rest of the document: the create rule does not allow
/// it, and `acceptLegal` writes it on its own with the server's time.
@JsonKey(includeToJson: false) LegalConsent? get legalConsent;
/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountCopyWith<Account> get copyWith => _$AccountCopyWithImpl<Account>(this as Account, _$identity);

  /// Serializes this Account to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Account;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Account&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.photoUrl, _this.photoUrl) || other.photoUrl == _this.photoUrl)&&const DeepCollectionEquality().equals(other.householdIds, _this.householdIds)&&(identical(other.activeHouseholdId, _this.activeHouseholdId) || other.activeHouseholdId == _this.activeHouseholdId)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.lastSignedInAt, _this.lastSignedInAt) || other.lastSignedInAt == _this.lastSignedInAt)&&(identical(other.legalConsent, _this.legalConsent) || other.legalConsent == _this.legalConsent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Account;
  return Object.hash(runtimeType,_this.id,_this.displayName,_this.photoUrl,const DeepCollectionEquality().hash(_this.householdIds),_this.activeHouseholdId,_this.createdAt,_this.lastSignedInAt,_this.legalConsent);
}

@override
String toString() {
  final _this = this as Account;
  return 'Account(id: ${_this.id}, displayName: ${_this.displayName}, photoUrl: ${_this.photoUrl}, householdIds: ${_this.householdIds}, activeHouseholdId: ${_this.activeHouseholdId}, createdAt: ${_this.createdAt}, lastSignedInAt: ${_this.lastSignedInAt}, legalConsent: ${_this.legalConsent})';
}


}

/// @nodoc
abstract mixin class $AccountCopyWith<$Res>  {
  factory $AccountCopyWith(Account value, $Res Function(Account) _then) = _$AccountCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String displayName, String? photoUrl, List<String> householdIds, String? activeHouseholdId,@ServerTimestampConverter() DateTime? createdAt,@ServerTimestampConverter() DateTime? lastSignedInAt,@JsonKey(includeToJson: false) LegalConsent? legalConsent
});


$LegalConsentCopyWith<$Res>? get legalConsent;

}
/// @nodoc
class _$AccountCopyWithImpl<$Res>
    implements $AccountCopyWith<$Res> {
  _$AccountCopyWithImpl(this._self, this._then);

  final Account _self;
  final $Res Function(Account) _then;

/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? photoUrl = freezed,Object? householdIds = null,Object? activeHouseholdId = freezed,Object? createdAt = freezed,Object? lastSignedInAt = freezed,Object? legalConsent = freezed,}) {
  return _then(Account(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,householdIds: null == householdIds ? _self.householdIds : householdIds // ignore: cast_nullable_to_non_nullable
as List<String>,activeHouseholdId: freezed == activeHouseholdId ? _self.activeHouseholdId : activeHouseholdId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastSignedInAt: freezed == lastSignedInAt ? _self.lastSignedInAt : lastSignedInAt // ignore: cast_nullable_to_non_nullable
as DateTime?,legalConsent: freezed == legalConsent ? _self.legalConsent : legalConsent // ignore: cast_nullable_to_non_nullable
as LegalConsent?,
  ));
}
/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LegalConsentCopyWith<$Res>? get legalConsent {
    if (_self.legalConsent == null) {
    return null;
  }

  return $LegalConsentCopyWith<$Res>(_self.legalConsent!, (value) {
    return _then(_self.copyWith(legalConsent: value));
  });
}
}


/// Adds pattern-matching-related methods to [Account].
extension AccountPatterns on Account {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Account value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Account() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Account value)  $default,){
final _that = this;
switch (_that) {
case _Account():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Account value)?  $default,){
final _that = this;
switch (_that) {
case _Account() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String displayName,  String? photoUrl,  List<String> householdIds,  String? activeHouseholdId, @ServerTimestampConverter()  DateTime? createdAt, @ServerTimestampConverter()  DateTime? lastSignedInAt, @JsonKey(includeToJson: false)  LegalConsent? legalConsent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Account() when $default != null:
return $default(_that.id,_that.displayName,_that.photoUrl,_that.householdIds,_that.activeHouseholdId,_that.createdAt,_that.lastSignedInAt,_that.legalConsent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String displayName,  String? photoUrl,  List<String> householdIds,  String? activeHouseholdId, @ServerTimestampConverter()  DateTime? createdAt, @ServerTimestampConverter()  DateTime? lastSignedInAt, @JsonKey(includeToJson: false)  LegalConsent? legalConsent)  $default,) {final _that = this;
switch (_that) {
case _Account():
return $default(_that.id,_that.displayName,_that.photoUrl,_that.householdIds,_that.activeHouseholdId,_that.createdAt,_that.lastSignedInAt,_that.legalConsent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String displayName,  String? photoUrl,  List<String> householdIds,  String? activeHouseholdId, @ServerTimestampConverter()  DateTime? createdAt, @ServerTimestampConverter()  DateTime? lastSignedInAt, @JsonKey(includeToJson: false)  LegalConsent? legalConsent)?  $default,) {final _that = this;
switch (_that) {
case _Account() when $default != null:
return $default(_that.id,_that.displayName,_that.photoUrl,_that.householdIds,_that.activeHouseholdId,_that.createdAt,_that.lastSignedInAt,_that.legalConsent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Account extends Account {
  const _Account({@JsonKey(includeToJson: false) required this.id, required this.displayName, this.photoUrl,  List<String> householdIds = const <String>[], this.activeHouseholdId, @ServerTimestampConverter() this.createdAt, @ServerTimestampConverter() this.lastSignedInAt, @JsonKey(includeToJson: false) this.legalConsent}): _householdIds = householdIds,super._();
  factory _Account.fromJson(Map<String, dynamic> json) => _$AccountFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String displayName;
@override final  String? photoUrl;
 final  List<String> _householdIds;
@override@JsonKey() List<String> get householdIds {
  if (_householdIds is EqualUnmodifiableListView) return _householdIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_householdIds);
}

@override final  String? activeHouseholdId;
@override@ServerTimestampConverter() final  DateTime? createdAt;
@override@ServerTimestampConverter() final  DateTime? lastSignedInAt;
/// What this person agreed to (accounts ADR-0005). Read here, never
/// written with the rest of the document: the create rule does not allow
/// it, and `acceptLegal` writes it on its own with the server's time.
@override@JsonKey(includeToJson: false) final  LegalConsent? legalConsent;

/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountCopyWith<_Account> get copyWith => __$AccountCopyWithImpl<_Account>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AccountToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Account&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&const DeepCollectionEquality().equals(other.householdIds, _householdIds)&&(identical(other.activeHouseholdId, activeHouseholdId) || other.activeHouseholdId == activeHouseholdId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastSignedInAt, lastSignedInAt) || other.lastSignedInAt == lastSignedInAt)&&(identical(other.legalConsent, legalConsent) || other.legalConsent == legalConsent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,displayName,photoUrl,const DeepCollectionEquality().hash(_householdIds),activeHouseholdId,createdAt,lastSignedInAt,legalConsent);
}

@override
String toString() {
    return 'Account(id: $id, displayName: $displayName, photoUrl: $photoUrl, householdIds: $householdIds, activeHouseholdId: $activeHouseholdId, createdAt: $createdAt, lastSignedInAt: $lastSignedInAt, legalConsent: $legalConsent)';
}


}

/// @nodoc
abstract mixin class _$AccountCopyWith<$Res> implements $AccountCopyWith<$Res> {
  factory _$AccountCopyWith(_Account value, $Res Function(_Account) _then) = __$AccountCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String displayName, String? photoUrl, List<String> householdIds, String? activeHouseholdId,@ServerTimestampConverter() DateTime? createdAt,@ServerTimestampConverter() DateTime? lastSignedInAt,@JsonKey(includeToJson: false) LegalConsent? legalConsent
});


@override $LegalConsentCopyWith<$Res>? get legalConsent;

}
/// @nodoc
class __$AccountCopyWithImpl<$Res>
    implements _$AccountCopyWith<$Res> {
  __$AccountCopyWithImpl(this._self, this._then);

  final _Account _self;
  final $Res Function(_Account) _then;

/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? photoUrl = freezed,Object? householdIds = null,Object? activeHouseholdId = freezed,Object? createdAt = freezed,Object? lastSignedInAt = freezed,Object? legalConsent = freezed,}) {
  return _then(_Account(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,householdIds: null == householdIds ? _self._householdIds : householdIds // ignore: cast_nullable_to_non_nullable
as List<String>,activeHouseholdId: freezed == activeHouseholdId ? _self.activeHouseholdId : activeHouseholdId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastSignedInAt: freezed == lastSignedInAt ? _self.lastSignedInAt : lastSignedInAt // ignore: cast_nullable_to_non_nullable
as DateTime?,legalConsent: freezed == legalConsent ? _self.legalConsent : legalConsent // ignore: cast_nullable_to_non_nullable
as LegalConsent?,
  ));
}

/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LegalConsentCopyWith<$Res>? get legalConsent {
    if (_self.legalConsent == null) {
    return null;
  }

  return $LegalConsentCopyWith<$Res>(_self.legalConsent!, (value) {
    return _then(_self.copyWith(legalConsent: value));
  });
}
}

// dart format on

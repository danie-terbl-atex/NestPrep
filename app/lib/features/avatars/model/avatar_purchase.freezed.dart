// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'avatar_purchase.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AvatarPurchase {

@JsonKey(includeToJson: false) String get id; String get memberId; String get accessoryId;@JsonKey(includeToJson: false, unknownEnumValue: PurchaseStatus.refused) PurchaseStatus? get status;@JsonKey(includeToJson: false, unknownEnumValue: PurchaseRefusal.unknownAccessory) PurchaseRefusal? get reason;
/// Create a copy of AvatarPurchase
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AvatarPurchaseCopyWith<AvatarPurchase> get copyWith => _$AvatarPurchaseCopyWithImpl<AvatarPurchase>(this as AvatarPurchase, _$identity);

  /// Serializes this AvatarPurchase to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AvatarPurchase;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AvatarPurchase&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.memberId, _this.memberId) || other.memberId == _this.memberId)&&(identical(other.accessoryId, _this.accessoryId) || other.accessoryId == _this.accessoryId)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.reason, _this.reason) || other.reason == _this.reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AvatarPurchase;
  return Object.hash(runtimeType,_this.id,_this.memberId,_this.accessoryId,_this.status,_this.reason);
}

@override
String toString() {
  final _this = this as AvatarPurchase;
  return 'AvatarPurchase(id: ${_this.id}, memberId: ${_this.memberId}, accessoryId: ${_this.accessoryId}, status: ${_this.status}, reason: ${_this.reason})';
}


}

/// @nodoc
abstract mixin class $AvatarPurchaseCopyWith<$Res>  {
  factory $AvatarPurchaseCopyWith(AvatarPurchase value, $Res Function(AvatarPurchase) _then) = _$AvatarPurchaseCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String memberId, String accessoryId,@JsonKey(includeToJson: false, unknownEnumValue: PurchaseStatus.refused) PurchaseStatus? status,@JsonKey(includeToJson: false, unknownEnumValue: PurchaseRefusal.unknownAccessory) PurchaseRefusal? reason
});




}
/// @nodoc
class _$AvatarPurchaseCopyWithImpl<$Res>
    implements $AvatarPurchaseCopyWith<$Res> {
  _$AvatarPurchaseCopyWithImpl(this._self, this._then);

  final AvatarPurchase _self;
  final $Res Function(AvatarPurchase) _then;

/// Create a copy of AvatarPurchase
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? memberId = null,Object? accessoryId = null,Object? status = freezed,Object? reason = freezed,}) {
  return _then(AvatarPurchase(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,accessoryId: null == accessoryId ? _self.accessoryId : accessoryId // ignore: cast_nullable_to_non_nullable
as String,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PurchaseStatus?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as PurchaseRefusal?,
  ));
}

}


/// Adds pattern-matching-related methods to [AvatarPurchase].
extension AvatarPurchasePatterns on AvatarPurchase {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AvatarPurchase value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AvatarPurchase() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AvatarPurchase value)  $default,){
final _that = this;
switch (_that) {
case _AvatarPurchase():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AvatarPurchase value)?  $default,){
final _that = this;
switch (_that) {
case _AvatarPurchase() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String memberId,  String accessoryId, @JsonKey(includeToJson: false, unknownEnumValue: PurchaseStatus.refused)  PurchaseStatus? status, @JsonKey(includeToJson: false, unknownEnumValue: PurchaseRefusal.unknownAccessory)  PurchaseRefusal? reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AvatarPurchase() when $default != null:
return $default(_that.id,_that.memberId,_that.accessoryId,_that.status,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String memberId,  String accessoryId, @JsonKey(includeToJson: false, unknownEnumValue: PurchaseStatus.refused)  PurchaseStatus? status, @JsonKey(includeToJson: false, unknownEnumValue: PurchaseRefusal.unknownAccessory)  PurchaseRefusal? reason)  $default,) {final _that = this;
switch (_that) {
case _AvatarPurchase():
return $default(_that.id,_that.memberId,_that.accessoryId,_that.status,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String memberId,  String accessoryId, @JsonKey(includeToJson: false, unknownEnumValue: PurchaseStatus.refused)  PurchaseStatus? status, @JsonKey(includeToJson: false, unknownEnumValue: PurchaseRefusal.unknownAccessory)  PurchaseRefusal? reason)?  $default,) {final _that = this;
switch (_that) {
case _AvatarPurchase() when $default != null:
return $default(_that.id,_that.memberId,_that.accessoryId,_that.status,_that.reason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AvatarPurchase extends AvatarPurchase {
  const _AvatarPurchase({@JsonKey(includeToJson: false) required this.id, required this.memberId, required this.accessoryId, @JsonKey(includeToJson: false, unknownEnumValue: PurchaseStatus.refused) this.status, @JsonKey(includeToJson: false, unknownEnumValue: PurchaseRefusal.unknownAccessory) this.reason}): super._();
  factory _AvatarPurchase.fromJson(Map<String, dynamic> json) => _$AvatarPurchaseFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String memberId;
@override final  String accessoryId;
@override@JsonKey(includeToJson: false, unknownEnumValue: PurchaseStatus.refused) final  PurchaseStatus? status;
@override@JsonKey(includeToJson: false, unknownEnumValue: PurchaseRefusal.unknownAccessory) final  PurchaseRefusal? reason;

/// Create a copy of AvatarPurchase
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AvatarPurchaseCopyWith<_AvatarPurchase> get copyWith => __$AvatarPurchaseCopyWithImpl<_AvatarPurchase>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AvatarPurchaseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AvatarPurchase&&(identical(other.id, id) || other.id == id)&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.accessoryId, accessoryId) || other.accessoryId == accessoryId)&&(identical(other.status, status) || other.status == status)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,memberId,accessoryId,status,reason);
}

@override
String toString() {
    return 'AvatarPurchase(id: $id, memberId: $memberId, accessoryId: $accessoryId, status: $status, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$AvatarPurchaseCopyWith<$Res> implements $AvatarPurchaseCopyWith<$Res> {
  factory _$AvatarPurchaseCopyWith(_AvatarPurchase value, $Res Function(_AvatarPurchase) _then) = __$AvatarPurchaseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String memberId, String accessoryId,@JsonKey(includeToJson: false, unknownEnumValue: PurchaseStatus.refused) PurchaseStatus? status,@JsonKey(includeToJson: false, unknownEnumValue: PurchaseRefusal.unknownAccessory) PurchaseRefusal? reason
});




}
/// @nodoc
class __$AvatarPurchaseCopyWithImpl<$Res>
    implements _$AvatarPurchaseCopyWith<$Res> {
  __$AvatarPurchaseCopyWithImpl(this._self, this._then);

  final _AvatarPurchase _self;
  final $Res Function(_AvatarPurchase) _then;

/// Create a copy of AvatarPurchase
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? memberId = null,Object? accessoryId = null,Object? status = freezed,Object? reason = freezed,}) {
  return _then(_AvatarPurchase(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,accessoryId: null == accessoryId ? _self.accessoryId : accessoryId // ignore: cast_nullable_to_non_nullable
as String,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PurchaseStatus?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as PurchaseRefusal?,
  ));
}


}

// dart format on

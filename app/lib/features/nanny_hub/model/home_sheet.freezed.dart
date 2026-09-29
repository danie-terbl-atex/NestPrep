// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_sheet.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HomeSheet {

@JsonKey(includeToJson: false) String get id; String? get address; String? get medicalAidScheme; String? get medicalAidPlan; String? get medicalAidNumber; String? get updatedBy;@ServerTimestampConverter() DateTime? get updatedAt;
/// Create a copy of HomeSheet
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeSheetCopyWith<HomeSheet> get copyWith => _$HomeSheetCopyWithImpl<HomeSheet>(this as HomeSheet, _$identity);

  /// Serializes this HomeSheet to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HomeSheet;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeSheet&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.address, _this.address) || other.address == _this.address)&&(identical(other.medicalAidScheme, _this.medicalAidScheme) || other.medicalAidScheme == _this.medicalAidScheme)&&(identical(other.medicalAidPlan, _this.medicalAidPlan) || other.medicalAidPlan == _this.medicalAidPlan)&&(identical(other.medicalAidNumber, _this.medicalAidNumber) || other.medicalAidNumber == _this.medicalAidNumber)&&(identical(other.updatedBy, _this.updatedBy) || other.updatedBy == _this.updatedBy)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HomeSheet;
  return Object.hash(runtimeType,_this.id,_this.address,_this.medicalAidScheme,_this.medicalAidPlan,_this.medicalAidNumber,_this.updatedBy,_this.updatedAt);
}

@override
String toString() {
  final _this = this as HomeSheet;
  return 'HomeSheet(id: ${_this.id}, address: ${_this.address}, medicalAidScheme: ${_this.medicalAidScheme}, medicalAidPlan: ${_this.medicalAidPlan}, medicalAidNumber: ${_this.medicalAidNumber}, updatedBy: ${_this.updatedBy}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $HomeSheetCopyWith<$Res>  {
  factory $HomeSheetCopyWith(HomeSheet value, $Res Function(HomeSheet) _then) = _$HomeSheetCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String? address, String? medicalAidScheme, String? medicalAidPlan, String? medicalAidNumber, String? updatedBy,@ServerTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$HomeSheetCopyWithImpl<$Res>
    implements $HomeSheetCopyWith<$Res> {
  _$HomeSheetCopyWithImpl(this._self, this._then);

  final HomeSheet _self;
  final $Res Function(HomeSheet) _then;

/// Create a copy of HomeSheet
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? address = freezed,Object? medicalAidScheme = freezed,Object? medicalAidPlan = freezed,Object? medicalAidNumber = freezed,Object? updatedBy = freezed,Object? updatedAt = freezed,}) {
  return _then(HomeSheet(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,medicalAidScheme: freezed == medicalAidScheme ? _self.medicalAidScheme : medicalAidScheme // ignore: cast_nullable_to_non_nullable
as String?,medicalAidPlan: freezed == medicalAidPlan ? _self.medicalAidPlan : medicalAidPlan // ignore: cast_nullable_to_non_nullable
as String?,medicalAidNumber: freezed == medicalAidNumber ? _self.medicalAidNumber : medicalAidNumber // ignore: cast_nullable_to_non_nullable
as String?,updatedBy: freezed == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [HomeSheet].
extension HomeSheetPatterns on HomeSheet {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeSheet value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeSheet() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeSheet value)  $default,){
final _that = this;
switch (_that) {
case _HomeSheet():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeSheet value)?  $default,){
final _that = this;
switch (_that) {
case _HomeSheet() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String? address,  String? medicalAidScheme,  String? medicalAidPlan,  String? medicalAidNumber,  String? updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeSheet() when $default != null:
return $default(_that.id,_that.address,_that.medicalAidScheme,_that.medicalAidPlan,_that.medicalAidNumber,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String? address,  String? medicalAidScheme,  String? medicalAidPlan,  String? medicalAidNumber,  String? updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _HomeSheet():
return $default(_that.id,_that.address,_that.medicalAidScheme,_that.medicalAidPlan,_that.medicalAidNumber,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String? address,  String? medicalAidScheme,  String? medicalAidPlan,  String? medicalAidNumber,  String? updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _HomeSheet() when $default != null:
return $default(_that.id,_that.address,_that.medicalAidScheme,_that.medicalAidPlan,_that.medicalAidNumber,_that.updatedBy,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HomeSheet extends HomeSheet {
  const _HomeSheet({@JsonKey(includeToJson: false) this.id = HomeSheet.documentId, this.address, this.medicalAidScheme, this.medicalAidPlan, this.medicalAidNumber, this.updatedBy, @ServerTimestampConverter() this.updatedAt}): super._();
  factory _HomeSheet.fromJson(Map<String, dynamic> json) => _$HomeSheetFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String? address;
@override final  String? medicalAidScheme;
@override final  String? medicalAidPlan;
@override final  String? medicalAidNumber;
@override final  String? updatedBy;
@override@ServerTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of HomeSheet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeSheetCopyWith<_HomeSheet> get copyWith => __$HomeSheetCopyWithImpl<_HomeSheet>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HomeSheetToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeSheet&&(identical(other.id, id) || other.id == id)&&(identical(other.address, address) || other.address == address)&&(identical(other.medicalAidScheme, medicalAidScheme) || other.medicalAidScheme == medicalAidScheme)&&(identical(other.medicalAidPlan, medicalAidPlan) || other.medicalAidPlan == medicalAidPlan)&&(identical(other.medicalAidNumber, medicalAidNumber) || other.medicalAidNumber == medicalAidNumber)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,address,medicalAidScheme,medicalAidPlan,medicalAidNumber,updatedBy,updatedAt);
}

@override
String toString() {
    return 'HomeSheet(id: $id, address: $address, medicalAidScheme: $medicalAidScheme, medicalAidPlan: $medicalAidPlan, medicalAidNumber: $medicalAidNumber, updatedBy: $updatedBy, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$HomeSheetCopyWith<$Res> implements $HomeSheetCopyWith<$Res> {
  factory _$HomeSheetCopyWith(_HomeSheet value, $Res Function(_HomeSheet) _then) = __$HomeSheetCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String? address, String? medicalAidScheme, String? medicalAidPlan, String? medicalAidNumber, String? updatedBy,@ServerTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$HomeSheetCopyWithImpl<$Res>
    implements _$HomeSheetCopyWith<$Res> {
  __$HomeSheetCopyWithImpl(this._self, this._then);

  final _HomeSheet _self;
  final $Res Function(_HomeSheet) _then;

/// Create a copy of HomeSheet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? address = freezed,Object? medicalAidScheme = freezed,Object? medicalAidPlan = freezed,Object? medicalAidNumber = freezed,Object? updatedBy = freezed,Object? updatedAt = freezed,}) {
  return _then(_HomeSheet(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,medicalAidScheme: freezed == medicalAidScheme ? _self.medicalAidScheme : medicalAidScheme // ignore: cast_nullable_to_non_nullable
as String?,medicalAidPlan: freezed == medicalAidPlan ? _self.medicalAidPlan : medicalAidPlan // ignore: cast_nullable_to_non_nullable
as String?,medicalAidNumber: freezed == medicalAidNumber ? _self.medicalAidNumber : medicalAidNumber // ignore: cast_nullable_to_non_nullable
as String?,updatedBy: freezed == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

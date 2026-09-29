// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'grocery_plan_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GroceryPlanSettings {

/// Add and take off proposed items as the plans change, without asking —
/// never touching what a person typed or ticked. Off until a parent turns
/// it on.
 bool get keepInStep;/// Normalised names marked *usually in the house*: never proposed. A skip
/// list, not a re-add list — nothing is ever added from it.
 List<String> get staples;/// The member who last changed either, so the sheet can say who.
 String? get updatedBy;@ServerTimestampConverter() DateTime? get updatedAt;
/// Create a copy of GroceryPlanSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroceryPlanSettingsCopyWith<GroceryPlanSettings> get copyWith => _$GroceryPlanSettingsCopyWithImpl<GroceryPlanSettings>(this as GroceryPlanSettings, _$identity);

  /// Serializes this GroceryPlanSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GroceryPlanSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroceryPlanSettings&&(identical(other.keepInStep, _this.keepInStep) || other.keepInStep == _this.keepInStep)&&const DeepCollectionEquality().equals(other.staples, _this.staples)&&(identical(other.updatedBy, _this.updatedBy) || other.updatedBy == _this.updatedBy)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GroceryPlanSettings;
  return Object.hash(runtimeType,_this.keepInStep,const DeepCollectionEquality().hash(_this.staples),_this.updatedBy,_this.updatedAt);
}

@override
String toString() {
  final _this = this as GroceryPlanSettings;
  return 'GroceryPlanSettings(keepInStep: ${_this.keepInStep}, staples: ${_this.staples}, updatedBy: ${_this.updatedBy}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $GroceryPlanSettingsCopyWith<$Res>  {
  factory $GroceryPlanSettingsCopyWith(GroceryPlanSettings value, $Res Function(GroceryPlanSettings) _then) = _$GroceryPlanSettingsCopyWithImpl;
@useResult
$Res call({
 bool keepInStep, List<String> staples, String? updatedBy,@ServerTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$GroceryPlanSettingsCopyWithImpl<$Res>
    implements $GroceryPlanSettingsCopyWith<$Res> {
  _$GroceryPlanSettingsCopyWithImpl(this._self, this._then);

  final GroceryPlanSettings _self;
  final $Res Function(GroceryPlanSettings) _then;

/// Create a copy of GroceryPlanSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? keepInStep = null,Object? staples = null,Object? updatedBy = freezed,Object? updatedAt = freezed,}) {
  return _then(GroceryPlanSettings(
keepInStep: null == keepInStep ? _self.keepInStep : keepInStep // ignore: cast_nullable_to_non_nullable
as bool,staples: null == staples ? _self.staples : staples // ignore: cast_nullable_to_non_nullable
as List<String>,updatedBy: freezed == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [GroceryPlanSettings].
extension GroceryPlanSettingsPatterns on GroceryPlanSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroceryPlanSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroceryPlanSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroceryPlanSettings value)  $default,){
final _that = this;
switch (_that) {
case _GroceryPlanSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroceryPlanSettings value)?  $default,){
final _that = this;
switch (_that) {
case _GroceryPlanSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool keepInStep,  List<String> staples,  String? updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroceryPlanSettings() when $default != null:
return $default(_that.keepInStep,_that.staples,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool keepInStep,  List<String> staples,  String? updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _GroceryPlanSettings():
return $default(_that.keepInStep,_that.staples,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool keepInStep,  List<String> staples,  String? updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _GroceryPlanSettings() when $default != null:
return $default(_that.keepInStep,_that.staples,_that.updatedBy,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroceryPlanSettings extends GroceryPlanSettings {
  const _GroceryPlanSettings({this.keepInStep = false,  List<String> staples = const <String>[], this.updatedBy, @ServerTimestampConverter() this.updatedAt}): _staples = staples,super._();
  factory _GroceryPlanSettings.fromJson(Map<String, dynamic> json) => _$GroceryPlanSettingsFromJson(json);

/// Add and take off proposed items as the plans change, without asking —
/// never touching what a person typed or ticked. Off until a parent turns
/// it on.
@override@JsonKey() final  bool keepInStep;
/// Normalised names marked *usually in the house*: never proposed. A skip
/// list, not a re-add list — nothing is ever added from it.
 final  List<String> _staples;
/// Normalised names marked *usually in the house*: never proposed. A skip
/// list, not a re-add list — nothing is ever added from it.
@override@JsonKey() List<String> get staples {
  if (_staples is EqualUnmodifiableListView) return _staples;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_staples);
}

/// The member who last changed either, so the sheet can say who.
@override final  String? updatedBy;
@override@ServerTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of GroceryPlanSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroceryPlanSettingsCopyWith<_GroceryPlanSettings> get copyWith => __$GroceryPlanSettingsCopyWithImpl<_GroceryPlanSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroceryPlanSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroceryPlanSettings&&(identical(other.keepInStep, keepInStep) || other.keepInStep == keepInStep)&&const DeepCollectionEquality().equals(other.staples, _staples)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,keepInStep,const DeepCollectionEquality().hash(_staples),updatedBy,updatedAt);
}

@override
String toString() {
    return 'GroceryPlanSettings(keepInStep: $keepInStep, staples: $staples, updatedBy: $updatedBy, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$GroceryPlanSettingsCopyWith<$Res> implements $GroceryPlanSettingsCopyWith<$Res> {
  factory _$GroceryPlanSettingsCopyWith(_GroceryPlanSettings value, $Res Function(_GroceryPlanSettings) _then) = __$GroceryPlanSettingsCopyWithImpl;
@override @useResult
$Res call({
 bool keepInStep, List<String> staples, String? updatedBy,@ServerTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$GroceryPlanSettingsCopyWithImpl<$Res>
    implements _$GroceryPlanSettingsCopyWith<$Res> {
  __$GroceryPlanSettingsCopyWithImpl(this._self, this._then);

  final _GroceryPlanSettings _self;
  final $Res Function(_GroceryPlanSettings) _then;

/// Create a copy of GroceryPlanSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? keepInStep = null,Object? staples = null,Object? updatedBy = freezed,Object? updatedAt = freezed,}) {
  return _then(_GroceryPlanSettings(
keepInStep: null == keepInStep ? _self.keepInStep : keepInStep // ignore: cast_nullable_to_non_nullable
as bool,staples: null == staples ? _self._staples : staples // ignore: cast_nullable_to_non_nullable
as List<String>,updatedBy: freezed == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

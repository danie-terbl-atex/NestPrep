// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'assistant_activity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AssistantActivity {

@JsonKey(includeToJson: false) String get id; String get grantId; String get memberId;@JsonKey(unknownEnumValue: AssistantVia.assistant) AssistantVia get via; String get tool;@NullableTimestampConverter() DateTime? get at;
/// Create a copy of AssistantActivity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssistantActivityCopyWith<AssistantActivity> get copyWith => _$AssistantActivityCopyWithImpl<AssistantActivity>(this as AssistantActivity, _$identity);

  /// Serializes this AssistantActivity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AssistantActivity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssistantActivity&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.grantId, _this.grantId) || other.grantId == _this.grantId)&&(identical(other.memberId, _this.memberId) || other.memberId == _this.memberId)&&(identical(other.via, _this.via) || other.via == _this.via)&&(identical(other.tool, _this.tool) || other.tool == _this.tool)&&(identical(other.at, _this.at) || other.at == _this.at));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AssistantActivity;
  return Object.hash(runtimeType,_this.id,_this.grantId,_this.memberId,_this.via,_this.tool,_this.at);
}

@override
String toString() {
  final _this = this as AssistantActivity;
  return 'AssistantActivity(id: ${_this.id}, grantId: ${_this.grantId}, memberId: ${_this.memberId}, via: ${_this.via}, tool: ${_this.tool}, at: ${_this.at})';
}


}

/// @nodoc
abstract mixin class $AssistantActivityCopyWith<$Res>  {
  factory $AssistantActivityCopyWith(AssistantActivity value, $Res Function(AssistantActivity) _then) = _$AssistantActivityCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String grantId, String memberId,@JsonKey(unknownEnumValue: AssistantVia.assistant) AssistantVia via, String tool,@NullableTimestampConverter() DateTime? at
});




}
/// @nodoc
class _$AssistantActivityCopyWithImpl<$Res>
    implements $AssistantActivityCopyWith<$Res> {
  _$AssistantActivityCopyWithImpl(this._self, this._then);

  final AssistantActivity _self;
  final $Res Function(AssistantActivity) _then;

/// Create a copy of AssistantActivity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? grantId = null,Object? memberId = null,Object? via = null,Object? tool = null,Object? at = freezed,}) {
  return _then(AssistantActivity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,grantId: null == grantId ? _self.grantId : grantId // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,via: null == via ? _self.via : via // ignore: cast_nullable_to_non_nullable
as AssistantVia,tool: null == tool ? _self.tool : tool // ignore: cast_nullable_to_non_nullable
as String,at: freezed == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AssistantActivity].
extension AssistantActivityPatterns on AssistantActivity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssistantActivity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssistantActivity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssistantActivity value)  $default,){
final _that = this;
switch (_that) {
case _AssistantActivity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssistantActivity value)?  $default,){
final _that = this;
switch (_that) {
case _AssistantActivity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String grantId,  String memberId, @JsonKey(unknownEnumValue: AssistantVia.assistant)  AssistantVia via,  String tool, @NullableTimestampConverter()  DateTime? at)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssistantActivity() when $default != null:
return $default(_that.id,_that.grantId,_that.memberId,_that.via,_that.tool,_that.at);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String grantId,  String memberId, @JsonKey(unknownEnumValue: AssistantVia.assistant)  AssistantVia via,  String tool, @NullableTimestampConverter()  DateTime? at)  $default,) {final _that = this;
switch (_that) {
case _AssistantActivity():
return $default(_that.id,_that.grantId,_that.memberId,_that.via,_that.tool,_that.at);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String grantId,  String memberId, @JsonKey(unknownEnumValue: AssistantVia.assistant)  AssistantVia via,  String tool, @NullableTimestampConverter()  DateTime? at)?  $default,) {final _that = this;
switch (_that) {
case _AssistantActivity() when $default != null:
return $default(_that.id,_that.grantId,_that.memberId,_that.via,_that.tool,_that.at);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssistantActivity implements AssistantActivity {
  const _AssistantActivity({@JsonKey(includeToJson: false) required this.id, required this.grantId, required this.memberId, @JsonKey(unknownEnumValue: AssistantVia.assistant) this.via = AssistantVia.assistant, required this.tool, @NullableTimestampConverter() this.at});
  factory _AssistantActivity.fromJson(Map<String, dynamic> json) => _$AssistantActivityFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String grantId;
@override final  String memberId;
@override@JsonKey(unknownEnumValue: AssistantVia.assistant) final  AssistantVia via;
@override final  String tool;
@override@NullableTimestampConverter() final  DateTime? at;

/// Create a copy of AssistantActivity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssistantActivityCopyWith<_AssistantActivity> get copyWith => __$AssistantActivityCopyWithImpl<_AssistantActivity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssistantActivityToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssistantActivity&&(identical(other.id, id) || other.id == id)&&(identical(other.grantId, grantId) || other.grantId == grantId)&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.via, via) || other.via == via)&&(identical(other.tool, tool) || other.tool == tool)&&(identical(other.at, at) || other.at == at));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,grantId,memberId,via,tool,at);
}

@override
String toString() {
    return 'AssistantActivity(id: $id, grantId: $grantId, memberId: $memberId, via: $via, tool: $tool, at: $at)';
}


}

/// @nodoc
abstract mixin class _$AssistantActivityCopyWith<$Res> implements $AssistantActivityCopyWith<$Res> {
  factory _$AssistantActivityCopyWith(_AssistantActivity value, $Res Function(_AssistantActivity) _then) = __$AssistantActivityCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String grantId, String memberId,@JsonKey(unknownEnumValue: AssistantVia.assistant) AssistantVia via, String tool,@NullableTimestampConverter() DateTime? at
});




}
/// @nodoc
class __$AssistantActivityCopyWithImpl<$Res>
    implements _$AssistantActivityCopyWith<$Res> {
  __$AssistantActivityCopyWithImpl(this._self, this._then);

  final _AssistantActivity _self;
  final $Res Function(_AssistantActivity) _then;

/// Create a copy of AssistantActivity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? grantId = null,Object? memberId = null,Object? via = null,Object? tool = null,Object? at = freezed,}) {
  return _then(_AssistantActivity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,grantId: null == grantId ? _self.grantId : grantId // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,via: null == via ? _self.via : via // ignore: cast_nullable_to_non_nullable
as AssistantVia,tool: null == tool ? _self.tool : tool // ignore: cast_nullable_to_non_nullable
as String,at: freezed == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

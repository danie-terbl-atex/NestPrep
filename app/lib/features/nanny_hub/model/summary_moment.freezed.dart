// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'summary_moment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SummaryMoment {

@JsonKey(unknownEnumValue: HandoverKind.note) HandoverKind get kind;@InstantConverter() DateTime get at; String? get note;@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) HandoverMood? get mood; List<String> get childIds; bool get hasPhoto;
/// Create a copy of SummaryMoment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SummaryMomentCopyWith<SummaryMoment> get copyWith => _$SummaryMomentCopyWithImpl<SummaryMoment>(this as SummaryMoment, _$identity);

  /// Serializes this SummaryMoment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SummaryMoment;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SummaryMoment&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.at, _this.at) || other.at == _this.at)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.mood, _this.mood) || other.mood == _this.mood)&&const DeepCollectionEquality().equals(other.childIds, _this.childIds)&&(identical(other.hasPhoto, _this.hasPhoto) || other.hasPhoto == _this.hasPhoto));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SummaryMoment;
  return Object.hash(runtimeType,_this.kind,_this.at,_this.note,_this.mood,const DeepCollectionEquality().hash(_this.childIds),_this.hasPhoto);
}

@override
String toString() {
  final _this = this as SummaryMoment;
  return 'SummaryMoment(kind: ${_this.kind}, at: ${_this.at}, note: ${_this.note}, mood: ${_this.mood}, childIds: ${_this.childIds}, hasPhoto: ${_this.hasPhoto})';
}


}

/// @nodoc
abstract mixin class $SummaryMomentCopyWith<$Res>  {
  factory $SummaryMomentCopyWith(SummaryMoment value, $Res Function(SummaryMoment) _then) = _$SummaryMomentCopyWithImpl;
@useResult
$Res call({
@JsonKey(unknownEnumValue: HandoverKind.note) HandoverKind kind,@InstantConverter() DateTime at, String? note,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) HandoverMood? mood, List<String> childIds, bool hasPhoto
});




}
/// @nodoc
class _$SummaryMomentCopyWithImpl<$Res>
    implements $SummaryMomentCopyWith<$Res> {
  _$SummaryMomentCopyWithImpl(this._self, this._then);

  final SummaryMoment _self;
  final $Res Function(SummaryMoment) _then;

/// Create a copy of SummaryMoment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? at = null,Object? note = freezed,Object? mood = freezed,Object? childIds = null,Object? hasPhoto = null,}) {
  return _then(SummaryMoment(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as HandoverKind,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,mood: freezed == mood ? _self.mood : mood // ignore: cast_nullable_to_non_nullable
as HandoverMood?,childIds: null == childIds ? _self.childIds : childIds // ignore: cast_nullable_to_non_nullable
as List<String>,hasPhoto: null == hasPhoto ? _self.hasPhoto : hasPhoto // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SummaryMoment].
extension SummaryMomentPatterns on SummaryMoment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SummaryMoment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SummaryMoment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SummaryMoment value)  $default,){
final _that = this;
switch (_that) {
case _SummaryMoment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SummaryMoment value)?  $default,){
final _that = this;
switch (_that) {
case _SummaryMoment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: HandoverKind.note)  HandoverKind kind, @InstantConverter()  DateTime at,  String? note, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  HandoverMood? mood,  List<String> childIds,  bool hasPhoto)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SummaryMoment() when $default != null:
return $default(_that.kind,_that.at,_that.note,_that.mood,_that.childIds,_that.hasPhoto);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: HandoverKind.note)  HandoverKind kind, @InstantConverter()  DateTime at,  String? note, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  HandoverMood? mood,  List<String> childIds,  bool hasPhoto)  $default,) {final _that = this;
switch (_that) {
case _SummaryMoment():
return $default(_that.kind,_that.at,_that.note,_that.mood,_that.childIds,_that.hasPhoto);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(unknownEnumValue: HandoverKind.note)  HandoverKind kind, @InstantConverter()  DateTime at,  String? note, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  HandoverMood? mood,  List<String> childIds,  bool hasPhoto)?  $default,) {final _that = this;
switch (_that) {
case _SummaryMoment() when $default != null:
return $default(_that.kind,_that.at,_that.note,_that.mood,_that.childIds,_that.hasPhoto);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SummaryMoment implements SummaryMoment {
  const _SummaryMoment({@JsonKey(unknownEnumValue: HandoverKind.note) required this.kind, @InstantConverter() required this.at, this.note, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) this.mood,  List<String> childIds = const <String>[], this.hasPhoto = false}): _childIds = childIds;
  factory _SummaryMoment.fromJson(Map<String, dynamic> json) => _$SummaryMomentFromJson(json);

@override@JsonKey(unknownEnumValue: HandoverKind.note) final  HandoverKind kind;
@override@InstantConverter() final  DateTime at;
@override final  String? note;
@override@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) final  HandoverMood? mood;
 final  List<String> _childIds;
@override@JsonKey() List<String> get childIds {
  if (_childIds is EqualUnmodifiableListView) return _childIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_childIds);
}

@override@JsonKey() final  bool hasPhoto;

/// Create a copy of SummaryMoment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SummaryMomentCopyWith<_SummaryMoment> get copyWith => __$SummaryMomentCopyWithImpl<_SummaryMoment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SummaryMomentToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SummaryMoment&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.at, at) || other.at == at)&&(identical(other.note, note) || other.note == note)&&(identical(other.mood, mood) || other.mood == mood)&&const DeepCollectionEquality().equals(other.childIds, _childIds)&&(identical(other.hasPhoto, hasPhoto) || other.hasPhoto == hasPhoto));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,at,note,mood,const DeepCollectionEquality().hash(_childIds),hasPhoto);
}

@override
String toString() {
    return 'SummaryMoment(kind: $kind, at: $at, note: $note, mood: $mood, childIds: $childIds, hasPhoto: $hasPhoto)';
}


}

/// @nodoc
abstract mixin class _$SummaryMomentCopyWith<$Res> implements $SummaryMomentCopyWith<$Res> {
  factory _$SummaryMomentCopyWith(_SummaryMoment value, $Res Function(_SummaryMoment) _then) = __$SummaryMomentCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(unknownEnumValue: HandoverKind.note) HandoverKind kind,@InstantConverter() DateTime at, String? note,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) HandoverMood? mood, List<String> childIds, bool hasPhoto
});




}
/// @nodoc
class __$SummaryMomentCopyWithImpl<$Res>
    implements _$SummaryMomentCopyWith<$Res> {
  __$SummaryMomentCopyWithImpl(this._self, this._then);

  final _SummaryMoment _self;
  final $Res Function(_SummaryMoment) _then;

/// Create a copy of SummaryMoment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? at = null,Object? note = freezed,Object? mood = freezed,Object? childIds = null,Object? hasPhoto = null,}) {
  return _then(_SummaryMoment(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as HandoverKind,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,mood: freezed == mood ? _self.mood : mood // ignore: cast_nullable_to_non_nullable
as HandoverMood?,childIds: null == childIds ? _self._childIds : childIds // ignore: cast_nullable_to_non_nullable
as List<String>,hasPhoto: null == hasPhoto ? _self.hasPhoto : hasPhoto // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lunch_feedback.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LunchFeedback {

/// `LunchVerdict.name`, as stored.
 String get verdict;/// Slot name → `LunchVerdict.name`, for the things somebody marked one by
/// one. A slot not here was judged with the box.
 Map<String, String> get items;/// The member who marked it.
 String get by;@ServerTimestampConverter() DateTime? get at;
/// Create a copy of LunchFeedback
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LunchFeedbackCopyWith<LunchFeedback> get copyWith => _$LunchFeedbackCopyWithImpl<LunchFeedback>(this as LunchFeedback, _$identity);

  /// Serializes this LunchFeedback to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LunchFeedback;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LunchFeedback&&(identical(other.verdict, _this.verdict) || other.verdict == _this.verdict)&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.by, _this.by) || other.by == _this.by)&&(identical(other.at, _this.at) || other.at == _this.at));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LunchFeedback;
  return Object.hash(runtimeType,_this.verdict,const DeepCollectionEquality().hash(_this.items),_this.by,_this.at);
}

@override
String toString() {
  final _this = this as LunchFeedback;
  return 'LunchFeedback(verdict: ${_this.verdict}, items: ${_this.items}, by: ${_this.by}, at: ${_this.at})';
}


}

/// @nodoc
abstract mixin class $LunchFeedbackCopyWith<$Res>  {
  factory $LunchFeedbackCopyWith(LunchFeedback value, $Res Function(LunchFeedback) _then) = _$LunchFeedbackCopyWithImpl;
@useResult
$Res call({
 String verdict, Map<String, String> items, String by,@ServerTimestampConverter() DateTime? at
});




}
/// @nodoc
class _$LunchFeedbackCopyWithImpl<$Res>
    implements $LunchFeedbackCopyWith<$Res> {
  _$LunchFeedbackCopyWithImpl(this._self, this._then);

  final LunchFeedback _self;
  final $Res Function(LunchFeedback) _then;

/// Create a copy of LunchFeedback
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? verdict = null,Object? items = null,Object? by = null,Object? at = freezed,}) {
  return _then(LunchFeedback(
verdict: null == verdict ? _self.verdict : verdict // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as Map<String, String>,by: null == by ? _self.by : by // ignore: cast_nullable_to_non_nullable
as String,at: freezed == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [LunchFeedback].
extension LunchFeedbackPatterns on LunchFeedback {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LunchFeedback value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LunchFeedback() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LunchFeedback value)  $default,){
final _that = this;
switch (_that) {
case _LunchFeedback():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LunchFeedback value)?  $default,){
final _that = this;
switch (_that) {
case _LunchFeedback() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String verdict,  Map<String, String> items,  String by, @ServerTimestampConverter()  DateTime? at)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LunchFeedback() when $default != null:
return $default(_that.verdict,_that.items,_that.by,_that.at);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String verdict,  Map<String, String> items,  String by, @ServerTimestampConverter()  DateTime? at)  $default,) {final _that = this;
switch (_that) {
case _LunchFeedback():
return $default(_that.verdict,_that.items,_that.by,_that.at);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String verdict,  Map<String, String> items,  String by, @ServerTimestampConverter()  DateTime? at)?  $default,) {final _that = this;
switch (_that) {
case _LunchFeedback() when $default != null:
return $default(_that.verdict,_that.items,_that.by,_that.at);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LunchFeedback extends LunchFeedback {
  const _LunchFeedback({required this.verdict,  Map<String, String> items = const <String, String>{}, required this.by, @ServerTimestampConverter() this.at}): _items = items,super._();
  factory _LunchFeedback.fromJson(Map<String, dynamic> json) => _$LunchFeedbackFromJson(json);

/// `LunchVerdict.name`, as stored.
@override final  String verdict;
/// Slot name → `LunchVerdict.name`, for the things somebody marked one by
/// one. A slot not here was judged with the box.
 final  Map<String, String> _items;
/// Slot name → `LunchVerdict.name`, for the things somebody marked one by
/// one. A slot not here was judged with the box.
@override@JsonKey() Map<String, String> get items {
  if (_items is EqualUnmodifiableMapView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_items);
}

/// The member who marked it.
@override final  String by;
@override@ServerTimestampConverter() final  DateTime? at;

/// Create a copy of LunchFeedback
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LunchFeedbackCopyWith<_LunchFeedback> get copyWith => __$LunchFeedbackCopyWithImpl<_LunchFeedback>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LunchFeedbackToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LunchFeedback&&(identical(other.verdict, verdict) || other.verdict == verdict)&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.by, by) || other.by == by)&&(identical(other.at, at) || other.at == at));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,verdict,const DeepCollectionEquality().hash(_items),by,at);
}

@override
String toString() {
    return 'LunchFeedback(verdict: $verdict, items: $items, by: $by, at: $at)';
}


}

/// @nodoc
abstract mixin class _$LunchFeedbackCopyWith<$Res> implements $LunchFeedbackCopyWith<$Res> {
  factory _$LunchFeedbackCopyWith(_LunchFeedback value, $Res Function(_LunchFeedback) _then) = __$LunchFeedbackCopyWithImpl;
@override @useResult
$Res call({
 String verdict, Map<String, String> items, String by,@ServerTimestampConverter() DateTime? at
});




}
/// @nodoc
class __$LunchFeedbackCopyWithImpl<$Res>
    implements _$LunchFeedbackCopyWith<$Res> {
  __$LunchFeedbackCopyWithImpl(this._self, this._then);

  final _LunchFeedback _self;
  final $Res Function(_LunchFeedback) _then;

/// Create a copy of LunchFeedback
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? verdict = null,Object? items = null,Object? by = null,Object? at = freezed,}) {
  return _then(_LunchFeedback(
verdict: null == verdict ? _self.verdict : verdict // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as Map<String, String>,by: null == by ? _self.by : by // ignore: cast_nullable_to_non_nullable
as String,at: freezed == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

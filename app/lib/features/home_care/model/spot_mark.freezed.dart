// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'spot_mark.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SpotMark {

 List<double> get points;
/// Create a copy of SpotMark
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpotMarkCopyWith<SpotMark> get copyWith => _$SpotMarkCopyWithImpl<SpotMark>(this as SpotMark, _$identity);

  /// Serializes this SpotMark to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SpotMark;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpotMark&&const DeepCollectionEquality().equals(other.points, _this.points));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SpotMark;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.points));
}

@override
String toString() {
  final _this = this as SpotMark;
  return 'SpotMark(points: ${_this.points})';
}


}

/// @nodoc
abstract mixin class $SpotMarkCopyWith<$Res>  {
  factory $SpotMarkCopyWith(SpotMark value, $Res Function(SpotMark) _then) = _$SpotMarkCopyWithImpl;
@useResult
$Res call({
 List<double> points
});




}
/// @nodoc
class _$SpotMarkCopyWithImpl<$Res>
    implements $SpotMarkCopyWith<$Res> {
  _$SpotMarkCopyWithImpl(this._self, this._then);

  final SpotMark _self;
  final $Res Function(SpotMark) _then;

/// Create a copy of SpotMark
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? points = null,}) {
  return _then(SpotMark(
points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as List<double>,
  ));
}

}


/// Adds pattern-matching-related methods to [SpotMark].
extension SpotMarkPatterns on SpotMark {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpotMark value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpotMark() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpotMark value)  $default,){
final _that = this;
switch (_that) {
case _SpotMark():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpotMark value)?  $default,){
final _that = this;
switch (_that) {
case _SpotMark() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<double> points)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpotMark() when $default != null:
return $default(_that.points);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<double> points)  $default,) {final _that = this;
switch (_that) {
case _SpotMark():
return $default(_that.points);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<double> points)?  $default,) {final _that = this;
switch (_that) {
case _SpotMark() when $default != null:
return $default(_that.points);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SpotMark extends SpotMark {
  const _SpotMark({ List<double> points = const <double>[]}): _points = points,super._();
  factory _SpotMark.fromJson(Map<String, dynamic> json) => _$SpotMarkFromJson(json);

 final  List<double> _points;
@override@JsonKey() List<double> get points {
  if (_points is EqualUnmodifiableListView) return _points;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_points);
}


/// Create a copy of SpotMark
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpotMarkCopyWith<_SpotMark> get copyWith => __$SpotMarkCopyWithImpl<_SpotMark>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SpotMarkToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpotMark&&const DeepCollectionEquality().equals(other.points, _points));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_points));
}

@override
String toString() {
    return 'SpotMark(points: $points)';
}


}

/// @nodoc
abstract mixin class _$SpotMarkCopyWith<$Res> implements $SpotMarkCopyWith<$Res> {
  factory _$SpotMarkCopyWith(_SpotMark value, $Res Function(_SpotMark) _then) = __$SpotMarkCopyWithImpl;
@override @useResult
$Res call({
 List<double> points
});




}
/// @nodoc
class __$SpotMarkCopyWithImpl<$Res>
    implements _$SpotMarkCopyWith<$Res> {
  __$SpotMarkCopyWithImpl(this._self, this._then);

  final _SpotMark _self;
  final $Res Function(_SpotMark) _then;

/// Create a copy of SpotMark
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? points = null,}) {
  return _then(_SpotMark(
points: null == points ? _self._points : points // ignore: cast_nullable_to_non_nullable
as List<double>,
  ));
}


}

// dart format on

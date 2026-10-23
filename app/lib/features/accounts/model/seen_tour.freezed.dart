// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'seen_tour.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SeenTour {

 int get version;@ServerTimestampConverter() DateTime? get seenAt;
/// Create a copy of SeenTour
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SeenTourCopyWith<SeenTour> get copyWith => _$SeenTourCopyWithImpl<SeenTour>(this as SeenTour, _$identity);

  /// Serializes this SeenTour to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SeenTour;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SeenTour&&(identical(other.version, _this.version) || other.version == _this.version)&&(identical(other.seenAt, _this.seenAt) || other.seenAt == _this.seenAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SeenTour;
  return Object.hash(runtimeType,_this.version,_this.seenAt);
}

@override
String toString() {
  final _this = this as SeenTour;
  return 'SeenTour(version: ${_this.version}, seenAt: ${_this.seenAt})';
}


}

/// @nodoc
abstract mixin class $SeenTourCopyWith<$Res>  {
  factory $SeenTourCopyWith(SeenTour value, $Res Function(SeenTour) _then) = _$SeenTourCopyWithImpl;
@useResult
$Res call({
 int version,@ServerTimestampConverter() DateTime? seenAt
});




}
/// @nodoc
class _$SeenTourCopyWithImpl<$Res>
    implements $SeenTourCopyWith<$Res> {
  _$SeenTourCopyWithImpl(this._self, this._then);

  final SeenTour _self;
  final $Res Function(SeenTour) _then;

/// Create a copy of SeenTour
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? seenAt = freezed,}) {
  return _then(SeenTour(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,seenAt: freezed == seenAt ? _self.seenAt : seenAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [SeenTour].
extension SeenTourPatterns on SeenTour {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SeenTour value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SeenTour() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SeenTour value)  $default,){
final _that = this;
switch (_that) {
case _SeenTour():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SeenTour value)?  $default,){
final _that = this;
switch (_that) {
case _SeenTour() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int version, @ServerTimestampConverter()  DateTime? seenAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SeenTour() when $default != null:
return $default(_that.version,_that.seenAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int version, @ServerTimestampConverter()  DateTime? seenAt)  $default,) {final _that = this;
switch (_that) {
case _SeenTour():
return $default(_that.version,_that.seenAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int version, @ServerTimestampConverter()  DateTime? seenAt)?  $default,) {final _that = this;
switch (_that) {
case _SeenTour() when $default != null:
return $default(_that.version,_that.seenAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SeenTour implements SeenTour {
  const _SeenTour({required this.version, @ServerTimestampConverter() this.seenAt});
  factory _SeenTour.fromJson(Map<String, dynamic> json) => _$SeenTourFromJson(json);

@override final  int version;
@override@ServerTimestampConverter() final  DateTime? seenAt;

/// Create a copy of SeenTour
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SeenTourCopyWith<_SeenTour> get copyWith => __$SeenTourCopyWithImpl<_SeenTour>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SeenTourToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SeenTour&&(identical(other.version, version) || other.version == version)&&(identical(other.seenAt, seenAt) || other.seenAt == seenAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,version,seenAt);
}

@override
String toString() {
    return 'SeenTour(version: $version, seenAt: $seenAt)';
}


}

/// @nodoc
abstract mixin class _$SeenTourCopyWith<$Res> implements $SeenTourCopyWith<$Res> {
  factory _$SeenTourCopyWith(_SeenTour value, $Res Function(_SeenTour) _then) = __$SeenTourCopyWithImpl;
@override @useResult
$Res call({
 int version,@ServerTimestampConverter() DateTime? seenAt
});




}
/// @nodoc
class __$SeenTourCopyWithImpl<$Res>
    implements _$SeenTourCopyWith<$Res> {
  __$SeenTourCopyWithImpl(this._self, this._then);

  final _SeenTour _self;
  final $Res Function(_SeenTour) _then;

/// Create a copy of SeenTour
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? seenAt = freezed,}) {
  return _then(_SeenTour(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,seenAt: freezed == seenAt ? _self.seenAt : seenAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

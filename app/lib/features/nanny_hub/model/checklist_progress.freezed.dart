// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'checklist_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChecklistProgress {

 int get ticked; int get total;
/// Create a copy of ChecklistProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChecklistProgressCopyWith<ChecklistProgress> get copyWith => _$ChecklistProgressCopyWithImpl<ChecklistProgress>(this as ChecklistProgress, _$identity);

  /// Serializes this ChecklistProgress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChecklistProgress;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChecklistProgress&&(identical(other.ticked, _this.ticked) || other.ticked == _this.ticked)&&(identical(other.total, _this.total) || other.total == _this.total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChecklistProgress;
  return Object.hash(runtimeType,_this.ticked,_this.total);
}

@override
String toString() {
  final _this = this as ChecklistProgress;
  return 'ChecklistProgress(ticked: ${_this.ticked}, total: ${_this.total})';
}


}

/// @nodoc
abstract mixin class $ChecklistProgressCopyWith<$Res>  {
  factory $ChecklistProgressCopyWith(ChecklistProgress value, $Res Function(ChecklistProgress) _then) = _$ChecklistProgressCopyWithImpl;
@useResult
$Res call({
 int ticked, int total
});




}
/// @nodoc
class _$ChecklistProgressCopyWithImpl<$Res>
    implements $ChecklistProgressCopyWith<$Res> {
  _$ChecklistProgressCopyWithImpl(this._self, this._then);

  final ChecklistProgress _self;
  final $Res Function(ChecklistProgress) _then;

/// Create a copy of ChecklistProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ticked = null,Object? total = null,}) {
  return _then(ChecklistProgress(
ticked: null == ticked ? _self.ticked : ticked // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ChecklistProgress].
extension ChecklistProgressPatterns on ChecklistProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChecklistProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChecklistProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChecklistProgress value)  $default,){
final _that = this;
switch (_that) {
case _ChecklistProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChecklistProgress value)?  $default,){
final _that = this;
switch (_that) {
case _ChecklistProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int ticked,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChecklistProgress() when $default != null:
return $default(_that.ticked,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int ticked,  int total)  $default,) {final _that = this;
switch (_that) {
case _ChecklistProgress():
return $default(_that.ticked,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int ticked,  int total)?  $default,) {final _that = this;
switch (_that) {
case _ChecklistProgress() when $default != null:
return $default(_that.ticked,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChecklistProgress extends ChecklistProgress {
  const _ChecklistProgress({this.ticked = 0, this.total = 0}): super._();
  factory _ChecklistProgress.fromJson(Map<String, dynamic> json) => _$ChecklistProgressFromJson(json);

@override@JsonKey() final  int ticked;
@override@JsonKey() final  int total;

/// Create a copy of ChecklistProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChecklistProgressCopyWith<_ChecklistProgress> get copyWith => __$ChecklistProgressCopyWithImpl<_ChecklistProgress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChecklistProgressToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChecklistProgress&&(identical(other.ticked, ticked) || other.ticked == ticked)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,ticked,total);
}

@override
String toString() {
    return 'ChecklistProgress(ticked: $ticked, total: $total)';
}


}

/// @nodoc
abstract mixin class _$ChecklistProgressCopyWith<$Res> implements $ChecklistProgressCopyWith<$Res> {
  factory _$ChecklistProgressCopyWith(_ChecklistProgress value, $Res Function(_ChecklistProgress) _then) = __$ChecklistProgressCopyWithImpl;
@override @useResult
$Res call({
 int ticked, int total
});




}
/// @nodoc
class __$ChecklistProgressCopyWithImpl<$Res>
    implements _$ChecklistProgressCopyWith<$Res> {
  __$ChecklistProgressCopyWithImpl(this._self, this._then);

  final _ChecklistProgress _self;
  final $Res Function(_ChecklistProgress) _then;

/// Create a copy of ChecklistProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ticked = null,Object? total = null,}) {
  return _then(_ChecklistProgress(
ticked: null == ticked ? _self.ticked : ticked // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

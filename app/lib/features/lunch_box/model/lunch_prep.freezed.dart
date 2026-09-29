// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lunch_prep.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LunchPrep {

/// The week key — also the document id.
@JsonKey(includeToJson: false) String get id;/// Item ids prepped already.
 List<String> get done;
/// Create a copy of LunchPrep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LunchPrepCopyWith<LunchPrep> get copyWith => _$LunchPrepCopyWithImpl<LunchPrep>(this as LunchPrep, _$identity);

  /// Serializes this LunchPrep to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LunchPrep;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LunchPrep&&(identical(other.id, _this.id) || other.id == _this.id)&&const DeepCollectionEquality().equals(other.done, _this.done));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LunchPrep;
  return Object.hash(runtimeType,_this.id,const DeepCollectionEquality().hash(_this.done));
}

@override
String toString() {
  final _this = this as LunchPrep;
  return 'LunchPrep(id: ${_this.id}, done: ${_this.done})';
}


}

/// @nodoc
abstract mixin class $LunchPrepCopyWith<$Res>  {
  factory $LunchPrepCopyWith(LunchPrep value, $Res Function(LunchPrep) _then) = _$LunchPrepCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, List<String> done
});




}
/// @nodoc
class _$LunchPrepCopyWithImpl<$Res>
    implements $LunchPrepCopyWith<$Res> {
  _$LunchPrepCopyWithImpl(this._self, this._then);

  final LunchPrep _self;
  final $Res Function(LunchPrep) _then;

/// Create a copy of LunchPrep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? done = null,}) {
  return _then(LunchPrep(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [LunchPrep].
extension LunchPrepPatterns on LunchPrep {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LunchPrep value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LunchPrep() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LunchPrep value)  $default,){
final _that = this;
switch (_that) {
case _LunchPrep():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LunchPrep value)?  $default,){
final _that = this;
switch (_that) {
case _LunchPrep() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  List<String> done)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LunchPrep() when $default != null:
return $default(_that.id,_that.done);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  List<String> done)  $default,) {final _that = this;
switch (_that) {
case _LunchPrep():
return $default(_that.id,_that.done);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  List<String> done)?  $default,) {final _that = this;
switch (_that) {
case _LunchPrep() when $default != null:
return $default(_that.id,_that.done);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LunchPrep extends LunchPrep {
  const _LunchPrep({@JsonKey(includeToJson: false) required this.id,  List<String> done = const <String>[]}): _done = done,super._();
  factory _LunchPrep.fromJson(Map<String, dynamic> json) => _$LunchPrepFromJson(json);

/// The week key — also the document id.
@override@JsonKey(includeToJson: false) final  String id;
/// Item ids prepped already.
 final  List<String> _done;
/// Item ids prepped already.
@override@JsonKey() List<String> get done {
  if (_done is EqualUnmodifiableListView) return _done;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_done);
}


/// Create a copy of LunchPrep
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LunchPrepCopyWith<_LunchPrep> get copyWith => __$LunchPrepCopyWithImpl<_LunchPrep>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LunchPrepToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LunchPrep&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.done, _done));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_done));
}

@override
String toString() {
    return 'LunchPrep(id: $id, done: $done)';
}


}

/// @nodoc
abstract mixin class _$LunchPrepCopyWith<$Res> implements $LunchPrepCopyWith<$Res> {
  factory _$LunchPrepCopyWith(_LunchPrep value, $Res Function(_LunchPrep) _then) = __$LunchPrepCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, List<String> done
});




}
/// @nodoc
class __$LunchPrepCopyWithImpl<$Res>
    implements _$LunchPrepCopyWith<$Res> {
  __$LunchPrepCopyWithImpl(this._self, this._then);

  final _LunchPrep _self;
  final $Res Function(_LunchPrep) _then;

/// Create a copy of LunchPrep
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? done = null,}) {
  return _then(_LunchPrep(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,done: null == done ? _self._done : done // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on

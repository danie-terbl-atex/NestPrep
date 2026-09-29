// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'co_parent_home.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CoParentHome {

 String get name;@MemberColorConverter() MemberColor get color;
/// Create a copy of CoParentHome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoParentHomeCopyWith<CoParentHome> get copyWith => _$CoParentHomeCopyWithImpl<CoParentHome>(this as CoParentHome, _$identity);

  /// Serializes this CoParentHome to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CoParentHome;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoParentHome&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.color, _this.color) || other.color == _this.color));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CoParentHome;
  return Object.hash(runtimeType,_this.name,_this.color);
}

@override
String toString() {
  final _this = this as CoParentHome;
  return 'CoParentHome(name: ${_this.name}, color: ${_this.color})';
}


}

/// @nodoc
abstract mixin class $CoParentHomeCopyWith<$Res>  {
  factory $CoParentHomeCopyWith(CoParentHome value, $Res Function(CoParentHome) _then) = _$CoParentHomeCopyWithImpl;
@useResult
$Res call({
 String name,@MemberColorConverter() MemberColor color
});




}
/// @nodoc
class _$CoParentHomeCopyWithImpl<$Res>
    implements $CoParentHomeCopyWith<$Res> {
  _$CoParentHomeCopyWithImpl(this._self, this._then);

  final CoParentHome _self;
  final $Res Function(CoParentHome) _then;

/// Create a copy of CoParentHome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? color = null,}) {
  return _then(CoParentHome(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as MemberColor,
  ));
}

}


/// Adds pattern-matching-related methods to [CoParentHome].
extension CoParentHomePatterns on CoParentHome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoParentHome value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoParentHome() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoParentHome value)  $default,){
final _that = this;
switch (_that) {
case _CoParentHome():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoParentHome value)?  $default,){
final _that = this;
switch (_that) {
case _CoParentHome() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name, @MemberColorConverter()  MemberColor color)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoParentHome() when $default != null:
return $default(_that.name,_that.color);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name, @MemberColorConverter()  MemberColor color)  $default,) {final _that = this;
switch (_that) {
case _CoParentHome():
return $default(_that.name,_that.color);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name, @MemberColorConverter()  MemberColor color)?  $default,) {final _that = this;
switch (_that) {
case _CoParentHome() when $default != null:
return $default(_that.name,_that.color);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CoParentHome implements CoParentHome {
  const _CoParentHome({required this.name, @MemberColorConverter() required this.color});
  factory _CoParentHome.fromJson(Map<String, dynamic> json) => _$CoParentHomeFromJson(json);

@override final  String name;
@override@MemberColorConverter() final  MemberColor color;

/// Create a copy of CoParentHome
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoParentHomeCopyWith<_CoParentHome> get copyWith => __$CoParentHomeCopyWithImpl<_CoParentHome>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CoParentHomeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoParentHome&&(identical(other.name, name) || other.name == name)&&(identical(other.color, color) || other.color == color));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,color);
}

@override
String toString() {
    return 'CoParentHome(name: $name, color: $color)';
}


}

/// @nodoc
abstract mixin class _$CoParentHomeCopyWith<$Res> implements $CoParentHomeCopyWith<$Res> {
  factory _$CoParentHomeCopyWith(_CoParentHome value, $Res Function(_CoParentHome) _then) = __$CoParentHomeCopyWithImpl;
@override @useResult
$Res call({
 String name,@MemberColorConverter() MemberColor color
});




}
/// @nodoc
class __$CoParentHomeCopyWithImpl<$Res>
    implements _$CoParentHomeCopyWith<$Res> {
  __$CoParentHomeCopyWithImpl(this._self, this._then);

  final _CoParentHome _self;
  final $Res Function(_CoParentHome) _then;

/// Create a copy of CoParentHome
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? color = null,}) {
  return _then(_CoParentHome(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as MemberColor,
  ));
}


}


/// @nodoc
mixin _$CoParentHomes {

 CoParentHome get a; CoParentHome get b;
/// Create a copy of CoParentHomes
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoParentHomesCopyWith<CoParentHomes> get copyWith => _$CoParentHomesCopyWithImpl<CoParentHomes>(this as CoParentHomes, _$identity);

  /// Serializes this CoParentHomes to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CoParentHomes;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoParentHomes&&(identical(other.a, _this.a) || other.a == _this.a)&&(identical(other.b, _this.b) || other.b == _this.b));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CoParentHomes;
  return Object.hash(runtimeType,_this.a,_this.b);
}

@override
String toString() {
  final _this = this as CoParentHomes;
  return 'CoParentHomes(a: ${_this.a}, b: ${_this.b})';
}


}

/// @nodoc
abstract mixin class $CoParentHomesCopyWith<$Res>  {
  factory $CoParentHomesCopyWith(CoParentHomes value, $Res Function(CoParentHomes) _then) = _$CoParentHomesCopyWithImpl;
@useResult
$Res call({
 CoParentHome a, CoParentHome b
});


$CoParentHomeCopyWith<$Res> get a;$CoParentHomeCopyWith<$Res> get b;

}
/// @nodoc
class _$CoParentHomesCopyWithImpl<$Res>
    implements $CoParentHomesCopyWith<$Res> {
  _$CoParentHomesCopyWithImpl(this._self, this._then);

  final CoParentHomes _self;
  final $Res Function(CoParentHomes) _then;

/// Create a copy of CoParentHomes
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? a = null,Object? b = null,}) {
  return _then(CoParentHomes(
a: null == a ? _self.a : a // ignore: cast_nullable_to_non_nullable
as CoParentHome,b: null == b ? _self.b : b // ignore: cast_nullable_to_non_nullable
as CoParentHome,
  ));
}
/// Create a copy of CoParentHomes
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoParentHomeCopyWith<$Res> get a {
  
  return $CoParentHomeCopyWith<$Res>(_self.a, (value) {
    return _then(_self.copyWith(a: value));
  });
}/// Create a copy of CoParentHomes
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoParentHomeCopyWith<$Res> get b {
  
  return $CoParentHomeCopyWith<$Res>(_self.b, (value) {
    return _then(_self.copyWith(b: value));
  });
}
}


/// Adds pattern-matching-related methods to [CoParentHomes].
extension CoParentHomesPatterns on CoParentHomes {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoParentHomes value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoParentHomes() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoParentHomes value)  $default,){
final _that = this;
switch (_that) {
case _CoParentHomes():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoParentHomes value)?  $default,){
final _that = this;
switch (_that) {
case _CoParentHomes() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CoParentHome a,  CoParentHome b)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoParentHomes() when $default != null:
return $default(_that.a,_that.b);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CoParentHome a,  CoParentHome b)  $default,) {final _that = this;
switch (_that) {
case _CoParentHomes():
return $default(_that.a,_that.b);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CoParentHome a,  CoParentHome b)?  $default,) {final _that = this;
switch (_that) {
case _CoParentHomes() when $default != null:
return $default(_that.a,_that.b);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CoParentHomes implements CoParentHomes {
  const _CoParentHomes({required this.a, required this.b});
  factory _CoParentHomes.fromJson(Map<String, dynamic> json) => _$CoParentHomesFromJson(json);

@override final  CoParentHome a;
@override final  CoParentHome b;

/// Create a copy of CoParentHomes
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoParentHomesCopyWith<_CoParentHomes> get copyWith => __$CoParentHomesCopyWithImpl<_CoParentHomes>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CoParentHomesToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoParentHomes&&(identical(other.a, a) || other.a == a)&&(identical(other.b, b) || other.b == b));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,a,b);
}

@override
String toString() {
    return 'CoParentHomes(a: $a, b: $b)';
}


}

/// @nodoc
abstract mixin class _$CoParentHomesCopyWith<$Res> implements $CoParentHomesCopyWith<$Res> {
  factory _$CoParentHomesCopyWith(_CoParentHomes value, $Res Function(_CoParentHomes) _then) = __$CoParentHomesCopyWithImpl;
@override @useResult
$Res call({
 CoParentHome a, CoParentHome b
});


@override $CoParentHomeCopyWith<$Res> get a;@override $CoParentHomeCopyWith<$Res> get b;

}
/// @nodoc
class __$CoParentHomesCopyWithImpl<$Res>
    implements _$CoParentHomesCopyWith<$Res> {
  __$CoParentHomesCopyWithImpl(this._self, this._then);

  final _CoParentHomes _self;
  final $Res Function(_CoParentHomes) _then;

/// Create a copy of CoParentHomes
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? a = null,Object? b = null,}) {
  return _then(_CoParentHomes(
a: null == a ? _self.a : a // ignore: cast_nullable_to_non_nullable
as CoParentHome,b: null == b ? _self.b : b // ignore: cast_nullable_to_non_nullable
as CoParentHome,
  ));
}

/// Create a copy of CoParentHomes
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoParentHomeCopyWith<$Res> get a {
  
  return $CoParentHomeCopyWith<$Res>(_self.a, (value) {
    return _then(_self.copyWith(a: value));
  });
}/// Create a copy of CoParentHomes
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoParentHomeCopyWith<$Res> get b {
  
  return $CoParentHomeCopyWith<$Res>(_self.b, (value) {
    return _then(_self.copyWith(b: value));
  });
}
}

// dart format on

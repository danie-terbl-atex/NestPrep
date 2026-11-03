// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shared_page.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SharedPage {

 String? get url; String? get title;
/// Create a copy of SharedPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SharedPageCopyWith<SharedPage> get copyWith => _$SharedPageCopyWithImpl<SharedPage>(this as SharedPage, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SharedPage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SharedPage&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.title, _this.title) || other.title == _this.title));
}


@override
int get hashCode {
  final _this = this as SharedPage;
  return Object.hash(runtimeType,_this.url,_this.title);
}

@override
String toString() {
  final _this = this as SharedPage;
  return 'SharedPage(url: ${_this.url}, title: ${_this.title})';
}


}

/// @nodoc
abstract mixin class $SharedPageCopyWith<$Res>  {
  factory $SharedPageCopyWith(SharedPage value, $Res Function(SharedPage) _then) = _$SharedPageCopyWithImpl;
@useResult
$Res call({
 String? url, String? title
});




}
/// @nodoc
class _$SharedPageCopyWithImpl<$Res>
    implements $SharedPageCopyWith<$Res> {
  _$SharedPageCopyWithImpl(this._self, this._then);

  final SharedPage _self;
  final $Res Function(SharedPage) _then;

/// Create a copy of SharedPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = freezed,Object? title = freezed,}) {
  return _then(SharedPage(
url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SharedPage].
extension SharedPagePatterns on SharedPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SharedPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SharedPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SharedPage value)  $default,){
final _that = this;
switch (_that) {
case _SharedPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SharedPage value)?  $default,){
final _that = this;
switch (_that) {
case _SharedPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? url,  String? title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SharedPage() when $default != null:
return $default(_that.url,_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? url,  String? title)  $default,) {final _that = this;
switch (_that) {
case _SharedPage():
return $default(_that.url,_that.title);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? url,  String? title)?  $default,) {final _that = this;
switch (_that) {
case _SharedPage() when $default != null:
return $default(_that.url,_that.title);case _:
  return null;

}
}

}

/// @nodoc


class _SharedPage extends SharedPage {
  const _SharedPage({this.url, this.title}): super._();
  

@override final  String? url;
@override final  String? title;

/// Create a copy of SharedPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SharedPageCopyWith<_SharedPage> get copyWith => __$SharedPageCopyWithImpl<_SharedPage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SharedPage&&(identical(other.url, url) || other.url == url)&&(identical(other.title, title) || other.title == title));
}


@override
int get hashCode {
    return Object.hash(runtimeType,url,title);
}

@override
String toString() {
    return 'SharedPage(url: $url, title: $title)';
}


}

/// @nodoc
abstract mixin class _$SharedPageCopyWith<$Res> implements $SharedPageCopyWith<$Res> {
  factory _$SharedPageCopyWith(_SharedPage value, $Res Function(_SharedPage) _then) = __$SharedPageCopyWithImpl;
@override @useResult
$Res call({
 String? url, String? title
});




}
/// @nodoc
class __$SharedPageCopyWithImpl<$Res>
    implements _$SharedPageCopyWith<$Res> {
  __$SharedPageCopyWithImpl(this._self, this._then);

  final _SharedPage _self;
  final $Res Function(_SharedPage) _then;

/// Create a copy of SharedPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = freezed,Object? title = freezed,}) {
  return _then(_SharedPage(
url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

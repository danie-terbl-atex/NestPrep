// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe_photo.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RecipePhoto {

 String get card; String get hero; String? get credit; String? get licence; String? get sourceUrl; bool get isGenerated;
/// Create a copy of RecipePhoto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipePhotoCopyWith<RecipePhoto> get copyWith => _$RecipePhotoCopyWithImpl<RecipePhoto>(this as RecipePhoto, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RecipePhoto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecipePhoto&&(identical(other.card, _this.card) || other.card == _this.card)&&(identical(other.hero, _this.hero) || other.hero == _this.hero)&&(identical(other.credit, _this.credit) || other.credit == _this.credit)&&(identical(other.licence, _this.licence) || other.licence == _this.licence)&&(identical(other.sourceUrl, _this.sourceUrl) || other.sourceUrl == _this.sourceUrl)&&(identical(other.isGenerated, _this.isGenerated) || other.isGenerated == _this.isGenerated));
}


@override
int get hashCode {
  final _this = this as RecipePhoto;
  return Object.hash(runtimeType,_this.card,_this.hero,_this.credit,_this.licence,_this.sourceUrl,_this.isGenerated);
}

@override
String toString() {
  final _this = this as RecipePhoto;
  return 'RecipePhoto(card: ${_this.card}, hero: ${_this.hero}, credit: ${_this.credit}, licence: ${_this.licence}, sourceUrl: ${_this.sourceUrl}, isGenerated: ${_this.isGenerated})';
}


}

/// @nodoc
abstract mixin class $RecipePhotoCopyWith<$Res>  {
  factory $RecipePhotoCopyWith(RecipePhoto value, $Res Function(RecipePhoto) _then) = _$RecipePhotoCopyWithImpl;
@useResult
$Res call({
 String card, String hero, String? credit, String? licence, String? sourceUrl, bool isGenerated
});




}
/// @nodoc
class _$RecipePhotoCopyWithImpl<$Res>
    implements $RecipePhotoCopyWith<$Res> {
  _$RecipePhotoCopyWithImpl(this._self, this._then);

  final RecipePhoto _self;
  final $Res Function(RecipePhoto) _then;

/// Create a copy of RecipePhoto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? card = null,Object? hero = null,Object? credit = freezed,Object? licence = freezed,Object? sourceUrl = freezed,Object? isGenerated = null,}) {
  return _then(RecipePhoto(
card: null == card ? _self.card : card // ignore: cast_nullable_to_non_nullable
as String,hero: null == hero ? _self.hero : hero // ignore: cast_nullable_to_non_nullable
as String,credit: freezed == credit ? _self.credit : credit // ignore: cast_nullable_to_non_nullable
as String?,licence: freezed == licence ? _self.licence : licence // ignore: cast_nullable_to_non_nullable
as String?,sourceUrl: freezed == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String?,isGenerated: null == isGenerated ? _self.isGenerated : isGenerated // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [RecipePhoto].
extension RecipePhotoPatterns on RecipePhoto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecipePhoto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecipePhoto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecipePhoto value)  $default,){
final _that = this;
switch (_that) {
case _RecipePhoto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecipePhoto value)?  $default,){
final _that = this;
switch (_that) {
case _RecipePhoto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String card,  String hero,  String? credit,  String? licence,  String? sourceUrl,  bool isGenerated)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecipePhoto() when $default != null:
return $default(_that.card,_that.hero,_that.credit,_that.licence,_that.sourceUrl,_that.isGenerated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String card,  String hero,  String? credit,  String? licence,  String? sourceUrl,  bool isGenerated)  $default,) {final _that = this;
switch (_that) {
case _RecipePhoto():
return $default(_that.card,_that.hero,_that.credit,_that.licence,_that.sourceUrl,_that.isGenerated);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String card,  String hero,  String? credit,  String? licence,  String? sourceUrl,  bool isGenerated)?  $default,) {final _that = this;
switch (_that) {
case _RecipePhoto() when $default != null:
return $default(_that.card,_that.hero,_that.credit,_that.licence,_that.sourceUrl,_that.isGenerated);case _:
  return null;

}
}

}

/// @nodoc


class _RecipePhoto implements RecipePhoto {
  const _RecipePhoto({required this.card, required this.hero, this.credit, this.licence, this.sourceUrl, this.isGenerated = false});
  

@override final  String card;
@override final  String hero;
@override final  String? credit;
@override final  String? licence;
@override final  String? sourceUrl;
@override@JsonKey() final  bool isGenerated;

/// Create a copy of RecipePhoto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipePhotoCopyWith<_RecipePhoto> get copyWith => __$RecipePhotoCopyWithImpl<_RecipePhoto>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecipePhoto&&(identical(other.card, card) || other.card == card)&&(identical(other.hero, hero) || other.hero == hero)&&(identical(other.credit, credit) || other.credit == credit)&&(identical(other.licence, licence) || other.licence == licence)&&(identical(other.sourceUrl, sourceUrl) || other.sourceUrl == sourceUrl)&&(identical(other.isGenerated, isGenerated) || other.isGenerated == isGenerated));
}


@override
int get hashCode {
    return Object.hash(runtimeType,card,hero,credit,licence,sourceUrl,isGenerated);
}

@override
String toString() {
    return 'RecipePhoto(card: $card, hero: $hero, credit: $credit, licence: $licence, sourceUrl: $sourceUrl, isGenerated: $isGenerated)';
}


}

/// @nodoc
abstract mixin class _$RecipePhotoCopyWith<$Res> implements $RecipePhotoCopyWith<$Res> {
  factory _$RecipePhotoCopyWith(_RecipePhoto value, $Res Function(_RecipePhoto) _then) = __$RecipePhotoCopyWithImpl;
@override @useResult
$Res call({
 String card, String hero, String? credit, String? licence, String? sourceUrl, bool isGenerated
});




}
/// @nodoc
class __$RecipePhotoCopyWithImpl<$Res>
    implements _$RecipePhotoCopyWith<$Res> {
  __$RecipePhotoCopyWithImpl(this._self, this._then);

  final _RecipePhoto _self;
  final $Res Function(_RecipePhoto) _then;

/// Create a copy of RecipePhoto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? card = null,Object? hero = null,Object? credit = freezed,Object? licence = freezed,Object? sourceUrl = freezed,Object? isGenerated = null,}) {
  return _then(_RecipePhoto(
card: null == card ? _self.card : card // ignore: cast_nullable_to_non_nullable
as String,hero: null == hero ? _self.hero : hero // ignore: cast_nullable_to_non_nullable
as String,credit: freezed == credit ? _self.credit : credit // ignore: cast_nullable_to_non_nullable
as String?,licence: freezed == licence ? _self.licence : licence // ignore: cast_nullable_to_non_nullable
as String?,sourceUrl: freezed == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String?,isGenerated: null == isGenerated ? _self.isGenerated : isGenerated // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

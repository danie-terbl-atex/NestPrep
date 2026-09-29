// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'family_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FamilyProfile {

@JsonKey(includeToJson: false) String get id;/// Set by a parent. What subscriptions counts, and what the family screen
/// groups by — being a child is not a role (family-profiles ADR-0001).
 bool get isChild; List<String> get likes; List<String> get dislikes;@DietaryFlagsConverter() Set<DietaryFlag> get diet;@AllergenMapConverter() Map<Allergen, AllergyDetail> get allergies; Map<String, OtherAllergy> get otherAllergies;/// A `School` in this household, or null. A school that has since been
/// deleted reads as no school (`FamilyRoster`).
 String? get schoolId; String? get grade; String? get clothingSize; String? get shoeSize;
/// Create a copy of FamilyProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FamilyProfileCopyWith<FamilyProfile> get copyWith => _$FamilyProfileCopyWithImpl<FamilyProfile>(this as FamilyProfile, _$identity);

  /// Serializes this FamilyProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as FamilyProfile;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FamilyProfile&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.isChild, _this.isChild) || other.isChild == _this.isChild)&&const DeepCollectionEquality().equals(other.likes, _this.likes)&&const DeepCollectionEquality().equals(other.dislikes, _this.dislikes)&&const DeepCollectionEquality().equals(other.diet, _this.diet)&&const DeepCollectionEquality().equals(other.allergies, _this.allergies)&&const DeepCollectionEquality().equals(other.otherAllergies, _this.otherAllergies)&&(identical(other.schoolId, _this.schoolId) || other.schoolId == _this.schoolId)&&(identical(other.grade, _this.grade) || other.grade == _this.grade)&&(identical(other.clothingSize, _this.clothingSize) || other.clothingSize == _this.clothingSize)&&(identical(other.shoeSize, _this.shoeSize) || other.shoeSize == _this.shoeSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FamilyProfile;
  return Object.hash(runtimeType,_this.id,_this.isChild,const DeepCollectionEquality().hash(_this.likes),const DeepCollectionEquality().hash(_this.dislikes),const DeepCollectionEquality().hash(_this.diet),const DeepCollectionEquality().hash(_this.allergies),const DeepCollectionEquality().hash(_this.otherAllergies),_this.schoolId,_this.grade,_this.clothingSize,_this.shoeSize);
}

@override
String toString() {
  final _this = this as FamilyProfile;
  return 'FamilyProfile(id: ${_this.id}, isChild: ${_this.isChild}, likes: ${_this.likes}, dislikes: ${_this.dislikes}, diet: ${_this.diet}, allergies: ${_this.allergies}, otherAllergies: ${_this.otherAllergies}, schoolId: ${_this.schoolId}, grade: ${_this.grade}, clothingSize: ${_this.clothingSize}, shoeSize: ${_this.shoeSize})';
}


}

/// @nodoc
abstract mixin class $FamilyProfileCopyWith<$Res>  {
  factory $FamilyProfileCopyWith(FamilyProfile value, $Res Function(FamilyProfile) _then) = _$FamilyProfileCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, bool isChild, List<String> likes, List<String> dislikes,@DietaryFlagsConverter() Set<DietaryFlag> diet,@AllergenMapConverter() Map<Allergen, AllergyDetail> allergies, Map<String, OtherAllergy> otherAllergies, String? schoolId, String? grade, String? clothingSize, String? shoeSize
});




}
/// @nodoc
class _$FamilyProfileCopyWithImpl<$Res>
    implements $FamilyProfileCopyWith<$Res> {
  _$FamilyProfileCopyWithImpl(this._self, this._then);

  final FamilyProfile _self;
  final $Res Function(FamilyProfile) _then;

/// Create a copy of FamilyProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? isChild = null,Object? likes = null,Object? dislikes = null,Object? diet = null,Object? allergies = null,Object? otherAllergies = null,Object? schoolId = freezed,Object? grade = freezed,Object? clothingSize = freezed,Object? shoeSize = freezed,}) {
  return _then(FamilyProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,isChild: null == isChild ? _self.isChild : isChild // ignore: cast_nullable_to_non_nullable
as bool,likes: null == likes ? _self.likes : likes // ignore: cast_nullable_to_non_nullable
as List<String>,dislikes: null == dislikes ? _self.dislikes : dislikes // ignore: cast_nullable_to_non_nullable
as List<String>,diet: null == diet ? _self.diet : diet // ignore: cast_nullable_to_non_nullable
as Set<DietaryFlag>,allergies: null == allergies ? _self.allergies : allergies // ignore: cast_nullable_to_non_nullable
as Map<Allergen, AllergyDetail>,otherAllergies: null == otherAllergies ? _self.otherAllergies : otherAllergies // ignore: cast_nullable_to_non_nullable
as Map<String, OtherAllergy>,schoolId: freezed == schoolId ? _self.schoolId : schoolId // ignore: cast_nullable_to_non_nullable
as String?,grade: freezed == grade ? _self.grade : grade // ignore: cast_nullable_to_non_nullable
as String?,clothingSize: freezed == clothingSize ? _self.clothingSize : clothingSize // ignore: cast_nullable_to_non_nullable
as String?,shoeSize: freezed == shoeSize ? _self.shoeSize : shoeSize // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FamilyProfile].
extension FamilyProfilePatterns on FamilyProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FamilyProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FamilyProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FamilyProfile value)  $default,){
final _that = this;
switch (_that) {
case _FamilyProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FamilyProfile value)?  $default,){
final _that = this;
switch (_that) {
case _FamilyProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  bool isChild,  List<String> likes,  List<String> dislikes, @DietaryFlagsConverter()  Set<DietaryFlag> diet, @AllergenMapConverter()  Map<Allergen, AllergyDetail> allergies,  Map<String, OtherAllergy> otherAllergies,  String? schoolId,  String? grade,  String? clothingSize,  String? shoeSize)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FamilyProfile() when $default != null:
return $default(_that.id,_that.isChild,_that.likes,_that.dislikes,_that.diet,_that.allergies,_that.otherAllergies,_that.schoolId,_that.grade,_that.clothingSize,_that.shoeSize);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  bool isChild,  List<String> likes,  List<String> dislikes, @DietaryFlagsConverter()  Set<DietaryFlag> diet, @AllergenMapConverter()  Map<Allergen, AllergyDetail> allergies,  Map<String, OtherAllergy> otherAllergies,  String? schoolId,  String? grade,  String? clothingSize,  String? shoeSize)  $default,) {final _that = this;
switch (_that) {
case _FamilyProfile():
return $default(_that.id,_that.isChild,_that.likes,_that.dislikes,_that.diet,_that.allergies,_that.otherAllergies,_that.schoolId,_that.grade,_that.clothingSize,_that.shoeSize);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  bool isChild,  List<String> likes,  List<String> dislikes, @DietaryFlagsConverter()  Set<DietaryFlag> diet, @AllergenMapConverter()  Map<Allergen, AllergyDetail> allergies,  Map<String, OtherAllergy> otherAllergies,  String? schoolId,  String? grade,  String? clothingSize,  String? shoeSize)?  $default,) {final _that = this;
switch (_that) {
case _FamilyProfile() when $default != null:
return $default(_that.id,_that.isChild,_that.likes,_that.dislikes,_that.diet,_that.allergies,_that.otherAllergies,_that.schoolId,_that.grade,_that.clothingSize,_that.shoeSize);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FamilyProfile extends FamilyProfile {
  const _FamilyProfile({@JsonKey(includeToJson: false) required this.id, this.isChild = false,  List<String> likes = const <String>[],  List<String> dislikes = const <String>[], @DietaryFlagsConverter()  Set<DietaryFlag> diet = const <DietaryFlag>{}, @AllergenMapConverter()  Map<Allergen, AllergyDetail> allergies = const <Allergen, AllergyDetail>{},  Map<String, OtherAllergy> otherAllergies = const <String, OtherAllergy>{}, this.schoolId, this.grade, this.clothingSize, this.shoeSize}): _likes = likes,_dislikes = dislikes,_diet = diet,_allergies = allergies,_otherAllergies = otherAllergies,super._();
  factory _FamilyProfile.fromJson(Map<String, dynamic> json) => _$FamilyProfileFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
/// Set by a parent. What subscriptions counts, and what the family screen
/// groups by — being a child is not a role (family-profiles ADR-0001).
@override@JsonKey() final  bool isChild;
 final  List<String> _likes;
@override@JsonKey() List<String> get likes {
  if (_likes is EqualUnmodifiableListView) return _likes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_likes);
}

 final  List<String> _dislikes;
@override@JsonKey() List<String> get dislikes {
  if (_dislikes is EqualUnmodifiableListView) return _dislikes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dislikes);
}

 final  Set<DietaryFlag> _diet;
@override@JsonKey()@DietaryFlagsConverter() Set<DietaryFlag> get diet {
  if (_diet is EqualUnmodifiableSetView) return _diet;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_diet);
}

 final  Map<Allergen, AllergyDetail> _allergies;
@override@JsonKey()@AllergenMapConverter() Map<Allergen, AllergyDetail> get allergies {
  if (_allergies is EqualUnmodifiableMapView) return _allergies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_allergies);
}

 final  Map<String, OtherAllergy> _otherAllergies;
@override@JsonKey() Map<String, OtherAllergy> get otherAllergies {
  if (_otherAllergies is EqualUnmodifiableMapView) return _otherAllergies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_otherAllergies);
}

/// A `School` in this household, or null. A school that has since been
/// deleted reads as no school (`FamilyRoster`).
@override final  String? schoolId;
@override final  String? grade;
@override final  String? clothingSize;
@override final  String? shoeSize;

/// Create a copy of FamilyProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FamilyProfileCopyWith<_FamilyProfile> get copyWith => __$FamilyProfileCopyWithImpl<_FamilyProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FamilyProfileToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FamilyProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.isChild, isChild) || other.isChild == isChild)&&const DeepCollectionEquality().equals(other.likes, _likes)&&const DeepCollectionEquality().equals(other.dislikes, _dislikes)&&const DeepCollectionEquality().equals(other.diet, _diet)&&const DeepCollectionEquality().equals(other.allergies, _allergies)&&const DeepCollectionEquality().equals(other.otherAllergies, _otherAllergies)&&(identical(other.schoolId, schoolId) || other.schoolId == schoolId)&&(identical(other.grade, grade) || other.grade == grade)&&(identical(other.clothingSize, clothingSize) || other.clothingSize == clothingSize)&&(identical(other.shoeSize, shoeSize) || other.shoeSize == shoeSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,isChild,const DeepCollectionEquality().hash(_likes),const DeepCollectionEquality().hash(_dislikes),const DeepCollectionEquality().hash(_diet),const DeepCollectionEquality().hash(_allergies),const DeepCollectionEquality().hash(_otherAllergies),schoolId,grade,clothingSize,shoeSize);
}

@override
String toString() {
    return 'FamilyProfile(id: $id, isChild: $isChild, likes: $likes, dislikes: $dislikes, diet: $diet, allergies: $allergies, otherAllergies: $otherAllergies, schoolId: $schoolId, grade: $grade, clothingSize: $clothingSize, shoeSize: $shoeSize)';
}


}

/// @nodoc
abstract mixin class _$FamilyProfileCopyWith<$Res> implements $FamilyProfileCopyWith<$Res> {
  factory _$FamilyProfileCopyWith(_FamilyProfile value, $Res Function(_FamilyProfile) _then) = __$FamilyProfileCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, bool isChild, List<String> likes, List<String> dislikes,@DietaryFlagsConverter() Set<DietaryFlag> diet,@AllergenMapConverter() Map<Allergen, AllergyDetail> allergies, Map<String, OtherAllergy> otherAllergies, String? schoolId, String? grade, String? clothingSize, String? shoeSize
});




}
/// @nodoc
class __$FamilyProfileCopyWithImpl<$Res>
    implements _$FamilyProfileCopyWith<$Res> {
  __$FamilyProfileCopyWithImpl(this._self, this._then);

  final _FamilyProfile _self;
  final $Res Function(_FamilyProfile) _then;

/// Create a copy of FamilyProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? isChild = null,Object? likes = null,Object? dislikes = null,Object? diet = null,Object? allergies = null,Object? otherAllergies = null,Object? schoolId = freezed,Object? grade = freezed,Object? clothingSize = freezed,Object? shoeSize = freezed,}) {
  return _then(_FamilyProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,isChild: null == isChild ? _self.isChild : isChild // ignore: cast_nullable_to_non_nullable
as bool,likes: null == likes ? _self._likes : likes // ignore: cast_nullable_to_non_nullable
as List<String>,dislikes: null == dislikes ? _self._dislikes : dislikes // ignore: cast_nullable_to_non_nullable
as List<String>,diet: null == diet ? _self._diet : diet // ignore: cast_nullable_to_non_nullable
as Set<DietaryFlag>,allergies: null == allergies ? _self._allergies : allergies // ignore: cast_nullable_to_non_nullable
as Map<Allergen, AllergyDetail>,otherAllergies: null == otherAllergies ? _self._otherAllergies : otherAllergies // ignore: cast_nullable_to_non_nullable
as Map<String, OtherAllergy>,schoolId: freezed == schoolId ? _self.schoolId : schoolId // ignore: cast_nullable_to_non_nullable
as String?,grade: freezed == grade ? _self.grade : grade // ignore: cast_nullable_to_non_nullable
as String?,clothingSize: freezed == clothingSize ? _self.clothingSize : clothingSize // ignore: cast_nullable_to_non_nullable
as String?,shoeSize: freezed == shoeSize ? _self.shoeSize : shoeSize // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

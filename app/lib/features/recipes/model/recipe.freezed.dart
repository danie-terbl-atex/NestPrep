// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Recipe {

 String get id; String get name; String get summary; Set<RecipeContext> get contexts;/// Context → where in that meal it goes, as stored (a slot name for the
/// lunch box, a course for a meal). Read through [lunchSlot] and
/// [courseIn].
 Map<RecipeContext, String> get placement; Set<Allergen> get allergens; List<String> get dietTags; List<RecipeIngredient> get ingredients; List<String> get steps; int get servings; int get prepMinutes;/// Worth making ahead on Sunday, like a lunch item that is.
 bool get prepAhead; String? get prepNote;/// Drafted by *Plan my week* for this household (recipes ADR-0002), not
/// written by NestPrep — the sheet says so.
 bool get isAiDrafted;/// Where the dish comes from and why families love it.
 String? get about; RecipeCuisine? get cuisine; Set<RecipeTag> get tags;/// Time on the stove or in the oven, beside [prepMinutes].
 int get cookMinutes; RecipeDifficulty? get difficulty; RecipePhoto? get photo;
/// Create a copy of Recipe
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipeCopyWith<Recipe> get copyWith => _$RecipeCopyWithImpl<Recipe>(this as Recipe, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Recipe;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Recipe&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.summary, _this.summary) || other.summary == _this.summary)&&const DeepCollectionEquality().equals(other.contexts, _this.contexts)&&const DeepCollectionEquality().equals(other.placement, _this.placement)&&const DeepCollectionEquality().equals(other.allergens, _this.allergens)&&const DeepCollectionEquality().equals(other.dietTags, _this.dietTags)&&const DeepCollectionEquality().equals(other.ingredients, _this.ingredients)&&const DeepCollectionEquality().equals(other.steps, _this.steps)&&(identical(other.servings, _this.servings) || other.servings == _this.servings)&&(identical(other.prepMinutes, _this.prepMinutes) || other.prepMinutes == _this.prepMinutes)&&(identical(other.prepAhead, _this.prepAhead) || other.prepAhead == _this.prepAhead)&&(identical(other.prepNote, _this.prepNote) || other.prepNote == _this.prepNote)&&(identical(other.isAiDrafted, _this.isAiDrafted) || other.isAiDrafted == _this.isAiDrafted)&&(identical(other.about, _this.about) || other.about == _this.about)&&(identical(other.cuisine, _this.cuisine) || other.cuisine == _this.cuisine)&&const DeepCollectionEquality().equals(other.tags, _this.tags)&&(identical(other.cookMinutes, _this.cookMinutes) || other.cookMinutes == _this.cookMinutes)&&(identical(other.difficulty, _this.difficulty) || other.difficulty == _this.difficulty)&&(identical(other.photo, _this.photo) || other.photo == _this.photo));
}


@override
int get hashCode {
  final _this = this as Recipe;
  return Object.hashAll([runtimeType,_this.id,_this.name,_this.summary,const DeepCollectionEquality().hash(_this.contexts),const DeepCollectionEquality().hash(_this.placement),const DeepCollectionEquality().hash(_this.allergens),const DeepCollectionEquality().hash(_this.dietTags),const DeepCollectionEquality().hash(_this.ingredients),const DeepCollectionEquality().hash(_this.steps),_this.servings,_this.prepMinutes,_this.prepAhead,_this.prepNote,_this.isAiDrafted,_this.about,_this.cuisine,const DeepCollectionEquality().hash(_this.tags),_this.cookMinutes,_this.difficulty,_this.photo]);
}

@override
String toString() {
  final _this = this as Recipe;
  return 'Recipe(id: ${_this.id}, name: ${_this.name}, summary: ${_this.summary}, contexts: ${_this.contexts}, placement: ${_this.placement}, allergens: ${_this.allergens}, dietTags: ${_this.dietTags}, ingredients: ${_this.ingredients}, steps: ${_this.steps}, servings: ${_this.servings}, prepMinutes: ${_this.prepMinutes}, prepAhead: ${_this.prepAhead}, prepNote: ${_this.prepNote}, isAiDrafted: ${_this.isAiDrafted}, about: ${_this.about}, cuisine: ${_this.cuisine}, tags: ${_this.tags}, cookMinutes: ${_this.cookMinutes}, difficulty: ${_this.difficulty}, photo: ${_this.photo})';
}


}

/// @nodoc
abstract mixin class $RecipeCopyWith<$Res>  {
  factory $RecipeCopyWith(Recipe value, $Res Function(Recipe) _then) = _$RecipeCopyWithImpl;
@useResult
$Res call({
 String id, String name, String summary, Set<RecipeContext> contexts, Map<RecipeContext, String> placement, Set<Allergen> allergens, List<String> dietTags, List<RecipeIngredient> ingredients, List<String> steps, int servings, int prepMinutes, bool prepAhead, String? prepNote, bool isAiDrafted, String? about, RecipeCuisine? cuisine, Set<RecipeTag> tags, int cookMinutes, RecipeDifficulty? difficulty, RecipePhoto? photo
});


$RecipePhotoCopyWith<$Res>? get photo;

}
/// @nodoc
class _$RecipeCopyWithImpl<$Res>
    implements $RecipeCopyWith<$Res> {
  _$RecipeCopyWithImpl(this._self, this._then);

  final Recipe _self;
  final $Res Function(Recipe) _then;

/// Create a copy of Recipe
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? summary = null,Object? contexts = null,Object? placement = null,Object? allergens = null,Object? dietTags = null,Object? ingredients = null,Object? steps = null,Object? servings = null,Object? prepMinutes = null,Object? prepAhead = null,Object? prepNote = freezed,Object? isAiDrafted = null,Object? about = freezed,Object? cuisine = freezed,Object? tags = null,Object? cookMinutes = null,Object? difficulty = freezed,Object? photo = freezed,}) {
  return _then(Recipe(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,contexts: null == contexts ? _self.contexts : contexts // ignore: cast_nullable_to_non_nullable
as Set<RecipeContext>,placement: null == placement ? _self.placement : placement // ignore: cast_nullable_to_non_nullable
as Map<RecipeContext, String>,allergens: null == allergens ? _self.allergens : allergens // ignore: cast_nullable_to_non_nullable
as Set<Allergen>,dietTags: null == dietTags ? _self.dietTags : dietTags // ignore: cast_nullable_to_non_nullable
as List<String>,ingredients: null == ingredients ? _self.ingredients : ingredients // ignore: cast_nullable_to_non_nullable
as List<RecipeIngredient>,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<String>,servings: null == servings ? _self.servings : servings // ignore: cast_nullable_to_non_nullable
as int,prepMinutes: null == prepMinutes ? _self.prepMinutes : prepMinutes // ignore: cast_nullable_to_non_nullable
as int,prepAhead: null == prepAhead ? _self.prepAhead : prepAhead // ignore: cast_nullable_to_non_nullable
as bool,prepNote: freezed == prepNote ? _self.prepNote : prepNote // ignore: cast_nullable_to_non_nullable
as String?,isAiDrafted: null == isAiDrafted ? _self.isAiDrafted : isAiDrafted // ignore: cast_nullable_to_non_nullable
as bool,about: freezed == about ? _self.about : about // ignore: cast_nullable_to_non_nullable
as String?,cuisine: freezed == cuisine ? _self.cuisine : cuisine // ignore: cast_nullable_to_non_nullable
as RecipeCuisine?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as Set<RecipeTag>,cookMinutes: null == cookMinutes ? _self.cookMinutes : cookMinutes // ignore: cast_nullable_to_non_nullable
as int,difficulty: freezed == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as RecipeDifficulty?,photo: freezed == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as RecipePhoto?,
  ));
}
/// Create a copy of Recipe
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecipePhotoCopyWith<$Res>? get photo {
    if (_self.photo == null) {
    return null;
  }

  return $RecipePhotoCopyWith<$Res>(_self.photo!, (value) {
    return _then(_self.copyWith(photo: value));
  });
}
}


/// Adds pattern-matching-related methods to [Recipe].
extension RecipePatterns on Recipe {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Recipe value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Recipe() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Recipe value)  $default,){
final _that = this;
switch (_that) {
case _Recipe():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Recipe value)?  $default,){
final _that = this;
switch (_that) {
case _Recipe() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String summary,  Set<RecipeContext> contexts,  Map<RecipeContext, String> placement,  Set<Allergen> allergens,  List<String> dietTags,  List<RecipeIngredient> ingredients,  List<String> steps,  int servings,  int prepMinutes,  bool prepAhead,  String? prepNote,  bool isAiDrafted,  String? about,  RecipeCuisine? cuisine,  Set<RecipeTag> tags,  int cookMinutes,  RecipeDifficulty? difficulty,  RecipePhoto? photo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Recipe() when $default != null:
return $default(_that.id,_that.name,_that.summary,_that.contexts,_that.placement,_that.allergens,_that.dietTags,_that.ingredients,_that.steps,_that.servings,_that.prepMinutes,_that.prepAhead,_that.prepNote,_that.isAiDrafted,_that.about,_that.cuisine,_that.tags,_that.cookMinutes,_that.difficulty,_that.photo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String summary,  Set<RecipeContext> contexts,  Map<RecipeContext, String> placement,  Set<Allergen> allergens,  List<String> dietTags,  List<RecipeIngredient> ingredients,  List<String> steps,  int servings,  int prepMinutes,  bool prepAhead,  String? prepNote,  bool isAiDrafted,  String? about,  RecipeCuisine? cuisine,  Set<RecipeTag> tags,  int cookMinutes,  RecipeDifficulty? difficulty,  RecipePhoto? photo)  $default,) {final _that = this;
switch (_that) {
case _Recipe():
return $default(_that.id,_that.name,_that.summary,_that.contexts,_that.placement,_that.allergens,_that.dietTags,_that.ingredients,_that.steps,_that.servings,_that.prepMinutes,_that.prepAhead,_that.prepNote,_that.isAiDrafted,_that.about,_that.cuisine,_that.tags,_that.cookMinutes,_that.difficulty,_that.photo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String summary,  Set<RecipeContext> contexts,  Map<RecipeContext, String> placement,  Set<Allergen> allergens,  List<String> dietTags,  List<RecipeIngredient> ingredients,  List<String> steps,  int servings,  int prepMinutes,  bool prepAhead,  String? prepNote,  bool isAiDrafted,  String? about,  RecipeCuisine? cuisine,  Set<RecipeTag> tags,  int cookMinutes,  RecipeDifficulty? difficulty,  RecipePhoto? photo)?  $default,) {final _that = this;
switch (_that) {
case _Recipe() when $default != null:
return $default(_that.id,_that.name,_that.summary,_that.contexts,_that.placement,_that.allergens,_that.dietTags,_that.ingredients,_that.steps,_that.servings,_that.prepMinutes,_that.prepAhead,_that.prepNote,_that.isAiDrafted,_that.about,_that.cuisine,_that.tags,_that.cookMinutes,_that.difficulty,_that.photo);case _:
  return null;

}
}

}

/// @nodoc


class _Recipe extends Recipe {
  const _Recipe({required this.id, required this.name, required this.summary, required  Set<RecipeContext> contexts, required  Map<RecipeContext, String> placement, required  Set<Allergen> allergens, required  List<String> dietTags, required  List<RecipeIngredient> ingredients, required  List<String> steps, required this.servings, required this.prepMinutes, required this.prepAhead, this.prepNote, this.isAiDrafted = false, this.about, this.cuisine,  Set<RecipeTag> tags = const <RecipeTag>{}, this.cookMinutes = 0, this.difficulty, this.photo}): _contexts = contexts,_placement = placement,_allergens = allergens,_dietTags = dietTags,_ingredients = ingredients,_steps = steps,_tags = tags,super._();
  

@override final  String id;
@override final  String name;
@override final  String summary;
 final  Set<RecipeContext> _contexts;
@override Set<RecipeContext> get contexts {
  if (_contexts is EqualUnmodifiableSetView) return _contexts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_contexts);
}

/// Context → where in that meal it goes, as stored (a slot name for the
/// lunch box, a course for a meal). Read through [lunchSlot] and
/// [courseIn].
 final  Map<RecipeContext, String> _placement;
/// Context → where in that meal it goes, as stored (a slot name for the
/// lunch box, a course for a meal). Read through [lunchSlot] and
/// [courseIn].
@override Map<RecipeContext, String> get placement {
  if (_placement is EqualUnmodifiableMapView) return _placement;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_placement);
}

 final  Set<Allergen> _allergens;
@override Set<Allergen> get allergens {
  if (_allergens is EqualUnmodifiableSetView) return _allergens;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_allergens);
}

 final  List<String> _dietTags;
@override List<String> get dietTags {
  if (_dietTags is EqualUnmodifiableListView) return _dietTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dietTags);
}

 final  List<RecipeIngredient> _ingredients;
@override List<RecipeIngredient> get ingredients {
  if (_ingredients is EqualUnmodifiableListView) return _ingredients;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ingredients);
}

 final  List<String> _steps;
@override List<String> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}

@override final  int servings;
@override final  int prepMinutes;
/// Worth making ahead on Sunday, like a lunch item that is.
@override final  bool prepAhead;
@override final  String? prepNote;
/// Drafted by *Plan my week* for this household (recipes ADR-0002), not
/// written by NestPrep — the sheet says so.
@override@JsonKey() final  bool isAiDrafted;
/// Where the dish comes from and why families love it.
@override final  String? about;
@override final  RecipeCuisine? cuisine;
 final  Set<RecipeTag> _tags;
@override@JsonKey() Set<RecipeTag> get tags {
  if (_tags is EqualUnmodifiableSetView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_tags);
}

/// Time on the stove or in the oven, beside [prepMinutes].
@override@JsonKey() final  int cookMinutes;
@override final  RecipeDifficulty? difficulty;
@override final  RecipePhoto? photo;

/// Create a copy of Recipe
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipeCopyWith<_Recipe> get copyWith => __$RecipeCopyWithImpl<_Recipe>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Recipe&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.contexts, _contexts)&&const DeepCollectionEquality().equals(other.placement, _placement)&&const DeepCollectionEquality().equals(other.allergens, _allergens)&&const DeepCollectionEquality().equals(other.dietTags, _dietTags)&&const DeepCollectionEquality().equals(other.ingredients, _ingredients)&&const DeepCollectionEquality().equals(other.steps, _steps)&&(identical(other.servings, servings) || other.servings == servings)&&(identical(other.prepMinutes, prepMinutes) || other.prepMinutes == prepMinutes)&&(identical(other.prepAhead, prepAhead) || other.prepAhead == prepAhead)&&(identical(other.prepNote, prepNote) || other.prepNote == prepNote)&&(identical(other.isAiDrafted, isAiDrafted) || other.isAiDrafted == isAiDrafted)&&(identical(other.about, about) || other.about == about)&&(identical(other.cuisine, cuisine) || other.cuisine == cuisine)&&const DeepCollectionEquality().equals(other.tags, _tags)&&(identical(other.cookMinutes, cookMinutes) || other.cookMinutes == cookMinutes)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.photo, photo) || other.photo == photo));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,id,name,summary,const DeepCollectionEquality().hash(_contexts),const DeepCollectionEquality().hash(_placement),const DeepCollectionEquality().hash(_allergens),const DeepCollectionEquality().hash(_dietTags),const DeepCollectionEquality().hash(_ingredients),const DeepCollectionEquality().hash(_steps),servings,prepMinutes,prepAhead,prepNote,isAiDrafted,about,cuisine,const DeepCollectionEquality().hash(_tags),cookMinutes,difficulty,photo]);
}

@override
String toString() {
    return 'Recipe(id: $id, name: $name, summary: $summary, contexts: $contexts, placement: $placement, allergens: $allergens, dietTags: $dietTags, ingredients: $ingredients, steps: $steps, servings: $servings, prepMinutes: $prepMinutes, prepAhead: $prepAhead, prepNote: $prepNote, isAiDrafted: $isAiDrafted, about: $about, cuisine: $cuisine, tags: $tags, cookMinutes: $cookMinutes, difficulty: $difficulty, photo: $photo)';
}


}

/// @nodoc
abstract mixin class _$RecipeCopyWith<$Res> implements $RecipeCopyWith<$Res> {
  factory _$RecipeCopyWith(_Recipe value, $Res Function(_Recipe) _then) = __$RecipeCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String summary, Set<RecipeContext> contexts, Map<RecipeContext, String> placement, Set<Allergen> allergens, List<String> dietTags, List<RecipeIngredient> ingredients, List<String> steps, int servings, int prepMinutes, bool prepAhead, String? prepNote, bool isAiDrafted, String? about, RecipeCuisine? cuisine, Set<RecipeTag> tags, int cookMinutes, RecipeDifficulty? difficulty, RecipePhoto? photo
});


@override $RecipePhotoCopyWith<$Res>? get photo;

}
/// @nodoc
class __$RecipeCopyWithImpl<$Res>
    implements _$RecipeCopyWith<$Res> {
  __$RecipeCopyWithImpl(this._self, this._then);

  final _Recipe _self;
  final $Res Function(_Recipe) _then;

/// Create a copy of Recipe
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? summary = null,Object? contexts = null,Object? placement = null,Object? allergens = null,Object? dietTags = null,Object? ingredients = null,Object? steps = null,Object? servings = null,Object? prepMinutes = null,Object? prepAhead = null,Object? prepNote = freezed,Object? isAiDrafted = null,Object? about = freezed,Object? cuisine = freezed,Object? tags = null,Object? cookMinutes = null,Object? difficulty = freezed,Object? photo = freezed,}) {
  return _then(_Recipe(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,contexts: null == contexts ? _self._contexts : contexts // ignore: cast_nullable_to_non_nullable
as Set<RecipeContext>,placement: null == placement ? _self._placement : placement // ignore: cast_nullable_to_non_nullable
as Map<RecipeContext, String>,allergens: null == allergens ? _self._allergens : allergens // ignore: cast_nullable_to_non_nullable
as Set<Allergen>,dietTags: null == dietTags ? _self._dietTags : dietTags // ignore: cast_nullable_to_non_nullable
as List<String>,ingredients: null == ingredients ? _self._ingredients : ingredients // ignore: cast_nullable_to_non_nullable
as List<RecipeIngredient>,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<String>,servings: null == servings ? _self.servings : servings // ignore: cast_nullable_to_non_nullable
as int,prepMinutes: null == prepMinutes ? _self.prepMinutes : prepMinutes // ignore: cast_nullable_to_non_nullable
as int,prepAhead: null == prepAhead ? _self.prepAhead : prepAhead // ignore: cast_nullable_to_non_nullable
as bool,prepNote: freezed == prepNote ? _self.prepNote : prepNote // ignore: cast_nullable_to_non_nullable
as String?,isAiDrafted: null == isAiDrafted ? _self.isAiDrafted : isAiDrafted // ignore: cast_nullable_to_non_nullable
as bool,about: freezed == about ? _self.about : about // ignore: cast_nullable_to_non_nullable
as String?,cuisine: freezed == cuisine ? _self.cuisine : cuisine // ignore: cast_nullable_to_non_nullable
as RecipeCuisine?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as Set<RecipeTag>,cookMinutes: null == cookMinutes ? _self.cookMinutes : cookMinutes // ignore: cast_nullable_to_non_nullable
as int,difficulty: freezed == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as RecipeDifficulty?,photo: freezed == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as RecipePhoto?,
  ));
}

/// Create a copy of Recipe
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecipePhotoCopyWith<$Res>? get photo {
    if (_self.photo == null) {
    return null;
  }

  return $RecipePhotoCopyWith<$Res>(_self.photo!, (value) {
    return _then(_self.copyWith(photo: value));
  });
}
}

// dart format on

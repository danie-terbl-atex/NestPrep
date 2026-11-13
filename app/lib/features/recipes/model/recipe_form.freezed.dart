// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe_form.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RecipeForm implements DiagnosticableTreeMixin {

 String get name; String get summary; String get notes; Map<RecipeContext, RecipeCourse> get placement; String get servings; String get prepMinutes; String get cookMinutes; List<RecipeFormEntry> get entries; List<RecipeFormStep> get steps; Set<Allergen> get alsoContains; List<RecipeFormPhoto> get photos; RecipeOrigin get origin; String? get sourceUrl; String? get sourceName; int get lastRowId;
/// Create a copy of RecipeForm
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipeFormCopyWith<RecipeForm> get copyWith => _$RecipeFormCopyWithImpl<RecipeForm>(this as RecipeForm, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as RecipeForm;
  properties
    ..add(DiagnosticsProperty('type', 'RecipeForm'))
    ..add(DiagnosticsProperty('name', _this.name))..add(DiagnosticsProperty('summary', _this.summary))..add(DiagnosticsProperty('notes', _this.notes))..add(DiagnosticsProperty('placement', _this.placement))..add(DiagnosticsProperty('servings', _this.servings))..add(DiagnosticsProperty('prepMinutes', _this.prepMinutes))..add(DiagnosticsProperty('cookMinutes', _this.cookMinutes))..add(DiagnosticsProperty('entries', _this.entries))..add(DiagnosticsProperty('steps', _this.steps))..add(DiagnosticsProperty('alsoContains', _this.alsoContains))..add(DiagnosticsProperty('photos', _this.photos))..add(DiagnosticsProperty('origin', _this.origin))..add(DiagnosticsProperty('sourceUrl', _this.sourceUrl))..add(DiagnosticsProperty('sourceName', _this.sourceName))..add(DiagnosticsProperty('lastRowId', _this.lastRowId));
}

@override
bool operator ==(Object other) {
  final _this = this as RecipeForm;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecipeForm&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.summary, _this.summary) || other.summary == _this.summary)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&const DeepCollectionEquality().equals(other.placement, _this.placement)&&(identical(other.servings, _this.servings) || other.servings == _this.servings)&&(identical(other.prepMinutes, _this.prepMinutes) || other.prepMinutes == _this.prepMinutes)&&(identical(other.cookMinutes, _this.cookMinutes) || other.cookMinutes == _this.cookMinutes)&&const DeepCollectionEquality().equals(other.entries, _this.entries)&&const DeepCollectionEquality().equals(other.steps, _this.steps)&&const DeepCollectionEquality().equals(other.alsoContains, _this.alsoContains)&&const DeepCollectionEquality().equals(other.photos, _this.photos)&&(identical(other.origin, _this.origin) || other.origin == _this.origin)&&(identical(other.sourceUrl, _this.sourceUrl) || other.sourceUrl == _this.sourceUrl)&&(identical(other.sourceName, _this.sourceName) || other.sourceName == _this.sourceName)&&(identical(other.lastRowId, _this.lastRowId) || other.lastRowId == _this.lastRowId));
}


@override
int get hashCode {
  final _this = this as RecipeForm;
  return Object.hash(runtimeType,_this.name,_this.summary,_this.notes,const DeepCollectionEquality().hash(_this.placement),_this.servings,_this.prepMinutes,_this.cookMinutes,const DeepCollectionEquality().hash(_this.entries),const DeepCollectionEquality().hash(_this.steps),const DeepCollectionEquality().hash(_this.alsoContains),const DeepCollectionEquality().hash(_this.photos),_this.origin,_this.sourceUrl,_this.sourceName,_this.lastRowId);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as RecipeForm;
  return 'RecipeForm(name: ${_this.name}, summary: ${_this.summary}, notes: ${_this.notes}, placement: ${_this.placement}, servings: ${_this.servings}, prepMinutes: ${_this.prepMinutes}, cookMinutes: ${_this.cookMinutes}, entries: ${_this.entries}, steps: ${_this.steps}, alsoContains: ${_this.alsoContains}, photos: ${_this.photos}, origin: ${_this.origin}, sourceUrl: ${_this.sourceUrl}, sourceName: ${_this.sourceName}, lastRowId: ${_this.lastRowId})';
}


}

/// @nodoc
abstract mixin class $RecipeFormCopyWith<$Res>  {
  factory $RecipeFormCopyWith(RecipeForm value, $Res Function(RecipeForm) _then) = _$RecipeFormCopyWithImpl;
@useResult
$Res call({
 String name, String summary, String notes, Map<RecipeContext, RecipeCourse> placement, String servings, String prepMinutes, String cookMinutes, List<RecipeFormEntry> entries, List<RecipeFormStep> steps, Set<Allergen> alsoContains, List<RecipeFormPhoto> photos, RecipeOrigin origin, String? sourceUrl, String? sourceName, int lastRowId
});




}
/// @nodoc
class _$RecipeFormCopyWithImpl<$Res>
    implements $RecipeFormCopyWith<$Res> {
  _$RecipeFormCopyWithImpl(this._self, this._then);

  final RecipeForm _self;
  final $Res Function(RecipeForm) _then;

/// Create a copy of RecipeForm
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? summary = null,Object? notes = null,Object? placement = null,Object? servings = null,Object? prepMinutes = null,Object? cookMinutes = null,Object? entries = null,Object? steps = null,Object? alsoContains = null,Object? photos = null,Object? origin = null,Object? sourceUrl = freezed,Object? sourceName = freezed,Object? lastRowId = null,}) {
  return _then(RecipeForm(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,placement: null == placement ? _self.placement : placement // ignore: cast_nullable_to_non_nullable
as Map<RecipeContext, RecipeCourse>,servings: null == servings ? _self.servings : servings // ignore: cast_nullable_to_non_nullable
as String,prepMinutes: null == prepMinutes ? _self.prepMinutes : prepMinutes // ignore: cast_nullable_to_non_nullable
as String,cookMinutes: null == cookMinutes ? _self.cookMinutes : cookMinutes // ignore: cast_nullable_to_non_nullable
as String,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<RecipeFormEntry>,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<RecipeFormStep>,alsoContains: null == alsoContains ? _self.alsoContains : alsoContains // ignore: cast_nullable_to_non_nullable
as Set<Allergen>,photos: null == photos ? _self.photos : photos // ignore: cast_nullable_to_non_nullable
as List<RecipeFormPhoto>,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as RecipeOrigin,sourceUrl: freezed == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String?,sourceName: freezed == sourceName ? _self.sourceName : sourceName // ignore: cast_nullable_to_non_nullable
as String?,lastRowId: null == lastRowId ? _self.lastRowId : lastRowId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RecipeForm].
extension RecipeFormPatterns on RecipeForm {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecipeForm value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecipeForm() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecipeForm value)  $default,){
final _that = this;
switch (_that) {
case _RecipeForm():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecipeForm value)?  $default,){
final _that = this;
switch (_that) {
case _RecipeForm() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String summary,  String notes,  Map<RecipeContext, RecipeCourse> placement,  String servings,  String prepMinutes,  String cookMinutes,  List<RecipeFormEntry> entries,  List<RecipeFormStep> steps,  Set<Allergen> alsoContains,  List<RecipeFormPhoto> photos,  RecipeOrigin origin,  String? sourceUrl,  String? sourceName,  int lastRowId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecipeForm() when $default != null:
return $default(_that.name,_that.summary,_that.notes,_that.placement,_that.servings,_that.prepMinutes,_that.cookMinutes,_that.entries,_that.steps,_that.alsoContains,_that.photos,_that.origin,_that.sourceUrl,_that.sourceName,_that.lastRowId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String summary,  String notes,  Map<RecipeContext, RecipeCourse> placement,  String servings,  String prepMinutes,  String cookMinutes,  List<RecipeFormEntry> entries,  List<RecipeFormStep> steps,  Set<Allergen> alsoContains,  List<RecipeFormPhoto> photos,  RecipeOrigin origin,  String? sourceUrl,  String? sourceName,  int lastRowId)  $default,) {final _that = this;
switch (_that) {
case _RecipeForm():
return $default(_that.name,_that.summary,_that.notes,_that.placement,_that.servings,_that.prepMinutes,_that.cookMinutes,_that.entries,_that.steps,_that.alsoContains,_that.photos,_that.origin,_that.sourceUrl,_that.sourceName,_that.lastRowId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String summary,  String notes,  Map<RecipeContext, RecipeCourse> placement,  String servings,  String prepMinutes,  String cookMinutes,  List<RecipeFormEntry> entries,  List<RecipeFormStep> steps,  Set<Allergen> alsoContains,  List<RecipeFormPhoto> photos,  RecipeOrigin origin,  String? sourceUrl,  String? sourceName,  int lastRowId)?  $default,) {final _that = this;
switch (_that) {
case _RecipeForm() when $default != null:
return $default(_that.name,_that.summary,_that.notes,_that.placement,_that.servings,_that.prepMinutes,_that.cookMinutes,_that.entries,_that.steps,_that.alsoContains,_that.photos,_that.origin,_that.sourceUrl,_that.sourceName,_that.lastRowId);case _:
  return null;

}
}

}

/// @nodoc


class _RecipeForm extends RecipeForm with DiagnosticableTreeMixin {
  const _RecipeForm({this.name = '', this.summary = '', this.notes = '',  Map<RecipeContext, RecipeCourse> placement = const <RecipeContext, RecipeCourse>{}, this.servings = '4', this.prepMinutes = '', this.cookMinutes = '',  List<RecipeFormEntry> entries = const <RecipeFormEntry>[],  List<RecipeFormStep> steps = const <RecipeFormStep>[],  Set<Allergen> alsoContains = const <Allergen>{},  List<RecipeFormPhoto> photos = const <RecipeFormPhoto>[], this.origin = RecipeOrigin.typed, this.sourceUrl, this.sourceName, this.lastRowId = 0}): _placement = placement,_entries = entries,_steps = steps,_alsoContains = alsoContains,_photos = photos,super._();
  

@override@JsonKey() final  String name;
@override@JsonKey() final  String summary;
@override@JsonKey() final  String notes;
 final  Map<RecipeContext, RecipeCourse> _placement;
@override@JsonKey() Map<RecipeContext, RecipeCourse> get placement {
  if (_placement is EqualUnmodifiableMapView) return _placement;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_placement);
}

@override@JsonKey() final  String servings;
@override@JsonKey() final  String prepMinutes;
@override@JsonKey() final  String cookMinutes;
 final  List<RecipeFormEntry> _entries;
@override@JsonKey() List<RecipeFormEntry> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}

 final  List<RecipeFormStep> _steps;
@override@JsonKey() List<RecipeFormStep> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}

 final  Set<Allergen> _alsoContains;
@override@JsonKey() Set<Allergen> get alsoContains {
  if (_alsoContains is EqualUnmodifiableSetView) return _alsoContains;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_alsoContains);
}

 final  List<RecipeFormPhoto> _photos;
@override@JsonKey() List<RecipeFormPhoto> get photos {
  if (_photos is EqualUnmodifiableListView) return _photos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photos);
}

@override@JsonKey() final  RecipeOrigin origin;
@override final  String? sourceUrl;
@override final  String? sourceName;
@override@JsonKey() final  int lastRowId;

/// Create a copy of RecipeForm
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipeFormCopyWith<_RecipeForm> get copyWith => __$RecipeFormCopyWithImpl<_RecipeForm>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'RecipeForm'))
    ..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('summary', summary))..add(DiagnosticsProperty('notes', notes))..add(DiagnosticsProperty('placement', placement))..add(DiagnosticsProperty('servings', servings))..add(DiagnosticsProperty('prepMinutes', prepMinutes))..add(DiagnosticsProperty('cookMinutes', cookMinutes))..add(DiagnosticsProperty('entries', entries))..add(DiagnosticsProperty('steps', steps))..add(DiagnosticsProperty('alsoContains', alsoContains))..add(DiagnosticsProperty('photos', photos))..add(DiagnosticsProperty('origin', origin))..add(DiagnosticsProperty('sourceUrl', sourceUrl))..add(DiagnosticsProperty('sourceName', sourceName))..add(DiagnosticsProperty('lastRowId', lastRowId));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecipeForm&&(identical(other.name, name) || other.name == name)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.notes, notes) || other.notes == notes)&&const DeepCollectionEquality().equals(other.placement, _placement)&&(identical(other.servings, servings) || other.servings == servings)&&(identical(other.prepMinutes, prepMinutes) || other.prepMinutes == prepMinutes)&&(identical(other.cookMinutes, cookMinutes) || other.cookMinutes == cookMinutes)&&const DeepCollectionEquality().equals(other.entries, _entries)&&const DeepCollectionEquality().equals(other.steps, _steps)&&const DeepCollectionEquality().equals(other.alsoContains, _alsoContains)&&const DeepCollectionEquality().equals(other.photos, _photos)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.sourceUrl, sourceUrl) || other.sourceUrl == sourceUrl)&&(identical(other.sourceName, sourceName) || other.sourceName == sourceName)&&(identical(other.lastRowId, lastRowId) || other.lastRowId == lastRowId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,summary,notes,const DeepCollectionEquality().hash(_placement),servings,prepMinutes,cookMinutes,const DeepCollectionEquality().hash(_entries),const DeepCollectionEquality().hash(_steps),const DeepCollectionEquality().hash(_alsoContains),const DeepCollectionEquality().hash(_photos),origin,sourceUrl,sourceName,lastRowId);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'RecipeForm(name: $name, summary: $summary, notes: $notes, placement: $placement, servings: $servings, prepMinutes: $prepMinutes, cookMinutes: $cookMinutes, entries: $entries, steps: $steps, alsoContains: $alsoContains, photos: $photos, origin: $origin, sourceUrl: $sourceUrl, sourceName: $sourceName, lastRowId: $lastRowId)';
}


}

/// @nodoc
abstract mixin class _$RecipeFormCopyWith<$Res> implements $RecipeFormCopyWith<$Res> {
  factory _$RecipeFormCopyWith(_RecipeForm value, $Res Function(_RecipeForm) _then) = __$RecipeFormCopyWithImpl;
@override @useResult
$Res call({
 String name, String summary, String notes, Map<RecipeContext, RecipeCourse> placement, String servings, String prepMinutes, String cookMinutes, List<RecipeFormEntry> entries, List<RecipeFormStep> steps, Set<Allergen> alsoContains, List<RecipeFormPhoto> photos, RecipeOrigin origin, String? sourceUrl, String? sourceName, int lastRowId
});




}
/// @nodoc
class __$RecipeFormCopyWithImpl<$Res>
    implements _$RecipeFormCopyWith<$Res> {
  __$RecipeFormCopyWithImpl(this._self, this._then);

  final _RecipeForm _self;
  final $Res Function(_RecipeForm) _then;

/// Create a copy of RecipeForm
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? summary = null,Object? notes = null,Object? placement = null,Object? servings = null,Object? prepMinutes = null,Object? cookMinutes = null,Object? entries = null,Object? steps = null,Object? alsoContains = null,Object? photos = null,Object? origin = null,Object? sourceUrl = freezed,Object? sourceName = freezed,Object? lastRowId = null,}) {
  return _then(_RecipeForm(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,placement: null == placement ? _self._placement : placement // ignore: cast_nullable_to_non_nullable
as Map<RecipeContext, RecipeCourse>,servings: null == servings ? _self.servings : servings // ignore: cast_nullable_to_non_nullable
as String,prepMinutes: null == prepMinutes ? _self.prepMinutes : prepMinutes // ignore: cast_nullable_to_non_nullable
as String,cookMinutes: null == cookMinutes ? _self.cookMinutes : cookMinutes // ignore: cast_nullable_to_non_nullable
as String,entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<RecipeFormEntry>,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<RecipeFormStep>,alsoContains: null == alsoContains ? _self._alsoContains : alsoContains // ignore: cast_nullable_to_non_nullable
as Set<Allergen>,photos: null == photos ? _self._photos : photos // ignore: cast_nullable_to_non_nullable
as List<RecipeFormPhoto>,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as RecipeOrigin,sourceUrl: freezed == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String?,sourceName: freezed == sourceName ? _self.sourceName : sourceName // ignore: cast_nullable_to_non_nullable
as String?,lastRowId: null == lastRowId ? _self.lastRowId : lastRowId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

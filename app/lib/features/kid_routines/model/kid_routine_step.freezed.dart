// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kid_routine_step.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$KidRoutinePart {

 String get id; String get text;@JsonKey(includeIfNull: false) String? get picture; List<int> get weekdays;
/// Create a copy of KidRoutinePart
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KidRoutinePartCopyWith<KidRoutinePart> get copyWith => _$KidRoutinePartCopyWithImpl<KidRoutinePart>(this as KidRoutinePart, _$identity);

  /// Serializes this KidRoutinePart to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as KidRoutinePart;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KidRoutinePart&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.picture, _this.picture) || other.picture == _this.picture)&&const DeepCollectionEquality().equals(other.weekdays, _this.weekdays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as KidRoutinePart;
  return Object.hash(runtimeType,_this.id,_this.text,_this.picture,const DeepCollectionEquality().hash(_this.weekdays));
}

@override
String toString() {
  final _this = this as KidRoutinePart;
  return 'KidRoutinePart(id: ${_this.id}, text: ${_this.text}, picture: ${_this.picture}, weekdays: ${_this.weekdays})';
}


}

/// @nodoc
abstract mixin class $KidRoutinePartCopyWith<$Res>  {
  factory $KidRoutinePartCopyWith(KidRoutinePart value, $Res Function(KidRoutinePart) _then) = _$KidRoutinePartCopyWithImpl;
@useResult
$Res call({
 String id, String text,@JsonKey(includeIfNull: false) String? picture, List<int> weekdays
});




}
/// @nodoc
class _$KidRoutinePartCopyWithImpl<$Res>
    implements $KidRoutinePartCopyWith<$Res> {
  _$KidRoutinePartCopyWithImpl(this._self, this._then);

  final KidRoutinePart _self;
  final $Res Function(KidRoutinePart) _then;

/// Create a copy of KidRoutinePart
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? text = null,Object? picture = freezed,Object? weekdays = null,}) {
  return _then(KidRoutinePart(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,picture: freezed == picture ? _self.picture : picture // ignore: cast_nullable_to_non_nullable
as String?,weekdays: null == weekdays ? _self.weekdays : weekdays // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}

}


/// Adds pattern-matching-related methods to [KidRoutinePart].
extension KidRoutinePartPatterns on KidRoutinePart {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KidRoutinePart value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KidRoutinePart() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KidRoutinePart value)  $default,){
final _that = this;
switch (_that) {
case _KidRoutinePart():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KidRoutinePart value)?  $default,){
final _that = this;
switch (_that) {
case _KidRoutinePart() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String text, @JsonKey(includeIfNull: false)  String? picture,  List<int> weekdays)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KidRoutinePart() when $default != null:
return $default(_that.id,_that.text,_that.picture,_that.weekdays);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String text, @JsonKey(includeIfNull: false)  String? picture,  List<int> weekdays)  $default,) {final _that = this;
switch (_that) {
case _KidRoutinePart():
return $default(_that.id,_that.text,_that.picture,_that.weekdays);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String text, @JsonKey(includeIfNull: false)  String? picture,  List<int> weekdays)?  $default,) {final _that = this;
switch (_that) {
case _KidRoutinePart() when $default != null:
return $default(_that.id,_that.text,_that.picture,_that.weekdays);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _KidRoutinePart extends KidRoutinePart {
  const _KidRoutinePart({required this.id, required this.text, @JsonKey(includeIfNull: false) this.picture,  List<int> weekdays = const <int>[]}): _weekdays = weekdays,super._();
  factory _KidRoutinePart.fromJson(Map<String, dynamic> json) => _$KidRoutinePartFromJson(json);

@override final  String id;
@override final  String text;
@override@JsonKey(includeIfNull: false) final  String? picture;
 final  List<int> _weekdays;
@override@JsonKey() List<int> get weekdays {
  if (_weekdays is EqualUnmodifiableListView) return _weekdays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_weekdays);
}


/// Create a copy of KidRoutinePart
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KidRoutinePartCopyWith<_KidRoutinePart> get copyWith => __$KidRoutinePartCopyWithImpl<_KidRoutinePart>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KidRoutinePartToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _KidRoutinePart&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.picture, picture) || other.picture == picture)&&const DeepCollectionEquality().equals(other.weekdays, _weekdays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,text,picture,const DeepCollectionEquality().hash(_weekdays));
}

@override
String toString() {
    return 'KidRoutinePart(id: $id, text: $text, picture: $picture, weekdays: $weekdays)';
}


}

/// @nodoc
abstract mixin class _$KidRoutinePartCopyWith<$Res> implements $KidRoutinePartCopyWith<$Res> {
  factory _$KidRoutinePartCopyWith(_KidRoutinePart value, $Res Function(_KidRoutinePart) _then) = __$KidRoutinePartCopyWithImpl;
@override @useResult
$Res call({
 String id, String text,@JsonKey(includeIfNull: false) String? picture, List<int> weekdays
});




}
/// @nodoc
class __$KidRoutinePartCopyWithImpl<$Res>
    implements _$KidRoutinePartCopyWith<$Res> {
  __$KidRoutinePartCopyWithImpl(this._self, this._then);

  final _KidRoutinePart _self;
  final $Res Function(_KidRoutinePart) _then;

/// Create a copy of KidRoutinePart
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? text = null,Object? picture = freezed,Object? weekdays = null,}) {
  return _then(_KidRoutinePart(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,picture: freezed == picture ? _self.picture : picture // ignore: cast_nullable_to_non_nullable
as String?,weekdays: null == weekdays ? _self._weekdays : weekdays // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}


/// @nodoc
mixin _$KidRoutineStep {

 String get id; String get title;@JsonKey(includeIfNull: false) String? get picture;@JsonKey(includeIfNull: false) String? get note; List<KidRoutinePart> get parts;
/// Create a copy of KidRoutineStep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KidRoutineStepCopyWith<KidRoutineStep> get copyWith => _$KidRoutineStepCopyWithImpl<KidRoutineStep>(this as KidRoutineStep, _$identity);

  /// Serializes this KidRoutineStep to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as KidRoutineStep;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KidRoutineStep&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.picture, _this.picture) || other.picture == _this.picture)&&(identical(other.note, _this.note) || other.note == _this.note)&&const DeepCollectionEquality().equals(other.parts, _this.parts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as KidRoutineStep;
  return Object.hash(runtimeType,_this.id,_this.title,_this.picture,_this.note,const DeepCollectionEquality().hash(_this.parts));
}

@override
String toString() {
  final _this = this as KidRoutineStep;
  return 'KidRoutineStep(id: ${_this.id}, title: ${_this.title}, picture: ${_this.picture}, note: ${_this.note}, parts: ${_this.parts})';
}


}

/// @nodoc
abstract mixin class $KidRoutineStepCopyWith<$Res>  {
  factory $KidRoutineStepCopyWith(KidRoutineStep value, $Res Function(KidRoutineStep) _then) = _$KidRoutineStepCopyWithImpl;
@useResult
$Res call({
 String id, String title,@JsonKey(includeIfNull: false) String? picture,@JsonKey(includeIfNull: false) String? note, List<KidRoutinePart> parts
});




}
/// @nodoc
class _$KidRoutineStepCopyWithImpl<$Res>
    implements $KidRoutineStepCopyWith<$Res> {
  _$KidRoutineStepCopyWithImpl(this._self, this._then);

  final KidRoutineStep _self;
  final $Res Function(KidRoutineStep) _then;

/// Create a copy of KidRoutineStep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? picture = freezed,Object? note = freezed,Object? parts = null,}) {
  return _then(KidRoutineStep(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,picture: freezed == picture ? _self.picture : picture // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,parts: null == parts ? _self.parts : parts // ignore: cast_nullable_to_non_nullable
as List<KidRoutinePart>,
  ));
}

}


/// Adds pattern-matching-related methods to [KidRoutineStep].
extension KidRoutineStepPatterns on KidRoutineStep {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KidRoutineStep value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KidRoutineStep() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KidRoutineStep value)  $default,){
final _that = this;
switch (_that) {
case _KidRoutineStep():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KidRoutineStep value)?  $default,){
final _that = this;
switch (_that) {
case _KidRoutineStep() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title, @JsonKey(includeIfNull: false)  String? picture, @JsonKey(includeIfNull: false)  String? note,  List<KidRoutinePart> parts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KidRoutineStep() when $default != null:
return $default(_that.id,_that.title,_that.picture,_that.note,_that.parts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title, @JsonKey(includeIfNull: false)  String? picture, @JsonKey(includeIfNull: false)  String? note,  List<KidRoutinePart> parts)  $default,) {final _that = this;
switch (_that) {
case _KidRoutineStep():
return $default(_that.id,_that.title,_that.picture,_that.note,_that.parts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title, @JsonKey(includeIfNull: false)  String? picture, @JsonKey(includeIfNull: false)  String? note,  List<KidRoutinePart> parts)?  $default,) {final _that = this;
switch (_that) {
case _KidRoutineStep() when $default != null:
return $default(_that.id,_that.title,_that.picture,_that.note,_that.parts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _KidRoutineStep implements KidRoutineStep {
  const _KidRoutineStep({required this.id, required this.title, @JsonKey(includeIfNull: false) this.picture, @JsonKey(includeIfNull: false) this.note,  List<KidRoutinePart> parts = const <KidRoutinePart>[]}): _parts = parts;
  factory _KidRoutineStep.fromJson(Map<String, dynamic> json) => _$KidRoutineStepFromJson(json);

@override final  String id;
@override final  String title;
@override@JsonKey(includeIfNull: false) final  String? picture;
@override@JsonKey(includeIfNull: false) final  String? note;
 final  List<KidRoutinePart> _parts;
@override@JsonKey() List<KidRoutinePart> get parts {
  if (_parts is EqualUnmodifiableListView) return _parts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_parts);
}


/// Create a copy of KidRoutineStep
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KidRoutineStepCopyWith<_KidRoutineStep> get copyWith => __$KidRoutineStepCopyWithImpl<_KidRoutineStep>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KidRoutineStepToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _KidRoutineStep&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.picture, picture) || other.picture == picture)&&(identical(other.note, note) || other.note == note)&&const DeepCollectionEquality().equals(other.parts, _parts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,picture,note,const DeepCollectionEquality().hash(_parts));
}

@override
String toString() {
    return 'KidRoutineStep(id: $id, title: $title, picture: $picture, note: $note, parts: $parts)';
}


}

/// @nodoc
abstract mixin class _$KidRoutineStepCopyWith<$Res> implements $KidRoutineStepCopyWith<$Res> {
  factory _$KidRoutineStepCopyWith(_KidRoutineStep value, $Res Function(_KidRoutineStep) _then) = __$KidRoutineStepCopyWithImpl;
@override @useResult
$Res call({
 String id, String title,@JsonKey(includeIfNull: false) String? picture,@JsonKey(includeIfNull: false) String? note, List<KidRoutinePart> parts
});




}
/// @nodoc
class __$KidRoutineStepCopyWithImpl<$Res>
    implements _$KidRoutineStepCopyWith<$Res> {
  __$KidRoutineStepCopyWithImpl(this._self, this._then);

  final _KidRoutineStep _self;
  final $Res Function(_KidRoutineStep) _then;

/// Create a copy of KidRoutineStep
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? picture = freezed,Object? note = freezed,Object? parts = null,}) {
  return _then(_KidRoutineStep(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,picture: freezed == picture ? _self.picture : picture // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,parts: null == parts ? _self._parts : parts // ignore: cast_nullable_to_non_nullable
as List<KidRoutinePart>,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lunch_choices.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LunchChoices {

@JsonKey(includeToJson: false) String get id; String get childId; String get week; Map<String, List<LunchPick>> get options; Map<String, String> get chosen;/// The school day (`'1'`–`'5'`) a parent's last write changed — the
/// rules check that day's options, and only that day's, so a write stays
/// inside their thousand-expression budget.
 String? get editedDay;/// The slot key the child last chose — what the rules read, after the
/// batch, to know which one slot of the plan a child's write changed.
 String? get chosenKey; String get updatedBy;@ServerTimestampConverter() DateTime? get updatedAt;
/// Create a copy of LunchChoices
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LunchChoicesCopyWith<LunchChoices> get copyWith => _$LunchChoicesCopyWithImpl<LunchChoices>(this as LunchChoices, _$identity);

  /// Serializes this LunchChoices to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LunchChoices;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LunchChoices&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.childId, _this.childId) || other.childId == _this.childId)&&(identical(other.week, _this.week) || other.week == _this.week)&&const DeepCollectionEquality().equals(other.options, _this.options)&&const DeepCollectionEquality().equals(other.chosen, _this.chosen)&&(identical(other.editedDay, _this.editedDay) || other.editedDay == _this.editedDay)&&(identical(other.chosenKey, _this.chosenKey) || other.chosenKey == _this.chosenKey)&&(identical(other.updatedBy, _this.updatedBy) || other.updatedBy == _this.updatedBy)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LunchChoices;
  return Object.hash(runtimeType,_this.id,_this.childId,_this.week,const DeepCollectionEquality().hash(_this.options),const DeepCollectionEquality().hash(_this.chosen),_this.editedDay,_this.chosenKey,_this.updatedBy,_this.updatedAt);
}

@override
String toString() {
  final _this = this as LunchChoices;
  return 'LunchChoices(id: ${_this.id}, childId: ${_this.childId}, week: ${_this.week}, options: ${_this.options}, chosen: ${_this.chosen}, editedDay: ${_this.editedDay}, chosenKey: ${_this.chosenKey}, updatedBy: ${_this.updatedBy}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $LunchChoicesCopyWith<$Res>  {
  factory $LunchChoicesCopyWith(LunchChoices value, $Res Function(LunchChoices) _then) = _$LunchChoicesCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String childId, String week, Map<String, List<LunchPick>> options, Map<String, String> chosen, String? editedDay, String? chosenKey, String updatedBy,@ServerTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$LunchChoicesCopyWithImpl<$Res>
    implements $LunchChoicesCopyWith<$Res> {
  _$LunchChoicesCopyWithImpl(this._self, this._then);

  final LunchChoices _self;
  final $Res Function(LunchChoices) _then;

/// Create a copy of LunchChoices
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? childId = null,Object? week = null,Object? options = null,Object? chosen = null,Object? editedDay = freezed,Object? chosenKey = freezed,Object? updatedBy = null,Object? updatedAt = freezed,}) {
  return _then(LunchChoices(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,childId: null == childId ? _self.childId : childId // ignore: cast_nullable_to_non_nullable
as String,week: null == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as Map<String, List<LunchPick>>,chosen: null == chosen ? _self.chosen : chosen // ignore: cast_nullable_to_non_nullable
as Map<String, String>,editedDay: freezed == editedDay ? _self.editedDay : editedDay // ignore: cast_nullable_to_non_nullable
as String?,chosenKey: freezed == chosenKey ? _self.chosenKey : chosenKey // ignore: cast_nullable_to_non_nullable
as String?,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [LunchChoices].
extension LunchChoicesPatterns on LunchChoices {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LunchChoices value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LunchChoices() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LunchChoices value)  $default,){
final _that = this;
switch (_that) {
case _LunchChoices():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LunchChoices value)?  $default,){
final _that = this;
switch (_that) {
case _LunchChoices() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String childId,  String week,  Map<String, List<LunchPick>> options,  Map<String, String> chosen,  String? editedDay,  String? chosenKey,  String updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LunchChoices() when $default != null:
return $default(_that.id,_that.childId,_that.week,_that.options,_that.chosen,_that.editedDay,_that.chosenKey,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String childId,  String week,  Map<String, List<LunchPick>> options,  Map<String, String> chosen,  String? editedDay,  String? chosenKey,  String updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _LunchChoices():
return $default(_that.id,_that.childId,_that.week,_that.options,_that.chosen,_that.editedDay,_that.chosenKey,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String childId,  String week,  Map<String, List<LunchPick>> options,  Map<String, String> chosen,  String? editedDay,  String? chosenKey,  String updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _LunchChoices() when $default != null:
return $default(_that.id,_that.childId,_that.week,_that.options,_that.chosen,_that.editedDay,_that.chosenKey,_that.updatedBy,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LunchChoices extends LunchChoices {
  const _LunchChoices({@JsonKey(includeToJson: false) required this.id, required this.childId, required this.week,  Map<String, List<LunchPick>> options = const <String, List<LunchPick>>{},  Map<String, String> chosen = const <String, String>{}, this.editedDay, this.chosenKey, required this.updatedBy, @ServerTimestampConverter() this.updatedAt}): _options = options,_chosen = chosen,super._();
  factory _LunchChoices.fromJson(Map<String, dynamic> json) => _$LunchChoicesFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String childId;
@override final  String week;
 final  Map<String, List<LunchPick>> _options;
@override@JsonKey() Map<String, List<LunchPick>> get options {
  if (_options is EqualUnmodifiableMapView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_options);
}

 final  Map<String, String> _chosen;
@override@JsonKey() Map<String, String> get chosen {
  if (_chosen is EqualUnmodifiableMapView) return _chosen;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_chosen);
}

/// The school day (`'1'`–`'5'`) a parent's last write changed — the
/// rules check that day's options, and only that day's, so a write stays
/// inside their thousand-expression budget.
@override final  String? editedDay;
/// The slot key the child last chose — what the rules read, after the
/// batch, to know which one slot of the plan a child's write changed.
@override final  String? chosenKey;
@override final  String updatedBy;
@override@ServerTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of LunchChoices
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LunchChoicesCopyWith<_LunchChoices> get copyWith => __$LunchChoicesCopyWithImpl<_LunchChoices>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LunchChoicesToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LunchChoices&&(identical(other.id, id) || other.id == id)&&(identical(other.childId, childId) || other.childId == childId)&&(identical(other.week, week) || other.week == week)&&const DeepCollectionEquality().equals(other.options, _options)&&const DeepCollectionEquality().equals(other.chosen, _chosen)&&(identical(other.editedDay, editedDay) || other.editedDay == editedDay)&&(identical(other.chosenKey, chosenKey) || other.chosenKey == chosenKey)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,childId,week,const DeepCollectionEquality().hash(_options),const DeepCollectionEquality().hash(_chosen),editedDay,chosenKey,updatedBy,updatedAt);
}

@override
String toString() {
    return 'LunchChoices(id: $id, childId: $childId, week: $week, options: $options, chosen: $chosen, editedDay: $editedDay, chosenKey: $chosenKey, updatedBy: $updatedBy, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$LunchChoicesCopyWith<$Res> implements $LunchChoicesCopyWith<$Res> {
  factory _$LunchChoicesCopyWith(_LunchChoices value, $Res Function(_LunchChoices) _then) = __$LunchChoicesCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String childId, String week, Map<String, List<LunchPick>> options, Map<String, String> chosen, String? editedDay, String? chosenKey, String updatedBy,@ServerTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$LunchChoicesCopyWithImpl<$Res>
    implements _$LunchChoicesCopyWith<$Res> {
  __$LunchChoicesCopyWithImpl(this._self, this._then);

  final _LunchChoices _self;
  final $Res Function(_LunchChoices) _then;

/// Create a copy of LunchChoices
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? childId = null,Object? week = null,Object? options = null,Object? chosen = null,Object? editedDay = freezed,Object? chosenKey = freezed,Object? updatedBy = null,Object? updatedAt = freezed,}) {
  return _then(_LunchChoices(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,childId: null == childId ? _self.childId : childId // ignore: cast_nullable_to_non_nullable
as String,week: null == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as Map<String, List<LunchPick>>,chosen: null == chosen ? _self._chosen : chosen // ignore: cast_nullable_to_non_nullable
as Map<String, String>,editedDay: freezed == editedDay ? _self.editedDay : editedDay // ignore: cast_nullable_to_non_nullable
as String?,chosenKey: freezed == chosenKey ? _self.chosenKey : chosenKey // ignore: cast_nullable_to_non_nullable
as String?,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

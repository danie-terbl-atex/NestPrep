// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lunch_packed_day.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LunchPackedDay {

@JsonKey(includeToJson: false) String get id; String get childId;/// `YYYY-MM-DD` — also the tail of the id.
 String get date;/// `YYYY-Www`, which the pantry's listener reads a week by.
 String get week;/// The items taken out of the pantry — what the undo gives back.
 List<String> get itemIds; String get by;@ServerTimestampConverter() DateTime? get at;
/// Create a copy of LunchPackedDay
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LunchPackedDayCopyWith<LunchPackedDay> get copyWith => _$LunchPackedDayCopyWithImpl<LunchPackedDay>(this as LunchPackedDay, _$identity);

  /// Serializes this LunchPackedDay to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LunchPackedDay;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LunchPackedDay&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.childId, _this.childId) || other.childId == _this.childId)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.week, _this.week) || other.week == _this.week)&&const DeepCollectionEquality().equals(other.itemIds, _this.itemIds)&&(identical(other.by, _this.by) || other.by == _this.by)&&(identical(other.at, _this.at) || other.at == _this.at));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LunchPackedDay;
  return Object.hash(runtimeType,_this.id,_this.childId,_this.date,_this.week,const DeepCollectionEquality().hash(_this.itemIds),_this.by,_this.at);
}

@override
String toString() {
  final _this = this as LunchPackedDay;
  return 'LunchPackedDay(id: ${_this.id}, childId: ${_this.childId}, date: ${_this.date}, week: ${_this.week}, itemIds: ${_this.itemIds}, by: ${_this.by}, at: ${_this.at})';
}


}

/// @nodoc
abstract mixin class $LunchPackedDayCopyWith<$Res>  {
  factory $LunchPackedDayCopyWith(LunchPackedDay value, $Res Function(LunchPackedDay) _then) = _$LunchPackedDayCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String childId, String date, String week, List<String> itemIds, String by,@ServerTimestampConverter() DateTime? at
});




}
/// @nodoc
class _$LunchPackedDayCopyWithImpl<$Res>
    implements $LunchPackedDayCopyWith<$Res> {
  _$LunchPackedDayCopyWithImpl(this._self, this._then);

  final LunchPackedDay _self;
  final $Res Function(LunchPackedDay) _then;

/// Create a copy of LunchPackedDay
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? childId = null,Object? date = null,Object? week = null,Object? itemIds = null,Object? by = null,Object? at = freezed,}) {
  return _then(LunchPackedDay(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,childId: null == childId ? _self.childId : childId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,week: null == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as String,itemIds: null == itemIds ? _self.itemIds : itemIds // ignore: cast_nullable_to_non_nullable
as List<String>,by: null == by ? _self.by : by // ignore: cast_nullable_to_non_nullable
as String,at: freezed == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [LunchPackedDay].
extension LunchPackedDayPatterns on LunchPackedDay {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LunchPackedDay value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LunchPackedDay() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LunchPackedDay value)  $default,){
final _that = this;
switch (_that) {
case _LunchPackedDay():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LunchPackedDay value)?  $default,){
final _that = this;
switch (_that) {
case _LunchPackedDay() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String childId,  String date,  String week,  List<String> itemIds,  String by, @ServerTimestampConverter()  DateTime? at)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LunchPackedDay() when $default != null:
return $default(_that.id,_that.childId,_that.date,_that.week,_that.itemIds,_that.by,_that.at);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String childId,  String date,  String week,  List<String> itemIds,  String by, @ServerTimestampConverter()  DateTime? at)  $default,) {final _that = this;
switch (_that) {
case _LunchPackedDay():
return $default(_that.id,_that.childId,_that.date,_that.week,_that.itemIds,_that.by,_that.at);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String childId,  String date,  String week,  List<String> itemIds,  String by, @ServerTimestampConverter()  DateTime? at)?  $default,) {final _that = this;
switch (_that) {
case _LunchPackedDay() when $default != null:
return $default(_that.id,_that.childId,_that.date,_that.week,_that.itemIds,_that.by,_that.at);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LunchPackedDay extends LunchPackedDay {
  const _LunchPackedDay({@JsonKey(includeToJson: false) required this.id, required this.childId, required this.date, required this.week,  List<String> itemIds = const <String>[], required this.by, @ServerTimestampConverter() this.at}): _itemIds = itemIds,super._();
  factory _LunchPackedDay.fromJson(Map<String, dynamic> json) => _$LunchPackedDayFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String childId;
/// `YYYY-MM-DD` — also the tail of the id.
@override final  String date;
/// `YYYY-Www`, which the pantry's listener reads a week by.
@override final  String week;
/// The items taken out of the pantry — what the undo gives back.
 final  List<String> _itemIds;
/// The items taken out of the pantry — what the undo gives back.
@override@JsonKey() List<String> get itemIds {
  if (_itemIds is EqualUnmodifiableListView) return _itemIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_itemIds);
}

@override final  String by;
@override@ServerTimestampConverter() final  DateTime? at;

/// Create a copy of LunchPackedDay
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LunchPackedDayCopyWith<_LunchPackedDay> get copyWith => __$LunchPackedDayCopyWithImpl<_LunchPackedDay>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LunchPackedDayToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LunchPackedDay&&(identical(other.id, id) || other.id == id)&&(identical(other.childId, childId) || other.childId == childId)&&(identical(other.date, date) || other.date == date)&&(identical(other.week, week) || other.week == week)&&const DeepCollectionEquality().equals(other.itemIds, _itemIds)&&(identical(other.by, by) || other.by == by)&&(identical(other.at, at) || other.at == at));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,childId,date,week,const DeepCollectionEquality().hash(_itemIds),by,at);
}

@override
String toString() {
    return 'LunchPackedDay(id: $id, childId: $childId, date: $date, week: $week, itemIds: $itemIds, by: $by, at: $at)';
}


}

/// @nodoc
abstract mixin class _$LunchPackedDayCopyWith<$Res> implements $LunchPackedDayCopyWith<$Res> {
  factory _$LunchPackedDayCopyWith(_LunchPackedDay value, $Res Function(_LunchPackedDay) _then) = __$LunchPackedDayCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String childId, String date, String week, List<String> itemIds, String by,@ServerTimestampConverter() DateTime? at
});




}
/// @nodoc
class __$LunchPackedDayCopyWithImpl<$Res>
    implements _$LunchPackedDayCopyWith<$Res> {
  __$LunchPackedDayCopyWithImpl(this._self, this._then);

  final _LunchPackedDay _self;
  final $Res Function(_LunchPackedDay) _then;

/// Create a copy of LunchPackedDay
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? childId = null,Object? date = null,Object? week = null,Object? itemIds = null,Object? by = null,Object? at = freezed,}) {
  return _then(_LunchPackedDay(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,childId: null == childId ? _self.childId : childId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,week: null == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as String,itemIds: null == itemIds ? _self._itemIds : itemIds // ignore: cast_nullable_to_non_nullable
as List<String>,by: null == by ? _self.by : by // ignore: cast_nullable_to_non_nullable
as String,at: freezed == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

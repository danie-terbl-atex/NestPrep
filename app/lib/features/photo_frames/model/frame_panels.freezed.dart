// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'frame_panels.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FramePanels {

 bool get calendar; bool get todos; bool get meals; bool get lunch;/// Missing on a frame linked before it, which is off; a new link turns it
/// on (photo-frames ADR-0008).
 bool get addEvents; bool get share; bool get people; String? get helperMemberId;
/// Create a copy of FramePanels
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FramePanelsCopyWith<FramePanels> get copyWith => _$FramePanelsCopyWithImpl<FramePanels>(this as FramePanels, _$identity);

  /// Serializes this FramePanels to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as FramePanels;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FramePanels&&(identical(other.calendar, _this.calendar) || other.calendar == _this.calendar)&&(identical(other.todos, _this.todos) || other.todos == _this.todos)&&(identical(other.meals, _this.meals) || other.meals == _this.meals)&&(identical(other.lunch, _this.lunch) || other.lunch == _this.lunch)&&(identical(other.addEvents, _this.addEvents) || other.addEvents == _this.addEvents)&&(identical(other.share, _this.share) || other.share == _this.share)&&(identical(other.people, _this.people) || other.people == _this.people)&&(identical(other.helperMemberId, _this.helperMemberId) || other.helperMemberId == _this.helperMemberId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FramePanels;
  return Object.hash(runtimeType,_this.calendar,_this.todos,_this.meals,_this.lunch,_this.addEvents,_this.share,_this.people,_this.helperMemberId);
}

@override
String toString() {
  final _this = this as FramePanels;
  return 'FramePanels(calendar: ${_this.calendar}, todos: ${_this.todos}, meals: ${_this.meals}, lunch: ${_this.lunch}, addEvents: ${_this.addEvents}, share: ${_this.share}, people: ${_this.people}, helperMemberId: ${_this.helperMemberId})';
}


}

/// @nodoc
abstract mixin class $FramePanelsCopyWith<$Res>  {
  factory $FramePanelsCopyWith(FramePanels value, $Res Function(FramePanels) _then) = _$FramePanelsCopyWithImpl;
@useResult
$Res call({
 bool calendar, bool todos, bool meals, bool lunch, bool addEvents, bool share, bool people, String? helperMemberId
});




}
/// @nodoc
class _$FramePanelsCopyWithImpl<$Res>
    implements $FramePanelsCopyWith<$Res> {
  _$FramePanelsCopyWithImpl(this._self, this._then);

  final FramePanels _self;
  final $Res Function(FramePanels) _then;

/// Create a copy of FramePanels
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? calendar = null,Object? todos = null,Object? meals = null,Object? lunch = null,Object? addEvents = null,Object? share = null,Object? people = null,Object? helperMemberId = freezed,}) {
  return _then(FramePanels(
calendar: null == calendar ? _self.calendar : calendar // ignore: cast_nullable_to_non_nullable
as bool,todos: null == todos ? _self.todos : todos // ignore: cast_nullable_to_non_nullable
as bool,meals: null == meals ? _self.meals : meals // ignore: cast_nullable_to_non_nullable
as bool,lunch: null == lunch ? _self.lunch : lunch // ignore: cast_nullable_to_non_nullable
as bool,addEvents: null == addEvents ? _self.addEvents : addEvents // ignore: cast_nullable_to_non_nullable
as bool,share: null == share ? _self.share : share // ignore: cast_nullable_to_non_nullable
as bool,people: null == people ? _self.people : people // ignore: cast_nullable_to_non_nullable
as bool,helperMemberId: freezed == helperMemberId ? _self.helperMemberId : helperMemberId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FramePanels].
extension FramePanelsPatterns on FramePanels {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FramePanels value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FramePanels() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FramePanels value)  $default,){
final _that = this;
switch (_that) {
case _FramePanels():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FramePanels value)?  $default,){
final _that = this;
switch (_that) {
case _FramePanels() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool calendar,  bool todos,  bool meals,  bool lunch,  bool addEvents,  bool share,  bool people,  String? helperMemberId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FramePanels() when $default != null:
return $default(_that.calendar,_that.todos,_that.meals,_that.lunch,_that.addEvents,_that.share,_that.people,_that.helperMemberId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool calendar,  bool todos,  bool meals,  bool lunch,  bool addEvents,  bool share,  bool people,  String? helperMemberId)  $default,) {final _that = this;
switch (_that) {
case _FramePanels():
return $default(_that.calendar,_that.todos,_that.meals,_that.lunch,_that.addEvents,_that.share,_that.people,_that.helperMemberId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool calendar,  bool todos,  bool meals,  bool lunch,  bool addEvents,  bool share,  bool people,  String? helperMemberId)?  $default,) {final _that = this;
switch (_that) {
case _FramePanels() when $default != null:
return $default(_that.calendar,_that.todos,_that.meals,_that.lunch,_that.addEvents,_that.share,_that.people,_that.helperMemberId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FramePanels extends FramePanels {
  const _FramePanels({this.calendar = true, this.todos = true, this.meals = true, this.lunch = false, this.addEvents = false, this.share = false, this.people = false, this.helperMemberId}): super._();
  factory _FramePanels.fromJson(Map<String, dynamic> json) => _$FramePanelsFromJson(json);

@override@JsonKey() final  bool calendar;
@override@JsonKey() final  bool todos;
@override@JsonKey() final  bool meals;
@override@JsonKey() final  bool lunch;
/// Missing on a frame linked before it, which is off; a new link turns it
/// on (photo-frames ADR-0008).
@override@JsonKey() final  bool addEvents;
@override@JsonKey() final  bool share;
@override@JsonKey() final  bool people;
@override final  String? helperMemberId;

/// Create a copy of FramePanels
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FramePanelsCopyWith<_FramePanels> get copyWith => __$FramePanelsCopyWithImpl<_FramePanels>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FramePanelsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FramePanels&&(identical(other.calendar, calendar) || other.calendar == calendar)&&(identical(other.todos, todos) || other.todos == todos)&&(identical(other.meals, meals) || other.meals == meals)&&(identical(other.lunch, lunch) || other.lunch == lunch)&&(identical(other.addEvents, addEvents) || other.addEvents == addEvents)&&(identical(other.share, share) || other.share == share)&&(identical(other.people, people) || other.people == people)&&(identical(other.helperMemberId, helperMemberId) || other.helperMemberId == helperMemberId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,calendar,todos,meals,lunch,addEvents,share,people,helperMemberId);
}

@override
String toString() {
    return 'FramePanels(calendar: $calendar, todos: $todos, meals: $meals, lunch: $lunch, addEvents: $addEvents, share: $share, people: $people, helperMemberId: $helperMemberId)';
}


}

/// @nodoc
abstract mixin class _$FramePanelsCopyWith<$Res> implements $FramePanelsCopyWith<$Res> {
  factory _$FramePanelsCopyWith(_FramePanels value, $Res Function(_FramePanels) _then) = __$FramePanelsCopyWithImpl;
@override @useResult
$Res call({
 bool calendar, bool todos, bool meals, bool lunch, bool addEvents, bool share, bool people, String? helperMemberId
});




}
/// @nodoc
class __$FramePanelsCopyWithImpl<$Res>
    implements _$FramePanelsCopyWith<$Res> {
  __$FramePanelsCopyWithImpl(this._self, this._then);

  final _FramePanels _self;
  final $Res Function(_FramePanels) _then;

/// Create a copy of FramePanels
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? calendar = null,Object? todos = null,Object? meals = null,Object? lunch = null,Object? addEvents = null,Object? share = null,Object? people = null,Object? helperMemberId = freezed,}) {
  return _then(_FramePanels(
calendar: null == calendar ? _self.calendar : calendar // ignore: cast_nullable_to_non_nullable
as bool,todos: null == todos ? _self.todos : todos // ignore: cast_nullable_to_non_nullable
as bool,meals: null == meals ? _self.meals : meals // ignore: cast_nullable_to_non_nullable
as bool,lunch: null == lunch ? _self.lunch : lunch // ignore: cast_nullable_to_non_nullable
as bool,addEvents: null == addEvents ? _self.addEvents : addEvents // ignore: cast_nullable_to_non_nullable
as bool,share: null == share ? _self.share : share // ignore: cast_nullable_to_non_nullable
as bool,people: null == people ? _self.people : people // ignore: cast_nullable_to_non_nullable
as bool,helperMemberId: freezed == helperMemberId ? _self.helperMemberId : helperMemberId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

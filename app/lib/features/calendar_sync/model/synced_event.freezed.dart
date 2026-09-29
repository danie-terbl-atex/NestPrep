// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'synced_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SyncedEvent {

@JsonKey(includeToJson: false) String get id; String get connectionId;@JsonKey(unknownEnumValue: CalendarProvider.ics) CalendarProvider get provider;/// Whose calendar it came from.
 String get memberId;/// The connection's account label: the host of a calendar link, which is
/// what tells an iCloud calendar's badge to say Apple.
 String get sourceLabel;/// Empty when the provider had none; the row says "Busy" instead.
 String get title;@CalendarDateConverter() CalendarDate get date;/// The last day it covers, inclusive — a half-term holiday spans days.
@CalendarDateConverter() CalendarDate get endDate; int? get startMinute; int? get endMinute;
/// Create a copy of SyncedEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncedEventCopyWith<SyncedEvent> get copyWith => _$SyncedEventCopyWithImpl<SyncedEvent>(this as SyncedEvent, _$identity);

  /// Serializes this SyncedEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SyncedEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncedEvent&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.connectionId, _this.connectionId) || other.connectionId == _this.connectionId)&&(identical(other.provider, _this.provider) || other.provider == _this.provider)&&(identical(other.memberId, _this.memberId) || other.memberId == _this.memberId)&&(identical(other.sourceLabel, _this.sourceLabel) || other.sourceLabel == _this.sourceLabel)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.endDate, _this.endDate) || other.endDate == _this.endDate)&&(identical(other.startMinute, _this.startMinute) || other.startMinute == _this.startMinute)&&(identical(other.endMinute, _this.endMinute) || other.endMinute == _this.endMinute));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SyncedEvent;
  return Object.hash(runtimeType,_this.id,_this.connectionId,_this.provider,_this.memberId,_this.sourceLabel,_this.title,_this.date,_this.endDate,_this.startMinute,_this.endMinute);
}

@override
String toString() {
  final _this = this as SyncedEvent;
  return 'SyncedEvent(id: ${_this.id}, connectionId: ${_this.connectionId}, provider: ${_this.provider}, memberId: ${_this.memberId}, sourceLabel: ${_this.sourceLabel}, title: ${_this.title}, date: ${_this.date}, endDate: ${_this.endDate}, startMinute: ${_this.startMinute}, endMinute: ${_this.endMinute})';
}


}

/// @nodoc
abstract mixin class $SyncedEventCopyWith<$Res>  {
  factory $SyncedEventCopyWith(SyncedEvent value, $Res Function(SyncedEvent) _then) = _$SyncedEventCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String connectionId,@JsonKey(unknownEnumValue: CalendarProvider.ics) CalendarProvider provider, String memberId, String sourceLabel, String title,@CalendarDateConverter() CalendarDate date,@CalendarDateConverter() CalendarDate endDate, int? startMinute, int? endMinute
});




}
/// @nodoc
class _$SyncedEventCopyWithImpl<$Res>
    implements $SyncedEventCopyWith<$Res> {
  _$SyncedEventCopyWithImpl(this._self, this._then);

  final SyncedEvent _self;
  final $Res Function(SyncedEvent) _then;

/// Create a copy of SyncedEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? connectionId = null,Object? provider = null,Object? memberId = null,Object? sourceLabel = null,Object? title = null,Object? date = null,Object? endDate = null,Object? startMinute = freezed,Object? endMinute = freezed,}) {
  return _then(SyncedEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,connectionId: null == connectionId ? _self.connectionId : connectionId // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as CalendarProvider,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,sourceLabel: null == sourceLabel ? _self.sourceLabel : sourceLabel // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as CalendarDate,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as CalendarDate,startMinute: freezed == startMinute ? _self.startMinute : startMinute // ignore: cast_nullable_to_non_nullable
as int?,endMinute: freezed == endMinute ? _self.endMinute : endMinute // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncedEvent].
extension SyncedEventPatterns on SyncedEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncedEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncedEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncedEvent value)  $default,){
final _that = this;
switch (_that) {
case _SyncedEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncedEvent value)?  $default,){
final _that = this;
switch (_that) {
case _SyncedEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String connectionId, @JsonKey(unknownEnumValue: CalendarProvider.ics)  CalendarProvider provider,  String memberId,  String sourceLabel,  String title, @CalendarDateConverter()  CalendarDate date, @CalendarDateConverter()  CalendarDate endDate,  int? startMinute,  int? endMinute)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncedEvent() when $default != null:
return $default(_that.id,_that.connectionId,_that.provider,_that.memberId,_that.sourceLabel,_that.title,_that.date,_that.endDate,_that.startMinute,_that.endMinute);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String connectionId, @JsonKey(unknownEnumValue: CalendarProvider.ics)  CalendarProvider provider,  String memberId,  String sourceLabel,  String title, @CalendarDateConverter()  CalendarDate date, @CalendarDateConverter()  CalendarDate endDate,  int? startMinute,  int? endMinute)  $default,) {final _that = this;
switch (_that) {
case _SyncedEvent():
return $default(_that.id,_that.connectionId,_that.provider,_that.memberId,_that.sourceLabel,_that.title,_that.date,_that.endDate,_that.startMinute,_that.endMinute);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String connectionId, @JsonKey(unknownEnumValue: CalendarProvider.ics)  CalendarProvider provider,  String memberId,  String sourceLabel,  String title, @CalendarDateConverter()  CalendarDate date, @CalendarDateConverter()  CalendarDate endDate,  int? startMinute,  int? endMinute)?  $default,) {final _that = this;
switch (_that) {
case _SyncedEvent() when $default != null:
return $default(_that.id,_that.connectionId,_that.provider,_that.memberId,_that.sourceLabel,_that.title,_that.date,_that.endDate,_that.startMinute,_that.endMinute);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SyncedEvent extends SyncedEvent {
  const _SyncedEvent({@JsonKey(includeToJson: false) required this.id, required this.connectionId, @JsonKey(unknownEnumValue: CalendarProvider.ics) required this.provider, required this.memberId, this.sourceLabel = '', this.title = '', @CalendarDateConverter() required this.date, @CalendarDateConverter() required this.endDate, this.startMinute, this.endMinute}): super._();
  factory _SyncedEvent.fromJson(Map<String, dynamic> json) => _$SyncedEventFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String connectionId;
@override@JsonKey(unknownEnumValue: CalendarProvider.ics) final  CalendarProvider provider;
/// Whose calendar it came from.
@override final  String memberId;
/// The connection's account label: the host of a calendar link, which is
/// what tells an iCloud calendar's badge to say Apple.
@override@JsonKey() final  String sourceLabel;
/// Empty when the provider had none; the row says "Busy" instead.
@override@JsonKey() final  String title;
@override@CalendarDateConverter() final  CalendarDate date;
/// The last day it covers, inclusive — a half-term holiday spans days.
@override@CalendarDateConverter() final  CalendarDate endDate;
@override final  int? startMinute;
@override final  int? endMinute;

/// Create a copy of SyncedEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncedEventCopyWith<_SyncedEvent> get copyWith => __$SyncedEventCopyWithImpl<_SyncedEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SyncedEventToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncedEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.connectionId, connectionId) || other.connectionId == connectionId)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.sourceLabel, sourceLabel) || other.sourceLabel == sourceLabel)&&(identical(other.title, title) || other.title == title)&&(identical(other.date, date) || other.date == date)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.startMinute, startMinute) || other.startMinute == startMinute)&&(identical(other.endMinute, endMinute) || other.endMinute == endMinute));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,connectionId,provider,memberId,sourceLabel,title,date,endDate,startMinute,endMinute);
}

@override
String toString() {
    return 'SyncedEvent(id: $id, connectionId: $connectionId, provider: $provider, memberId: $memberId, sourceLabel: $sourceLabel, title: $title, date: $date, endDate: $endDate, startMinute: $startMinute, endMinute: $endMinute)';
}


}

/// @nodoc
abstract mixin class _$SyncedEventCopyWith<$Res> implements $SyncedEventCopyWith<$Res> {
  factory _$SyncedEventCopyWith(_SyncedEvent value, $Res Function(_SyncedEvent) _then) = __$SyncedEventCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String connectionId,@JsonKey(unknownEnumValue: CalendarProvider.ics) CalendarProvider provider, String memberId, String sourceLabel, String title,@CalendarDateConverter() CalendarDate date,@CalendarDateConverter() CalendarDate endDate, int? startMinute, int? endMinute
});




}
/// @nodoc
class __$SyncedEventCopyWithImpl<$Res>
    implements _$SyncedEventCopyWith<$Res> {
  __$SyncedEventCopyWithImpl(this._self, this._then);

  final _SyncedEvent _self;
  final $Res Function(_SyncedEvent) _then;

/// Create a copy of SyncedEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? connectionId = null,Object? provider = null,Object? memberId = null,Object? sourceLabel = null,Object? title = null,Object? date = null,Object? endDate = null,Object? startMinute = freezed,Object? endMinute = freezed,}) {
  return _then(_SyncedEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,connectionId: null == connectionId ? _self.connectionId : connectionId // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as CalendarProvider,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,sourceLabel: null == sourceLabel ? _self.sourceLabel : sourceLabel // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as CalendarDate,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as CalendarDate,startMinute: freezed == startMinute ? _self.startMinute : startMinute // ignore: cast_nullable_to_non_nullable
as int?,endMinute: freezed == endMinute ? _self.endMinute : endMinute // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on

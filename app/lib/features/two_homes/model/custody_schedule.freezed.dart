// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'custody_schedule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CustodyBlock {

 CustodySide get side; int get weekOffset; List<int> get weekdays;
/// Create a copy of CustodyBlock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustodyBlockCopyWith<CustodyBlock> get copyWith => _$CustodyBlockCopyWithImpl<CustodyBlock>(this as CustodyBlock, _$identity);

  /// Serializes this CustodyBlock to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CustodyBlock;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustodyBlock&&(identical(other.side, _this.side) || other.side == _this.side)&&(identical(other.weekOffset, _this.weekOffset) || other.weekOffset == _this.weekOffset)&&const DeepCollectionEquality().equals(other.weekdays, _this.weekdays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CustodyBlock;
  return Object.hash(runtimeType,_this.side,_this.weekOffset,const DeepCollectionEquality().hash(_this.weekdays));
}

@override
String toString() {
  final _this = this as CustodyBlock;
  return 'CustodyBlock(side: ${_this.side}, weekOffset: ${_this.weekOffset}, weekdays: ${_this.weekdays})';
}


}

/// @nodoc
abstract mixin class $CustodyBlockCopyWith<$Res>  {
  factory $CustodyBlockCopyWith(CustodyBlock value, $Res Function(CustodyBlock) _then) = _$CustodyBlockCopyWithImpl;
@useResult
$Res call({
 CustodySide side, int weekOffset, List<int> weekdays
});




}
/// @nodoc
class _$CustodyBlockCopyWithImpl<$Res>
    implements $CustodyBlockCopyWith<$Res> {
  _$CustodyBlockCopyWithImpl(this._self, this._then);

  final CustodyBlock _self;
  final $Res Function(CustodyBlock) _then;

/// Create a copy of CustodyBlock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? side = null,Object? weekOffset = null,Object? weekdays = null,}) {
  return _then(CustodyBlock(
side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as CustodySide,weekOffset: null == weekOffset ? _self.weekOffset : weekOffset // ignore: cast_nullable_to_non_nullable
as int,weekdays: null == weekdays ? _self.weekdays : weekdays // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}

}


/// Adds pattern-matching-related methods to [CustodyBlock].
extension CustodyBlockPatterns on CustodyBlock {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustodyBlock value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustodyBlock() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustodyBlock value)  $default,){
final _that = this;
switch (_that) {
case _CustodyBlock():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustodyBlock value)?  $default,){
final _that = this;
switch (_that) {
case _CustodyBlock() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CustodySide side,  int weekOffset,  List<int> weekdays)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustodyBlock() when $default != null:
return $default(_that.side,_that.weekOffset,_that.weekdays);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CustodySide side,  int weekOffset,  List<int> weekdays)  $default,) {final _that = this;
switch (_that) {
case _CustodyBlock():
return $default(_that.side,_that.weekOffset,_that.weekdays);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CustodySide side,  int weekOffset,  List<int> weekdays)?  $default,) {final _that = this;
switch (_that) {
case _CustodyBlock() when $default != null:
return $default(_that.side,_that.weekOffset,_that.weekdays);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CustodyBlock implements CustodyBlock {
  const _CustodyBlock({required this.side, required this.weekOffset, required  List<int> weekdays}): _weekdays = weekdays;
  factory _CustodyBlock.fromJson(Map<String, dynamic> json) => _$CustodyBlockFromJson(json);

@override final  CustodySide side;
@override final  int weekOffset;
 final  List<int> _weekdays;
@override List<int> get weekdays {
  if (_weekdays is EqualUnmodifiableListView) return _weekdays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_weekdays);
}


/// Create a copy of CustodyBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustodyBlockCopyWith<_CustodyBlock> get copyWith => __$CustodyBlockCopyWithImpl<_CustodyBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CustodyBlockToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustodyBlock&&(identical(other.side, side) || other.side == side)&&(identical(other.weekOffset, weekOffset) || other.weekOffset == weekOffset)&&const DeepCollectionEquality().equals(other.weekdays, _weekdays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,side,weekOffset,const DeepCollectionEquality().hash(_weekdays));
}

@override
String toString() {
    return 'CustodyBlock(side: $side, weekOffset: $weekOffset, weekdays: $weekdays)';
}


}

/// @nodoc
abstract mixin class _$CustodyBlockCopyWith<$Res> implements $CustodyBlockCopyWith<$Res> {
  factory _$CustodyBlockCopyWith(_CustodyBlock value, $Res Function(_CustodyBlock) _then) = __$CustodyBlockCopyWithImpl;
@override @useResult
$Res call({
 CustodySide side, int weekOffset, List<int> weekdays
});




}
/// @nodoc
class __$CustodyBlockCopyWithImpl<$Res>
    implements _$CustodyBlockCopyWith<$Res> {
  __$CustodyBlockCopyWithImpl(this._self, this._then);

  final _CustodyBlock _self;
  final $Res Function(_CustodyBlock) _then;

/// Create a copy of CustodyBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? side = null,Object? weekOffset = null,Object? weekdays = null,}) {
  return _then(_CustodyBlock(
side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as CustodySide,weekOffset: null == weekOffset ? _self.weekOffset : weekOffset // ignore: cast_nullable_to_non_nullable
as int,weekdays: null == weekdays ? _self._weekdays : weekdays // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}


/// @nodoc
mixin _$CustodySchedule {

@JsonKey(unknownEnumValue: CustodyPattern.custom) CustodyPattern get pattern;/// The Monday the cycle's first week starts on.
@CalendarDateConverter() CalendarDate get startsOn; int get cycleWeeks; List<CustodyBlock> get blocks;/// When the child changes homes, in minutes after midnight in the
/// household's own time. Null is "some time that day".
 int? get handoverMinute;
/// Create a copy of CustodySchedule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustodyScheduleCopyWith<CustodySchedule> get copyWith => _$CustodyScheduleCopyWithImpl<CustodySchedule>(this as CustodySchedule, _$identity);

  /// Serializes this CustodySchedule to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CustodySchedule;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustodySchedule&&(identical(other.pattern, _this.pattern) || other.pattern == _this.pattern)&&(identical(other.startsOn, _this.startsOn) || other.startsOn == _this.startsOn)&&(identical(other.cycleWeeks, _this.cycleWeeks) || other.cycleWeeks == _this.cycleWeeks)&&const DeepCollectionEquality().equals(other.blocks, _this.blocks)&&(identical(other.handoverMinute, _this.handoverMinute) || other.handoverMinute == _this.handoverMinute));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CustodySchedule;
  return Object.hash(runtimeType,_this.pattern,_this.startsOn,_this.cycleWeeks,const DeepCollectionEquality().hash(_this.blocks),_this.handoverMinute);
}

@override
String toString() {
  final _this = this as CustodySchedule;
  return 'CustodySchedule(pattern: ${_this.pattern}, startsOn: ${_this.startsOn}, cycleWeeks: ${_this.cycleWeeks}, blocks: ${_this.blocks}, handoverMinute: ${_this.handoverMinute})';
}


}

/// @nodoc
abstract mixin class $CustodyScheduleCopyWith<$Res>  {
  factory $CustodyScheduleCopyWith(CustodySchedule value, $Res Function(CustodySchedule) _then) = _$CustodyScheduleCopyWithImpl;
@useResult
$Res call({
@JsonKey(unknownEnumValue: CustodyPattern.custom) CustodyPattern pattern,@CalendarDateConverter() CalendarDate startsOn, int cycleWeeks, List<CustodyBlock> blocks, int? handoverMinute
});




}
/// @nodoc
class _$CustodyScheduleCopyWithImpl<$Res>
    implements $CustodyScheduleCopyWith<$Res> {
  _$CustodyScheduleCopyWithImpl(this._self, this._then);

  final CustodySchedule _self;
  final $Res Function(CustodySchedule) _then;

/// Create a copy of CustodySchedule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pattern = null,Object? startsOn = null,Object? cycleWeeks = null,Object? blocks = null,Object? handoverMinute = freezed,}) {
  return _then(CustodySchedule(
pattern: null == pattern ? _self.pattern : pattern // ignore: cast_nullable_to_non_nullable
as CustodyPattern,startsOn: null == startsOn ? _self.startsOn : startsOn // ignore: cast_nullable_to_non_nullable
as CalendarDate,cycleWeeks: null == cycleWeeks ? _self.cycleWeeks : cycleWeeks // ignore: cast_nullable_to_non_nullable
as int,blocks: null == blocks ? _self.blocks : blocks // ignore: cast_nullable_to_non_nullable
as List<CustodyBlock>,handoverMinute: freezed == handoverMinute ? _self.handoverMinute : handoverMinute // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [CustodySchedule].
extension CustodySchedulePatterns on CustodySchedule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustodySchedule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustodySchedule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustodySchedule value)  $default,){
final _that = this;
switch (_that) {
case _CustodySchedule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustodySchedule value)?  $default,){
final _that = this;
switch (_that) {
case _CustodySchedule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: CustodyPattern.custom)  CustodyPattern pattern, @CalendarDateConverter()  CalendarDate startsOn,  int cycleWeeks,  List<CustodyBlock> blocks,  int? handoverMinute)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustodySchedule() when $default != null:
return $default(_that.pattern,_that.startsOn,_that.cycleWeeks,_that.blocks,_that.handoverMinute);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: CustodyPattern.custom)  CustodyPattern pattern, @CalendarDateConverter()  CalendarDate startsOn,  int cycleWeeks,  List<CustodyBlock> blocks,  int? handoverMinute)  $default,) {final _that = this;
switch (_that) {
case _CustodySchedule():
return $default(_that.pattern,_that.startsOn,_that.cycleWeeks,_that.blocks,_that.handoverMinute);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(unknownEnumValue: CustodyPattern.custom)  CustodyPattern pattern, @CalendarDateConverter()  CalendarDate startsOn,  int cycleWeeks,  List<CustodyBlock> blocks,  int? handoverMinute)?  $default,) {final _that = this;
switch (_that) {
case _CustodySchedule() when $default != null:
return $default(_that.pattern,_that.startsOn,_that.cycleWeeks,_that.blocks,_that.handoverMinute);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CustodySchedule extends CustodySchedule {
  const _CustodySchedule({@JsonKey(unknownEnumValue: CustodyPattern.custom) required this.pattern, @CalendarDateConverter() required this.startsOn, required this.cycleWeeks, required  List<CustodyBlock> blocks, this.handoverMinute}): _blocks = blocks,super._();
  factory _CustodySchedule.fromJson(Map<String, dynamic> json) => _$CustodyScheduleFromJson(json);

@override@JsonKey(unknownEnumValue: CustodyPattern.custom) final  CustodyPattern pattern;
/// The Monday the cycle's first week starts on.
@override@CalendarDateConverter() final  CalendarDate startsOn;
@override final  int cycleWeeks;
 final  List<CustodyBlock> _blocks;
@override List<CustodyBlock> get blocks {
  if (_blocks is EqualUnmodifiableListView) return _blocks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_blocks);
}

/// When the child changes homes, in minutes after midnight in the
/// household's own time. Null is "some time that day".
@override final  int? handoverMinute;

/// Create a copy of CustodySchedule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustodyScheduleCopyWith<_CustodySchedule> get copyWith => __$CustodyScheduleCopyWithImpl<_CustodySchedule>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CustodyScheduleToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustodySchedule&&(identical(other.pattern, pattern) || other.pattern == pattern)&&(identical(other.startsOn, startsOn) || other.startsOn == startsOn)&&(identical(other.cycleWeeks, cycleWeeks) || other.cycleWeeks == cycleWeeks)&&const DeepCollectionEquality().equals(other.blocks, _blocks)&&(identical(other.handoverMinute, handoverMinute) || other.handoverMinute == handoverMinute));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,pattern,startsOn,cycleWeeks,const DeepCollectionEquality().hash(_blocks),handoverMinute);
}

@override
String toString() {
    return 'CustodySchedule(pattern: $pattern, startsOn: $startsOn, cycleWeeks: $cycleWeeks, blocks: $blocks, handoverMinute: $handoverMinute)';
}


}

/// @nodoc
abstract mixin class _$CustodyScheduleCopyWith<$Res> implements $CustodyScheduleCopyWith<$Res> {
  factory _$CustodyScheduleCopyWith(_CustodySchedule value, $Res Function(_CustodySchedule) _then) = __$CustodyScheduleCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(unknownEnumValue: CustodyPattern.custom) CustodyPattern pattern,@CalendarDateConverter() CalendarDate startsOn, int cycleWeeks, List<CustodyBlock> blocks, int? handoverMinute
});




}
/// @nodoc
class __$CustodyScheduleCopyWithImpl<$Res>
    implements _$CustodyScheduleCopyWith<$Res> {
  __$CustodyScheduleCopyWithImpl(this._self, this._then);

  final _CustodySchedule _self;
  final $Res Function(_CustodySchedule) _then;

/// Create a copy of CustodySchedule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pattern = null,Object? startsOn = null,Object? cycleWeeks = null,Object? blocks = null,Object? handoverMinute = freezed,}) {
  return _then(_CustodySchedule(
pattern: null == pattern ? _self.pattern : pattern // ignore: cast_nullable_to_non_nullable
as CustodyPattern,startsOn: null == startsOn ? _self.startsOn : startsOn // ignore: cast_nullable_to_non_nullable
as CalendarDate,cycleWeeks: null == cycleWeeks ? _self.cycleWeeks : cycleWeeks // ignore: cast_nullable_to_non_nullable
as int,blocks: null == blocks ? _self._blocks : blocks // ignore: cast_nullable_to_non_nullable
as List<CustodyBlock>,handoverMinute: freezed == handoverMinute ? _self.handoverMinute : handoverMinute // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lunch_budget.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LunchBudget {

@JsonKey(includeToJson: false) String get id; int get cents; String get currency; String get updatedBy;@ServerTimestampConverter() DateTime? get updatedAt;
/// Create a copy of LunchBudget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LunchBudgetCopyWith<LunchBudget> get copyWith => _$LunchBudgetCopyWithImpl<LunchBudget>(this as LunchBudget, _$identity);

  /// Serializes this LunchBudget to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LunchBudget;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LunchBudget&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.cents, _this.cents) || other.cents == _this.cents)&&(identical(other.currency, _this.currency) || other.currency == _this.currency)&&(identical(other.updatedBy, _this.updatedBy) || other.updatedBy == _this.updatedBy)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LunchBudget;
  return Object.hash(runtimeType,_this.id,_this.cents,_this.currency,_this.updatedBy,_this.updatedAt);
}

@override
String toString() {
  final _this = this as LunchBudget;
  return 'LunchBudget(id: ${_this.id}, cents: ${_this.cents}, currency: ${_this.currency}, updatedBy: ${_this.updatedBy}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $LunchBudgetCopyWith<$Res>  {
  factory $LunchBudgetCopyWith(LunchBudget value, $Res Function(LunchBudget) _then) = _$LunchBudgetCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, int cents, String currency, String updatedBy,@ServerTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$LunchBudgetCopyWithImpl<$Res>
    implements $LunchBudgetCopyWith<$Res> {
  _$LunchBudgetCopyWithImpl(this._self, this._then);

  final LunchBudget _self;
  final $Res Function(LunchBudget) _then;

/// Create a copy of LunchBudget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? cents = null,Object? currency = null,Object? updatedBy = null,Object? updatedAt = freezed,}) {
  return _then(LunchBudget(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,cents: null == cents ? _self.cents : cents // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [LunchBudget].
extension LunchBudgetPatterns on LunchBudget {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LunchBudget value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LunchBudget() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LunchBudget value)  $default,){
final _that = this;
switch (_that) {
case _LunchBudget():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LunchBudget value)?  $default,){
final _that = this;
switch (_that) {
case _LunchBudget() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  int cents,  String currency,  String updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LunchBudget() when $default != null:
return $default(_that.id,_that.cents,_that.currency,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  int cents,  String currency,  String updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _LunchBudget():
return $default(_that.id,_that.cents,_that.currency,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  int cents,  String currency,  String updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _LunchBudget() when $default != null:
return $default(_that.id,_that.cents,_that.currency,_that.updatedBy,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LunchBudget extends LunchBudget {
  const _LunchBudget({@JsonKey(includeToJson: false) required this.id, required this.cents, this.currency = 'ZAR', required this.updatedBy, @ServerTimestampConverter() this.updatedAt}): super._();
  factory _LunchBudget.fromJson(Map<String, dynamic> json) => _$LunchBudgetFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  int cents;
@override@JsonKey() final  String currency;
@override final  String updatedBy;
@override@ServerTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of LunchBudget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LunchBudgetCopyWith<_LunchBudget> get copyWith => __$LunchBudgetCopyWithImpl<_LunchBudget>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LunchBudgetToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LunchBudget&&(identical(other.id, id) || other.id == id)&&(identical(other.cents, cents) || other.cents == cents)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,cents,currency,updatedBy,updatedAt);
}

@override
String toString() {
    return 'LunchBudget(id: $id, cents: $cents, currency: $currency, updatedBy: $updatedBy, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$LunchBudgetCopyWith<$Res> implements $LunchBudgetCopyWith<$Res> {
  factory _$LunchBudgetCopyWith(_LunchBudget value, $Res Function(_LunchBudget) _then) = __$LunchBudgetCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, int cents, String currency, String updatedBy,@ServerTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$LunchBudgetCopyWithImpl<$Res>
    implements _$LunchBudgetCopyWith<$Res> {
  __$LunchBudgetCopyWithImpl(this._self, this._then);

  final _LunchBudget _self;
  final $Res Function(_LunchBudget) _then;

/// Create a copy of LunchBudget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? cents = null,Object? currency = null,Object? updatedBy = null,Object? updatedAt = freezed,}) {
  return _then(_LunchBudget(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,cents: null == cents ? _self.cents : cents // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

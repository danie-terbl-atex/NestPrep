// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DigestChoice {

 bool get enabled; int get minute;
/// Create a copy of DigestChoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DigestChoiceCopyWith<DigestChoice> get copyWith => _$DigestChoiceCopyWithImpl<DigestChoice>(this as DigestChoice, _$identity);

  /// Serializes this DigestChoice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DigestChoice;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DigestChoice&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.minute, _this.minute) || other.minute == _this.minute));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DigestChoice;
  return Object.hash(runtimeType,_this.enabled,_this.minute);
}

@override
String toString() {
  final _this = this as DigestChoice;
  return 'DigestChoice(enabled: ${_this.enabled}, minute: ${_this.minute})';
}


}

/// @nodoc
abstract mixin class $DigestChoiceCopyWith<$Res>  {
  factory $DigestChoiceCopyWith(DigestChoice value, $Res Function(DigestChoice) _then) = _$DigestChoiceCopyWithImpl;
@useResult
$Res call({
 bool enabled, int minute
});




}
/// @nodoc
class _$DigestChoiceCopyWithImpl<$Res>
    implements $DigestChoiceCopyWith<$Res> {
  _$DigestChoiceCopyWithImpl(this._self, this._then);

  final DigestChoice _self;
  final $Res Function(DigestChoice) _then;

/// Create a copy of DigestChoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? minute = null,}) {
  return _then(DigestChoice(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,minute: null == minute ? _self.minute : minute // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DigestChoice].
extension DigestChoicePatterns on DigestChoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DigestChoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DigestChoice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DigestChoice value)  $default,){
final _that = this;
switch (_that) {
case _DigestChoice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DigestChoice value)?  $default,){
final _that = this;
switch (_that) {
case _DigestChoice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled,  int minute)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DigestChoice() when $default != null:
return $default(_that.enabled,_that.minute);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled,  int minute)  $default,) {final _that = this;
switch (_that) {
case _DigestChoice():
return $default(_that.enabled,_that.minute);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled,  int minute)?  $default,) {final _that = this;
switch (_that) {
case _DigestChoice() when $default != null:
return $default(_that.enabled,_that.minute);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DigestChoice implements DigestChoice {
  const _DigestChoice({this.enabled = false, this.minute = DigestTimes.defaultMinute});
  factory _DigestChoice.fromJson(Map<String, dynamic> json) => _$DigestChoiceFromJson(json);

@override@JsonKey() final  bool enabled;
@override@JsonKey() final  int minute;

/// Create a copy of DigestChoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DigestChoiceCopyWith<_DigestChoice> get copyWith => __$DigestChoiceCopyWithImpl<_DigestChoice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DigestChoiceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DigestChoice&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.minute, minute) || other.minute == minute));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,enabled,minute);
}

@override
String toString() {
    return 'DigestChoice(enabled: $enabled, minute: $minute)';
}


}

/// @nodoc
abstract mixin class _$DigestChoiceCopyWith<$Res> implements $DigestChoiceCopyWith<$Res> {
  factory _$DigestChoiceCopyWith(_DigestChoice value, $Res Function(_DigestChoice) _then) = __$DigestChoiceCopyWithImpl;
@override @useResult
$Res call({
 bool enabled, int minute
});




}
/// @nodoc
class __$DigestChoiceCopyWithImpl<$Res>
    implements _$DigestChoiceCopyWith<$Res> {
  __$DigestChoiceCopyWithImpl(this._self, this._then);

  final _DigestChoice _self;
  final $Res Function(_DigestChoice) _then;

/// Create a copy of DigestChoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? minute = null,}) {
  return _then(_DigestChoice(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,minute: null == minute ? _self.minute : minute // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$QuietHours {

 bool get enabled; int get startMinute; int get endMinute;
/// Create a copy of QuietHours
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuietHoursCopyWith<QuietHours> get copyWith => _$QuietHoursCopyWithImpl<QuietHours>(this as QuietHours, _$identity);

  /// Serializes this QuietHours to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as QuietHours;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuietHours&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.startMinute, _this.startMinute) || other.startMinute == _this.startMinute)&&(identical(other.endMinute, _this.endMinute) || other.endMinute == _this.endMinute));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as QuietHours;
  return Object.hash(runtimeType,_this.enabled,_this.startMinute,_this.endMinute);
}

@override
String toString() {
  final _this = this as QuietHours;
  return 'QuietHours(enabled: ${_this.enabled}, startMinute: ${_this.startMinute}, endMinute: ${_this.endMinute})';
}


}

/// @nodoc
abstract mixin class $QuietHoursCopyWith<$Res>  {
  factory $QuietHoursCopyWith(QuietHours value, $Res Function(QuietHours) _then) = _$QuietHoursCopyWithImpl;
@useResult
$Res call({
 bool enabled, int startMinute, int endMinute
});




}
/// @nodoc
class _$QuietHoursCopyWithImpl<$Res>
    implements $QuietHoursCopyWith<$Res> {
  _$QuietHoursCopyWithImpl(this._self, this._then);

  final QuietHours _self;
  final $Res Function(QuietHours) _then;

/// Create a copy of QuietHours
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? startMinute = null,Object? endMinute = null,}) {
  return _then(QuietHours(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,startMinute: null == startMinute ? _self.startMinute : startMinute // ignore: cast_nullable_to_non_nullable
as int,endMinute: null == endMinute ? _self.endMinute : endMinute // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [QuietHours].
extension QuietHoursPatterns on QuietHours {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuietHours value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuietHours() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuietHours value)  $default,){
final _that = this;
switch (_that) {
case _QuietHours():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuietHours value)?  $default,){
final _that = this;
switch (_that) {
case _QuietHours() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled,  int startMinute,  int endMinute)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuietHours() when $default != null:
return $default(_that.enabled,_that.startMinute,_that.endMinute);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled,  int startMinute,  int endMinute)  $default,) {final _that = this;
switch (_that) {
case _QuietHours():
return $default(_that.enabled,_that.startMinute,_that.endMinute);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled,  int startMinute,  int endMinute)?  $default,) {final _that = this;
switch (_that) {
case _QuietHours() when $default != null:
return $default(_that.enabled,_that.startMinute,_that.endMinute);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuietHours implements QuietHours {
  const _QuietHours({this.enabled = true, this.startMinute = DigestTimes.quietStart, this.endMinute = DigestTimes.quietEnd});
  factory _QuietHours.fromJson(Map<String, dynamic> json) => _$QuietHoursFromJson(json);

@override@JsonKey() final  bool enabled;
@override@JsonKey() final  int startMinute;
@override@JsonKey() final  int endMinute;

/// Create a copy of QuietHours
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuietHoursCopyWith<_QuietHours> get copyWith => __$QuietHoursCopyWithImpl<_QuietHours>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuietHoursToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuietHours&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.startMinute, startMinute) || other.startMinute == startMinute)&&(identical(other.endMinute, endMinute) || other.endMinute == endMinute));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,enabled,startMinute,endMinute);
}

@override
String toString() {
    return 'QuietHours(enabled: $enabled, startMinute: $startMinute, endMinute: $endMinute)';
}


}

/// @nodoc
abstract mixin class _$QuietHoursCopyWith<$Res> implements $QuietHoursCopyWith<$Res> {
  factory _$QuietHoursCopyWith(_QuietHours value, $Res Function(_QuietHours) _then) = __$QuietHoursCopyWithImpl;
@override @useResult
$Res call({
 bool enabled, int startMinute, int endMinute
});




}
/// @nodoc
class __$QuietHoursCopyWithImpl<$Res>
    implements _$QuietHoursCopyWith<$Res> {
  __$QuietHoursCopyWithImpl(this._self, this._then);

  final _QuietHours _self;
  final $Res Function(_QuietHours) _then;

/// Create a copy of QuietHours
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? startMinute = null,Object? endMinute = null,}) {
  return _then(_QuietHours(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,startMinute: null == startMinute ? _self.startMinute : startMinute // ignore: cast_nullable_to_non_nullable
as int,endMinute: null == endMinute ? _self.endMinute : endMinute // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$NotificationSettings {

/// The member these are for — the document id.
@JsonKey(includeToJson: false) String get id; DigestChoice get digest; Map<String, bool> get categories; QuietHours get quietHours; String get updatedBy;@ServerTimestampConverter() DateTime? get updatedAt;
/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationSettingsCopyWith<NotificationSettings> get copyWith => _$NotificationSettingsCopyWithImpl<NotificationSettings>(this as NotificationSettings, _$identity);

  /// Serializes this NotificationSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NotificationSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationSettings&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.digest, _this.digest) || other.digest == _this.digest)&&const DeepCollectionEquality().equals(other.categories, _this.categories)&&(identical(other.quietHours, _this.quietHours) || other.quietHours == _this.quietHours)&&(identical(other.updatedBy, _this.updatedBy) || other.updatedBy == _this.updatedBy)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NotificationSettings;
  return Object.hash(runtimeType,_this.id,_this.digest,const DeepCollectionEquality().hash(_this.categories),_this.quietHours,_this.updatedBy,_this.updatedAt);
}

@override
String toString() {
  final _this = this as NotificationSettings;
  return 'NotificationSettings(id: ${_this.id}, digest: ${_this.digest}, categories: ${_this.categories}, quietHours: ${_this.quietHours}, updatedBy: ${_this.updatedBy}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $NotificationSettingsCopyWith<$Res>  {
  factory $NotificationSettingsCopyWith(NotificationSettings value, $Res Function(NotificationSettings) _then) = _$NotificationSettingsCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, DigestChoice digest, Map<String, bool> categories, QuietHours quietHours, String updatedBy,@ServerTimestampConverter() DateTime? updatedAt
});


$DigestChoiceCopyWith<$Res> get digest;$QuietHoursCopyWith<$Res> get quietHours;

}
/// @nodoc
class _$NotificationSettingsCopyWithImpl<$Res>
    implements $NotificationSettingsCopyWith<$Res> {
  _$NotificationSettingsCopyWithImpl(this._self, this._then);

  final NotificationSettings _self;
  final $Res Function(NotificationSettings) _then;

/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? digest = null,Object? categories = null,Object? quietHours = null,Object? updatedBy = null,Object? updatedAt = freezed,}) {
  return _then(NotificationSettings(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,digest: null == digest ? _self.digest : digest // ignore: cast_nullable_to_non_nullable
as DigestChoice,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,quietHours: null == quietHours ? _self.quietHours : quietHours // ignore: cast_nullable_to_non_nullable
as QuietHours,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DigestChoiceCopyWith<$Res> get digest {
  
  return $DigestChoiceCopyWith<$Res>(_self.digest, (value) {
    return _then(_self.copyWith(digest: value));
  });
}/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuietHoursCopyWith<$Res> get quietHours {
  
  return $QuietHoursCopyWith<$Res>(_self.quietHours, (value) {
    return _then(_self.copyWith(quietHours: value));
  });
}
}


/// Adds pattern-matching-related methods to [NotificationSettings].
extension NotificationSettingsPatterns on NotificationSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationSettings value)  $default,){
final _that = this;
switch (_that) {
case _NotificationSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationSettings value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  DigestChoice digest,  Map<String, bool> categories,  QuietHours quietHours,  String updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationSettings() when $default != null:
return $default(_that.id,_that.digest,_that.categories,_that.quietHours,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  DigestChoice digest,  Map<String, bool> categories,  QuietHours quietHours,  String updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _NotificationSettings():
return $default(_that.id,_that.digest,_that.categories,_that.quietHours,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  DigestChoice digest,  Map<String, bool> categories,  QuietHours quietHours,  String updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _NotificationSettings() when $default != null:
return $default(_that.id,_that.digest,_that.categories,_that.quietHours,_that.updatedBy,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationSettings extends NotificationSettings {
  const _NotificationSettings({@JsonKey(includeToJson: false) required this.id, this.digest = const DigestChoice(),  Map<String, bool> categories = const <String, bool>{}, this.quietHours = const QuietHours(), required this.updatedBy, @ServerTimestampConverter() this.updatedAt}): _categories = categories,super._();
  factory _NotificationSettings.fromJson(Map<String, dynamic> json) => _$NotificationSettingsFromJson(json);

/// The member these are for — the document id.
@override@JsonKey(includeToJson: false) final  String id;
@override@JsonKey() final  DigestChoice digest;
 final  Map<String, bool> _categories;
@override@JsonKey() Map<String, bool> get categories {
  if (_categories is EqualUnmodifiableMapView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_categories);
}

@override@JsonKey() final  QuietHours quietHours;
@override final  String updatedBy;
@override@ServerTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationSettingsCopyWith<_NotificationSettings> get copyWith => __$NotificationSettingsCopyWithImpl<_NotificationSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationSettings&&(identical(other.id, id) || other.id == id)&&(identical(other.digest, digest) || other.digest == digest)&&const DeepCollectionEquality().equals(other.categories, _categories)&&(identical(other.quietHours, quietHours) || other.quietHours == quietHours)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,digest,const DeepCollectionEquality().hash(_categories),quietHours,updatedBy,updatedAt);
}

@override
String toString() {
    return 'NotificationSettings(id: $id, digest: $digest, categories: $categories, quietHours: $quietHours, updatedBy: $updatedBy, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$NotificationSettingsCopyWith<$Res> implements $NotificationSettingsCopyWith<$Res> {
  factory _$NotificationSettingsCopyWith(_NotificationSettings value, $Res Function(_NotificationSettings) _then) = __$NotificationSettingsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, DigestChoice digest, Map<String, bool> categories, QuietHours quietHours, String updatedBy,@ServerTimestampConverter() DateTime? updatedAt
});


@override $DigestChoiceCopyWith<$Res> get digest;@override $QuietHoursCopyWith<$Res> get quietHours;

}
/// @nodoc
class __$NotificationSettingsCopyWithImpl<$Res>
    implements _$NotificationSettingsCopyWith<$Res> {
  __$NotificationSettingsCopyWithImpl(this._self, this._then);

  final _NotificationSettings _self;
  final $Res Function(_NotificationSettings) _then;

/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? digest = null,Object? categories = null,Object? quietHours = null,Object? updatedBy = null,Object? updatedAt = freezed,}) {
  return _then(_NotificationSettings(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,digest: null == digest ? _self.digest : digest // ignore: cast_nullable_to_non_nullable
as DigestChoice,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,quietHours: null == quietHours ? _self.quietHours : quietHours // ignore: cast_nullable_to_non_nullable
as QuietHours,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DigestChoiceCopyWith<$Res> get digest {
  
  return $DigestChoiceCopyWith<$Res>(_self.digest, (value) {
    return _then(_self.copyWith(digest: value));
  });
}/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuietHoursCopyWith<$Res> get quietHours {
  
  return $QuietHoursCopyWith<$Res>(_self.quietHours, (value) {
    return _then(_self.copyWith(quietHours: value));
  });
}
}

// dart format on

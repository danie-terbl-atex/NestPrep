// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'handover_note.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HandoverItem {

 String get text; bool get packed;
/// Create a copy of HandoverItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HandoverItemCopyWith<HandoverItem> get copyWith => _$HandoverItemCopyWithImpl<HandoverItem>(this as HandoverItem, _$identity);

  /// Serializes this HandoverItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HandoverItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HandoverItem&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.packed, _this.packed) || other.packed == _this.packed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HandoverItem;
  return Object.hash(runtimeType,_this.text,_this.packed);
}

@override
String toString() {
  final _this = this as HandoverItem;
  return 'HandoverItem(text: ${_this.text}, packed: ${_this.packed})';
}


}

/// @nodoc
abstract mixin class $HandoverItemCopyWith<$Res>  {
  factory $HandoverItemCopyWith(HandoverItem value, $Res Function(HandoverItem) _then) = _$HandoverItemCopyWithImpl;
@useResult
$Res call({
 String text, bool packed
});




}
/// @nodoc
class _$HandoverItemCopyWithImpl<$Res>
    implements $HandoverItemCopyWith<$Res> {
  _$HandoverItemCopyWithImpl(this._self, this._then);

  final HandoverItem _self;
  final $Res Function(HandoverItem) _then;

/// Create a copy of HandoverItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? packed = null,}) {
  return _then(HandoverItem(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,packed: null == packed ? _self.packed : packed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [HandoverItem].
extension HandoverItemPatterns on HandoverItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HandoverItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HandoverItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HandoverItem value)  $default,){
final _that = this;
switch (_that) {
case _HandoverItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HandoverItem value)?  $default,){
final _that = this;
switch (_that) {
case _HandoverItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  bool packed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HandoverItem() when $default != null:
return $default(_that.text,_that.packed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  bool packed)  $default,) {final _that = this;
switch (_that) {
case _HandoverItem():
return $default(_that.text,_that.packed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  bool packed)?  $default,) {final _that = this;
switch (_that) {
case _HandoverItem() when $default != null:
return $default(_that.text,_that.packed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HandoverItem implements HandoverItem {
  const _HandoverItem({required this.text, required this.packed});
  factory _HandoverItem.fromJson(Map<String, dynamic> json) => _$HandoverItemFromJson(json);

@override final  String text;
@override final  bool packed;

/// Create a copy of HandoverItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HandoverItemCopyWith<_HandoverItem> get copyWith => __$HandoverItemCopyWithImpl<_HandoverItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HandoverItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HandoverItem&&(identical(other.text, text) || other.text == text)&&(identical(other.packed, packed) || other.packed == packed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,text,packed);
}

@override
String toString() {
    return 'HandoverItem(text: $text, packed: $packed)';
}


}

/// @nodoc
abstract mixin class _$HandoverItemCopyWith<$Res> implements $HandoverItemCopyWith<$Res> {
  factory _$HandoverItemCopyWith(_HandoverItem value, $Res Function(_HandoverItem) _then) = __$HandoverItemCopyWithImpl;
@override @useResult
$Res call({
 String text, bool packed
});




}
/// @nodoc
class __$HandoverItemCopyWithImpl<$Res>
    implements _$HandoverItemCopyWith<$Res> {
  __$HandoverItemCopyWithImpl(this._self, this._then);

  final _HandoverItem _self;
  final $Res Function(_HandoverItem) _then;

/// Create a copy of HandoverItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? packed = null,}) {
  return _then(_HandoverItem(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,packed: null == packed ? _self.packed : packed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$HandoverNote {

@JsonKey(includeToJson: false) String get id;@CalendarDateConverter() CalendarDate get date; List<HandoverItem> get items; String? get medicine; String? get homework; String? get clothes; String? get note;@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) CustodySide? get updatedBySide;@ServerTimestampConverter() DateTime? get updatedAt;
/// Create a copy of HandoverNote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HandoverNoteCopyWith<HandoverNote> get copyWith => _$HandoverNoteCopyWithImpl<HandoverNote>(this as HandoverNote, _$identity);

  /// Serializes this HandoverNote to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HandoverNote;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HandoverNote&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.date, _this.date) || other.date == _this.date)&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.medicine, _this.medicine) || other.medicine == _this.medicine)&&(identical(other.homework, _this.homework) || other.homework == _this.homework)&&(identical(other.clothes, _this.clothes) || other.clothes == _this.clothes)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.updatedBySide, _this.updatedBySide) || other.updatedBySide == _this.updatedBySide)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HandoverNote;
  return Object.hash(runtimeType,_this.id,_this.date,const DeepCollectionEquality().hash(_this.items),_this.medicine,_this.homework,_this.clothes,_this.note,_this.updatedBySide,_this.updatedAt);
}

@override
String toString() {
  final _this = this as HandoverNote;
  return 'HandoverNote(id: ${_this.id}, date: ${_this.date}, items: ${_this.items}, medicine: ${_this.medicine}, homework: ${_this.homework}, clothes: ${_this.clothes}, note: ${_this.note}, updatedBySide: ${_this.updatedBySide}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $HandoverNoteCopyWith<$Res>  {
  factory $HandoverNoteCopyWith(HandoverNote value, $Res Function(HandoverNote) _then) = _$HandoverNoteCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id,@CalendarDateConverter() CalendarDate date, List<HandoverItem> items, String? medicine, String? homework, String? clothes, String? note,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) CustodySide? updatedBySide,@ServerTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$HandoverNoteCopyWithImpl<$Res>
    implements $HandoverNoteCopyWith<$Res> {
  _$HandoverNoteCopyWithImpl(this._self, this._then);

  final HandoverNote _self;
  final $Res Function(HandoverNote) _then;

/// Create a copy of HandoverNote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? date = null,Object? items = null,Object? medicine = freezed,Object? homework = freezed,Object? clothes = freezed,Object? note = freezed,Object? updatedBySide = freezed,Object? updatedAt = freezed,}) {
  return _then(HandoverNote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as CalendarDate,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<HandoverItem>,medicine: freezed == medicine ? _self.medicine : medicine // ignore: cast_nullable_to_non_nullable
as String?,homework: freezed == homework ? _self.homework : homework // ignore: cast_nullable_to_non_nullable
as String?,clothes: freezed == clothes ? _self.clothes : clothes // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,updatedBySide: freezed == updatedBySide ? _self.updatedBySide : updatedBySide // ignore: cast_nullable_to_non_nullable
as CustodySide?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [HandoverNote].
extension HandoverNotePatterns on HandoverNote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HandoverNote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HandoverNote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HandoverNote value)  $default,){
final _that = this;
switch (_that) {
case _HandoverNote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HandoverNote value)?  $default,){
final _that = this;
switch (_that) {
case _HandoverNote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id, @CalendarDateConverter()  CalendarDate date,  List<HandoverItem> items,  String? medicine,  String? homework,  String? clothes,  String? note, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  CustodySide? updatedBySide, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HandoverNote() when $default != null:
return $default(_that.id,_that.date,_that.items,_that.medicine,_that.homework,_that.clothes,_that.note,_that.updatedBySide,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id, @CalendarDateConverter()  CalendarDate date,  List<HandoverItem> items,  String? medicine,  String? homework,  String? clothes,  String? note, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  CustodySide? updatedBySide, @ServerTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _HandoverNote():
return $default(_that.id,_that.date,_that.items,_that.medicine,_that.homework,_that.clothes,_that.note,_that.updatedBySide,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id, @CalendarDateConverter()  CalendarDate date,  List<HandoverItem> items,  String? medicine,  String? homework,  String? clothes,  String? note, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  CustodySide? updatedBySide, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _HandoverNote() when $default != null:
return $default(_that.id,_that.date,_that.items,_that.medicine,_that.homework,_that.clothes,_that.note,_that.updatedBySide,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HandoverNote extends HandoverNote {
  const _HandoverNote({@JsonKey(includeToJson: false) required this.id, @CalendarDateConverter() required this.date,  List<HandoverItem> items = const <HandoverItem>[], this.medicine, this.homework, this.clothes, this.note, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) this.updatedBySide, @ServerTimestampConverter() this.updatedAt}): _items = items,super._();
  factory _HandoverNote.fromJson(Map<String, dynamic> json) => _$HandoverNoteFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override@CalendarDateConverter() final  CalendarDate date;
 final  List<HandoverItem> _items;
@override@JsonKey() List<HandoverItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? medicine;
@override final  String? homework;
@override final  String? clothes;
@override final  String? note;
@override@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) final  CustodySide? updatedBySide;
@override@ServerTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of HandoverNote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HandoverNoteCopyWith<_HandoverNote> get copyWith => __$HandoverNoteCopyWithImpl<_HandoverNote>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HandoverNoteToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HandoverNote&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.medicine, medicine) || other.medicine == medicine)&&(identical(other.homework, homework) || other.homework == homework)&&(identical(other.clothes, clothes) || other.clothes == clothes)&&(identical(other.note, note) || other.note == note)&&(identical(other.updatedBySide, updatedBySide) || other.updatedBySide == updatedBySide)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,date,const DeepCollectionEquality().hash(_items),medicine,homework,clothes,note,updatedBySide,updatedAt);
}

@override
String toString() {
    return 'HandoverNote(id: $id, date: $date, items: $items, medicine: $medicine, homework: $homework, clothes: $clothes, note: $note, updatedBySide: $updatedBySide, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$HandoverNoteCopyWith<$Res> implements $HandoverNoteCopyWith<$Res> {
  factory _$HandoverNoteCopyWith(_HandoverNote value, $Res Function(_HandoverNote) _then) = __$HandoverNoteCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id,@CalendarDateConverter() CalendarDate date, List<HandoverItem> items, String? medicine, String? homework, String? clothes, String? note,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) CustodySide? updatedBySide,@ServerTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$HandoverNoteCopyWithImpl<$Res>
    implements _$HandoverNoteCopyWith<$Res> {
  __$HandoverNoteCopyWithImpl(this._self, this._then);

  final _HandoverNote _self;
  final $Res Function(_HandoverNote) _then;

/// Create a copy of HandoverNote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? date = null,Object? items = null,Object? medicine = freezed,Object? homework = freezed,Object? clothes = freezed,Object? note = freezed,Object? updatedBySide = freezed,Object? updatedAt = freezed,}) {
  return _then(_HandoverNote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as CalendarDate,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<HandoverItem>,medicine: freezed == medicine ? _self.medicine : medicine // ignore: cast_nullable_to_non_nullable
as String?,homework: freezed == homework ? _self.homework : homework // ignore: cast_nullable_to_non_nullable
as String?,clothes: freezed == clothes ? _self.clothes : clothes // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,updatedBySide: freezed == updatedBySide ? _self.updatedBySide : updatedBySide // ignore: cast_nullable_to_non_nullable
as CustodySide?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

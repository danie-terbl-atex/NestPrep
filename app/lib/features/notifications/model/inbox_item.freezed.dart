// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'inbox_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DigestLine {

 String get text; String? get detail;
/// Create a copy of DigestLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DigestLineCopyWith<DigestLine> get copyWith => _$DigestLineCopyWithImpl<DigestLine>(this as DigestLine, _$identity);

  /// Serializes this DigestLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DigestLine;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DigestLine&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.detail, _this.detail) || other.detail == _this.detail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DigestLine;
  return Object.hash(runtimeType,_this.text,_this.detail);
}

@override
String toString() {
  final _this = this as DigestLine;
  return 'DigestLine(text: ${_this.text}, detail: ${_this.detail})';
}


}

/// @nodoc
abstract mixin class $DigestLineCopyWith<$Res>  {
  factory $DigestLineCopyWith(DigestLine value, $Res Function(DigestLine) _then) = _$DigestLineCopyWithImpl;
@useResult
$Res call({
 String text, String? detail
});




}
/// @nodoc
class _$DigestLineCopyWithImpl<$Res>
    implements $DigestLineCopyWith<$Res> {
  _$DigestLineCopyWithImpl(this._self, this._then);

  final DigestLine _self;
  final $Res Function(DigestLine) _then;

/// Create a copy of DigestLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? detail = freezed,}) {
  return _then(DigestLine(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DigestLine].
extension DigestLinePatterns on DigestLine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DigestLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DigestLine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DigestLine value)  $default,){
final _that = this;
switch (_that) {
case _DigestLine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DigestLine value)?  $default,){
final _that = this;
switch (_that) {
case _DigestLine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  String? detail)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DigestLine() when $default != null:
return $default(_that.text,_that.detail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  String? detail)  $default,) {final _that = this;
switch (_that) {
case _DigestLine():
return $default(_that.text,_that.detail);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  String? detail)?  $default,) {final _that = this;
switch (_that) {
case _DigestLine() when $default != null:
return $default(_that.text,_that.detail);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DigestLine implements DigestLine {
  const _DigestLine({required this.text, this.detail});
  factory _DigestLine.fromJson(Map<String, dynamic> json) => _$DigestLineFromJson(json);

@override final  String text;
@override final  String? detail;

/// Create a copy of DigestLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DigestLineCopyWith<_DigestLine> get copyWith => __$DigestLineCopyWithImpl<_DigestLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DigestLineToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DigestLine&&(identical(other.text, text) || other.text == text)&&(identical(other.detail, detail) || other.detail == detail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,text,detail);
}

@override
String toString() {
    return 'DigestLine(text: $text, detail: $detail)';
}


}

/// @nodoc
abstract mixin class _$DigestLineCopyWith<$Res> implements $DigestLineCopyWith<$Res> {
  factory _$DigestLineCopyWith(_DigestLine value, $Res Function(_DigestLine) _then) = __$DigestLineCopyWithImpl;
@override @useResult
$Res call({
 String text, String? detail
});




}
/// @nodoc
class __$DigestLineCopyWithImpl<$Res>
    implements _$DigestLineCopyWith<$Res> {
  __$DigestLineCopyWithImpl(this._self, this._then);

  final _DigestLine _self;
  final $Res Function(_DigestLine) _then;

/// Create a copy of DigestLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? detail = freezed,}) {
  return _then(_DigestLine(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$DigestSection {

 String get kind; int get total; List<DigestLine> get items;
/// Create a copy of DigestSection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DigestSectionCopyWith<DigestSection> get copyWith => _$DigestSectionCopyWithImpl<DigestSection>(this as DigestSection, _$identity);

  /// Serializes this DigestSection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DigestSection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DigestSection&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.total, _this.total) || other.total == _this.total)&&const DeepCollectionEquality().equals(other.items, _this.items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DigestSection;
  return Object.hash(runtimeType,_this.kind,_this.total,const DeepCollectionEquality().hash(_this.items));
}

@override
String toString() {
  final _this = this as DigestSection;
  return 'DigestSection(kind: ${_this.kind}, total: ${_this.total}, items: ${_this.items})';
}


}

/// @nodoc
abstract mixin class $DigestSectionCopyWith<$Res>  {
  factory $DigestSectionCopyWith(DigestSection value, $Res Function(DigestSection) _then) = _$DigestSectionCopyWithImpl;
@useResult
$Res call({
 String kind, int total, List<DigestLine> items
});




}
/// @nodoc
class _$DigestSectionCopyWithImpl<$Res>
    implements $DigestSectionCopyWith<$Res> {
  _$DigestSectionCopyWithImpl(this._self, this._then);

  final DigestSection _self;
  final $Res Function(DigestSection) _then;

/// Create a copy of DigestSection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? total = null,Object? items = null,}) {
  return _then(DigestSection(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<DigestLine>,
  ));
}

}


/// Adds pattern-matching-related methods to [DigestSection].
extension DigestSectionPatterns on DigestSection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DigestSection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DigestSection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DigestSection value)  $default,){
final _that = this;
switch (_that) {
case _DigestSection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DigestSection value)?  $default,){
final _that = this;
switch (_that) {
case _DigestSection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind,  int total,  List<DigestLine> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DigestSection() when $default != null:
return $default(_that.kind,_that.total,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind,  int total,  List<DigestLine> items)  $default,) {final _that = this;
switch (_that) {
case _DigestSection():
return $default(_that.kind,_that.total,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind,  int total,  List<DigestLine> items)?  $default,) {final _that = this;
switch (_that) {
case _DigestSection() when $default != null:
return $default(_that.kind,_that.total,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DigestSection extends DigestSection {
  const _DigestSection({required this.kind, this.total = 0,  List<DigestLine> items = const <DigestLine>[]}): _items = items,super._();
  factory _DigestSection.fromJson(Map<String, dynamic> json) => _$DigestSectionFromJson(json);

@override final  String kind;
@override@JsonKey() final  int total;
 final  List<DigestLine> _items;
@override@JsonKey() List<DigestLine> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of DigestSection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DigestSectionCopyWith<_DigestSection> get copyWith => __$DigestSectionCopyWithImpl<_DigestSection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DigestSectionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DigestSection&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other.items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,total,const DeepCollectionEquality().hash(_items));
}

@override
String toString() {
    return 'DigestSection(kind: $kind, total: $total, items: $items)';
}


}

/// @nodoc
abstract mixin class _$DigestSectionCopyWith<$Res> implements $DigestSectionCopyWith<$Res> {
  factory _$DigestSectionCopyWith(_DigestSection value, $Res Function(_DigestSection) _then) = __$DigestSectionCopyWithImpl;
@override @useResult
$Res call({
 String kind, int total, List<DigestLine> items
});




}
/// @nodoc
class __$DigestSectionCopyWithImpl<$Res>
    implements _$DigestSectionCopyWith<$Res> {
  __$DigestSectionCopyWithImpl(this._self, this._then);

  final _DigestSection _self;
  final $Res Function(_DigestSection) _then;

/// Create a copy of DigestSection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? total = null,Object? items = null,}) {
  return _then(_DigestSection(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<DigestLine>,
  ));
}


}


/// @nodoc
mixin _$InboxTarget {

 String get kind; String? get id;
/// Create a copy of InboxTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InboxTargetCopyWith<InboxTarget> get copyWith => _$InboxTargetCopyWithImpl<InboxTarget>(this as InboxTarget, _$identity);

  /// Serializes this InboxTarget to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as InboxTarget;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InboxTarget&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.id, _this.id) || other.id == _this.id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as InboxTarget;
  return Object.hash(runtimeType,_this.kind,_this.id);
}

@override
String toString() {
  final _this = this as InboxTarget;
  return 'InboxTarget(kind: ${_this.kind}, id: ${_this.id})';
}


}

/// @nodoc
abstract mixin class $InboxTargetCopyWith<$Res>  {
  factory $InboxTargetCopyWith(InboxTarget value, $Res Function(InboxTarget) _then) = _$InboxTargetCopyWithImpl;
@useResult
$Res call({
 String kind, String? id
});




}
/// @nodoc
class _$InboxTargetCopyWithImpl<$Res>
    implements $InboxTargetCopyWith<$Res> {
  _$InboxTargetCopyWithImpl(this._self, this._then);

  final InboxTarget _self;
  final $Res Function(InboxTarget) _then;

/// Create a copy of InboxTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? id = freezed,}) {
  return _then(InboxTarget(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [InboxTarget].
extension InboxTargetPatterns on InboxTarget {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InboxTarget value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InboxTarget() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InboxTarget value)  $default,){
final _that = this;
switch (_that) {
case _InboxTarget():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InboxTarget value)?  $default,){
final _that = this;
switch (_that) {
case _InboxTarget() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind,  String? id)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InboxTarget() when $default != null:
return $default(_that.kind,_that.id);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind,  String? id)  $default,) {final _that = this;
switch (_that) {
case _InboxTarget():
return $default(_that.kind,_that.id);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind,  String? id)?  $default,) {final _that = this;
switch (_that) {
case _InboxTarget() when $default != null:
return $default(_that.kind,_that.id);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InboxTarget extends InboxTarget {
  const _InboxTarget({required this.kind, this.id}): super._();
  factory _InboxTarget.fromJson(Map<String, dynamic> json) => _$InboxTargetFromJson(json);

@override final  String kind;
@override final  String? id;

/// Create a copy of InboxTarget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InboxTargetCopyWith<_InboxTarget> get copyWith => __$InboxTargetCopyWithImpl<_InboxTarget>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InboxTargetToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InboxTarget&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,id);
}

@override
String toString() {
    return 'InboxTarget(kind: $kind, id: $id)';
}


}

/// @nodoc
abstract mixin class _$InboxTargetCopyWith<$Res> implements $InboxTargetCopyWith<$Res> {
  factory _$InboxTargetCopyWith(_InboxTarget value, $Res Function(_InboxTarget) _then) = __$InboxTargetCopyWithImpl;
@override @useResult
$Res call({
 String kind, String? id
});




}
/// @nodoc
class __$InboxTargetCopyWithImpl<$Res>
    implements _$InboxTargetCopyWith<$Res> {
  __$InboxTargetCopyWithImpl(this._self, this._then);

  final _InboxTarget _self;
  final $Res Function(_InboxTarget) _then;

/// Create a copy of InboxTarget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? id = freezed,}) {
  return _then(_InboxTarget(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$InboxItem {

@JsonKey(includeToJson: false) String get id; String get memberId; String get category; String get title; String get body; String? get detail; List<DigestSection> get sections; InboxTarget get target; String get localDate;@NullableTimestampConverter() DateTime? get createdAt;@NullableTimestampConverter() DateTime? get readAt;
/// Create a copy of InboxItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InboxItemCopyWith<InboxItem> get copyWith => _$InboxItemCopyWithImpl<InboxItem>(this as InboxItem, _$identity);

  /// Serializes this InboxItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as InboxItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InboxItem&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.memberId, _this.memberId) || other.memberId == _this.memberId)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.body, _this.body) || other.body == _this.body)&&(identical(other.detail, _this.detail) || other.detail == _this.detail)&&const DeepCollectionEquality().equals(other.sections, _this.sections)&&(identical(other.target, _this.target) || other.target == _this.target)&&(identical(other.localDate, _this.localDate) || other.localDate == _this.localDate)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.readAt, _this.readAt) || other.readAt == _this.readAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as InboxItem;
  return Object.hash(runtimeType,_this.id,_this.memberId,_this.category,_this.title,_this.body,_this.detail,const DeepCollectionEquality().hash(_this.sections),_this.target,_this.localDate,_this.createdAt,_this.readAt);
}

@override
String toString() {
  final _this = this as InboxItem;
  return 'InboxItem(id: ${_this.id}, memberId: ${_this.memberId}, category: ${_this.category}, title: ${_this.title}, body: ${_this.body}, detail: ${_this.detail}, sections: ${_this.sections}, target: ${_this.target}, localDate: ${_this.localDate}, createdAt: ${_this.createdAt}, readAt: ${_this.readAt})';
}


}

/// @nodoc
abstract mixin class $InboxItemCopyWith<$Res>  {
  factory $InboxItemCopyWith(InboxItem value, $Res Function(InboxItem) _then) = _$InboxItemCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String memberId, String category, String title, String body, String? detail, List<DigestSection> sections, InboxTarget target, String localDate,@NullableTimestampConverter() DateTime? createdAt,@NullableTimestampConverter() DateTime? readAt
});


$InboxTargetCopyWith<$Res> get target;

}
/// @nodoc
class _$InboxItemCopyWithImpl<$Res>
    implements $InboxItemCopyWith<$Res> {
  _$InboxItemCopyWithImpl(this._self, this._then);

  final InboxItem _self;
  final $Res Function(InboxItem) _then;

/// Create a copy of InboxItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? memberId = null,Object? category = null,Object? title = null,Object? body = null,Object? detail = freezed,Object? sections = null,Object? target = null,Object? localDate = null,Object? createdAt = freezed,Object? readAt = freezed,}) {
  return _then(InboxItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,sections: null == sections ? _self.sections : sections // ignore: cast_nullable_to_non_nullable
as List<DigestSection>,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as InboxTarget,localDate: null == localDate ? _self.localDate : localDate // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of InboxItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InboxTargetCopyWith<$Res> get target {
  
  return $InboxTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}


/// Adds pattern-matching-related methods to [InboxItem].
extension InboxItemPatterns on InboxItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InboxItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InboxItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InboxItem value)  $default,){
final _that = this;
switch (_that) {
case _InboxItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InboxItem value)?  $default,){
final _that = this;
switch (_that) {
case _InboxItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String memberId,  String category,  String title,  String body,  String? detail,  List<DigestSection> sections,  InboxTarget target,  String localDate, @NullableTimestampConverter()  DateTime? createdAt, @NullableTimestampConverter()  DateTime? readAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InboxItem() when $default != null:
return $default(_that.id,_that.memberId,_that.category,_that.title,_that.body,_that.detail,_that.sections,_that.target,_that.localDate,_that.createdAt,_that.readAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String memberId,  String category,  String title,  String body,  String? detail,  List<DigestSection> sections,  InboxTarget target,  String localDate, @NullableTimestampConverter()  DateTime? createdAt, @NullableTimestampConverter()  DateTime? readAt)  $default,) {final _that = this;
switch (_that) {
case _InboxItem():
return $default(_that.id,_that.memberId,_that.category,_that.title,_that.body,_that.detail,_that.sections,_that.target,_that.localDate,_that.createdAt,_that.readAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String memberId,  String category,  String title,  String body,  String? detail,  List<DigestSection> sections,  InboxTarget target,  String localDate, @NullableTimestampConverter()  DateTime? createdAt, @NullableTimestampConverter()  DateTime? readAt)?  $default,) {final _that = this;
switch (_that) {
case _InboxItem() when $default != null:
return $default(_that.id,_that.memberId,_that.category,_that.title,_that.body,_that.detail,_that.sections,_that.target,_that.localDate,_that.createdAt,_that.readAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InboxItem extends InboxItem {
  const _InboxItem({@JsonKey(includeToJson: false) required this.id, required this.memberId, required this.category, required this.title, required this.body, this.detail,  List<DigestSection> sections = const <DigestSection>[], this.target = const InboxTarget(kind: 'inboxItem'), this.localDate = '', @NullableTimestampConverter() this.createdAt, @NullableTimestampConverter() this.readAt}): _sections = sections,super._();
  factory _InboxItem.fromJson(Map<String, dynamic> json) => _$InboxItemFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String memberId;
@override final  String category;
@override final  String title;
@override final  String body;
@override final  String? detail;
 final  List<DigestSection> _sections;
@override@JsonKey() List<DigestSection> get sections {
  if (_sections is EqualUnmodifiableListView) return _sections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sections);
}

@override@JsonKey() final  InboxTarget target;
@override@JsonKey() final  String localDate;
@override@NullableTimestampConverter() final  DateTime? createdAt;
@override@NullableTimestampConverter() final  DateTime? readAt;

/// Create a copy of InboxItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InboxItemCopyWith<_InboxItem> get copyWith => __$InboxItemCopyWithImpl<_InboxItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InboxItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InboxItem&&(identical(other.id, id) || other.id == id)&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.category, category) || other.category == category)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.detail, detail) || other.detail == detail)&&const DeepCollectionEquality().equals(other.sections, _sections)&&(identical(other.target, target) || other.target == target)&&(identical(other.localDate, localDate) || other.localDate == localDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.readAt, readAt) || other.readAt == readAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,memberId,category,title,body,detail,const DeepCollectionEquality().hash(_sections),target,localDate,createdAt,readAt);
}

@override
String toString() {
    return 'InboxItem(id: $id, memberId: $memberId, category: $category, title: $title, body: $body, detail: $detail, sections: $sections, target: $target, localDate: $localDate, createdAt: $createdAt, readAt: $readAt)';
}


}

/// @nodoc
abstract mixin class _$InboxItemCopyWith<$Res> implements $InboxItemCopyWith<$Res> {
  factory _$InboxItemCopyWith(_InboxItem value, $Res Function(_InboxItem) _then) = __$InboxItemCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String memberId, String category, String title, String body, String? detail, List<DigestSection> sections, InboxTarget target, String localDate,@NullableTimestampConverter() DateTime? createdAt,@NullableTimestampConverter() DateTime? readAt
});


@override $InboxTargetCopyWith<$Res> get target;

}
/// @nodoc
class __$InboxItemCopyWithImpl<$Res>
    implements _$InboxItemCopyWith<$Res> {
  __$InboxItemCopyWithImpl(this._self, this._then);

  final _InboxItem _self;
  final $Res Function(_InboxItem) _then;

/// Create a copy of InboxItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? memberId = null,Object? category = null,Object? title = null,Object? body = null,Object? detail = freezed,Object? sections = null,Object? target = null,Object? localDate = null,Object? createdAt = freezed,Object? readAt = freezed,}) {
  return _then(_InboxItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,sections: null == sections ? _self._sections : sections // ignore: cast_nullable_to_non_nullable
as List<DigestSection>,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as InboxTarget,localDate: null == localDate ? _self.localDate : localDate // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of InboxItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InboxTargetCopyWith<$Res> get target {
  
  return $InboxTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}

// dart format on

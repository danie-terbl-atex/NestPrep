// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'photo_frame.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PhotoFrame {

@JsonKey(includeToJson: false) String get id; String get name; FramePanels get panels;@FrameScreensaverConverter() FrameScreensaver get screensaver;@FrameGroceriesConverter() FrameGroceries? get groceries; String get model; String get linkedBy;@NullableTimestampConverter() DateTime? get linkedAt;@NullableTimestampConverter() DateTime? get lastSeenAt;@JsonKey(fromJson: _acceptsFromJson, includeToJson: false) List<String> get accepts;
/// Create a copy of PhotoFrame
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PhotoFrameCopyWith<PhotoFrame> get copyWith => _$PhotoFrameCopyWithImpl<PhotoFrame>(this as PhotoFrame, _$identity);

  /// Serializes this PhotoFrame to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PhotoFrame;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PhotoFrame&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.panels, _this.panels) || other.panels == _this.panels)&&(identical(other.screensaver, _this.screensaver) || other.screensaver == _this.screensaver)&&(identical(other.groceries, _this.groceries) || other.groceries == _this.groceries)&&(identical(other.model, _this.model) || other.model == _this.model)&&(identical(other.linkedBy, _this.linkedBy) || other.linkedBy == _this.linkedBy)&&(identical(other.linkedAt, _this.linkedAt) || other.linkedAt == _this.linkedAt)&&(identical(other.lastSeenAt, _this.lastSeenAt) || other.lastSeenAt == _this.lastSeenAt)&&const DeepCollectionEquality().equals(other.accepts, _this.accepts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PhotoFrame;
  return Object.hash(runtimeType,_this.id,_this.name,_this.panels,_this.screensaver,_this.groceries,_this.model,_this.linkedBy,_this.linkedAt,_this.lastSeenAt,const DeepCollectionEquality().hash(_this.accepts));
}

@override
String toString() {
  final _this = this as PhotoFrame;
  return 'PhotoFrame(id: ${_this.id}, name: ${_this.name}, panels: ${_this.panels}, screensaver: ${_this.screensaver}, groceries: ${_this.groceries}, model: ${_this.model}, linkedBy: ${_this.linkedBy}, linkedAt: ${_this.linkedAt}, lastSeenAt: ${_this.lastSeenAt}, accepts: ${_this.accepts})';
}


}

/// @nodoc
abstract mixin class $PhotoFrameCopyWith<$Res>  {
  factory $PhotoFrameCopyWith(PhotoFrame value, $Res Function(PhotoFrame) _then) = _$PhotoFrameCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String name, FramePanels panels,@FrameScreensaverConverter() FrameScreensaver screensaver,@FrameGroceriesConverter() FrameGroceries? groceries, String model, String linkedBy,@NullableTimestampConverter() DateTime? linkedAt,@NullableTimestampConverter() DateTime? lastSeenAt,@JsonKey(fromJson: _acceptsFromJson, includeToJson: false) List<String> accepts
});


$FramePanelsCopyWith<$Res> get panels;$FrameScreensaverCopyWith<$Res> get screensaver;$FrameGroceriesCopyWith<$Res>? get groceries;

}
/// @nodoc
class _$PhotoFrameCopyWithImpl<$Res>
    implements $PhotoFrameCopyWith<$Res> {
  _$PhotoFrameCopyWithImpl(this._self, this._then);

  final PhotoFrame _self;
  final $Res Function(PhotoFrame) _then;

/// Create a copy of PhotoFrame
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? panels = null,Object? screensaver = null,Object? groceries = freezed,Object? model = null,Object? linkedBy = null,Object? linkedAt = freezed,Object? lastSeenAt = freezed,Object? accepts = null,}) {
  return _then(PhotoFrame(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,panels: null == panels ? _self.panels : panels // ignore: cast_nullable_to_non_nullable
as FramePanels,screensaver: null == screensaver ? _self.screensaver : screensaver // ignore: cast_nullable_to_non_nullable
as FrameScreensaver,groceries: freezed == groceries ? _self.groceries : groceries // ignore: cast_nullable_to_non_nullable
as FrameGroceries?,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,linkedBy: null == linkedBy ? _self.linkedBy : linkedBy // ignore: cast_nullable_to_non_nullable
as String,linkedAt: freezed == linkedAt ? _self.linkedAt : linkedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastSeenAt: freezed == lastSeenAt ? _self.lastSeenAt : lastSeenAt // ignore: cast_nullable_to_non_nullable
as DateTime?,accepts: null == accepts ? _self.accepts : accepts // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of PhotoFrame
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FramePanelsCopyWith<$Res> get panels {
  
  return $FramePanelsCopyWith<$Res>(_self.panels, (value) {
    return _then(_self.copyWith(panels: value));
  });
}/// Create a copy of PhotoFrame
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FrameScreensaverCopyWith<$Res> get screensaver {
  
  return $FrameScreensaverCopyWith<$Res>(_self.screensaver, (value) {
    return _then(_self.copyWith(screensaver: value));
  });
}/// Create a copy of PhotoFrame
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FrameGroceriesCopyWith<$Res>? get groceries {
    if (_self.groceries == null) {
    return null;
  }

  return $FrameGroceriesCopyWith<$Res>(_self.groceries!, (value) {
    return _then(_self.copyWith(groceries: value));
  });
}
}


/// Adds pattern-matching-related methods to [PhotoFrame].
extension PhotoFramePatterns on PhotoFrame {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PhotoFrame value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PhotoFrame() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PhotoFrame value)  $default,){
final _that = this;
switch (_that) {
case _PhotoFrame():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PhotoFrame value)?  $default,){
final _that = this;
switch (_that) {
case _PhotoFrame() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String name,  FramePanels panels, @FrameScreensaverConverter()  FrameScreensaver screensaver, @FrameGroceriesConverter()  FrameGroceries? groceries,  String model,  String linkedBy, @NullableTimestampConverter()  DateTime? linkedAt, @NullableTimestampConverter()  DateTime? lastSeenAt, @JsonKey(fromJson: _acceptsFromJson, includeToJson: false)  List<String> accepts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PhotoFrame() when $default != null:
return $default(_that.id,_that.name,_that.panels,_that.screensaver,_that.groceries,_that.model,_that.linkedBy,_that.linkedAt,_that.lastSeenAt,_that.accepts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String name,  FramePanels panels, @FrameScreensaverConverter()  FrameScreensaver screensaver, @FrameGroceriesConverter()  FrameGroceries? groceries,  String model,  String linkedBy, @NullableTimestampConverter()  DateTime? linkedAt, @NullableTimestampConverter()  DateTime? lastSeenAt, @JsonKey(fromJson: _acceptsFromJson, includeToJson: false)  List<String> accepts)  $default,) {final _that = this;
switch (_that) {
case _PhotoFrame():
return $default(_that.id,_that.name,_that.panels,_that.screensaver,_that.groceries,_that.model,_that.linkedBy,_that.linkedAt,_that.lastSeenAt,_that.accepts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String name,  FramePanels panels, @FrameScreensaverConverter()  FrameScreensaver screensaver, @FrameGroceriesConverter()  FrameGroceries? groceries,  String model,  String linkedBy, @NullableTimestampConverter()  DateTime? linkedAt, @NullableTimestampConverter()  DateTime? lastSeenAt, @JsonKey(fromJson: _acceptsFromJson, includeToJson: false)  List<String> accepts)?  $default,) {final _that = this;
switch (_that) {
case _PhotoFrame() when $default != null:
return $default(_that.id,_that.name,_that.panels,_that.screensaver,_that.groceries,_that.model,_that.linkedBy,_that.linkedAt,_that.lastSeenAt,_that.accepts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PhotoFrame extends PhotoFrame {
  const _PhotoFrame({@JsonKey(includeToJson: false) required this.id, required this.name, this.panels = const FramePanels(), @FrameScreensaverConverter() this.screensaver = FrameScreensaver.off, @FrameGroceriesConverter() this.groceries, this.model = '', this.linkedBy = '', @NullableTimestampConverter() this.linkedAt, @NullableTimestampConverter() this.lastSeenAt, @JsonKey(fromJson: _acceptsFromJson, includeToJson: false)  List<String> accepts = PhotoFrame.pageOnly}): _accepts = accepts,super._();
  factory _PhotoFrame.fromJson(Map<String, dynamic> json) => _$PhotoFrameFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String name;
@override@JsonKey() final  FramePanels panels;
@override@JsonKey()@FrameScreensaverConverter() final  FrameScreensaver screensaver;
@override@FrameGroceriesConverter() final  FrameGroceries? groceries;
@override@JsonKey() final  String model;
@override@JsonKey() final  String linkedBy;
@override@NullableTimestampConverter() final  DateTime? linkedAt;
@override@NullableTimestampConverter() final  DateTime? lastSeenAt;
 final  List<String> _accepts;
@override@JsonKey(fromJson: _acceptsFromJson, includeToJson: false) List<String> get accepts {
  if (_accepts is EqualUnmodifiableListView) return _accepts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_accepts);
}


/// Create a copy of PhotoFrame
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PhotoFrameCopyWith<_PhotoFrame> get copyWith => __$PhotoFrameCopyWithImpl<_PhotoFrame>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PhotoFrameToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PhotoFrame&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.panels, panels) || other.panels == panels)&&(identical(other.screensaver, screensaver) || other.screensaver == screensaver)&&(identical(other.groceries, groceries) || other.groceries == groceries)&&(identical(other.model, model) || other.model == model)&&(identical(other.linkedBy, linkedBy) || other.linkedBy == linkedBy)&&(identical(other.linkedAt, linkedAt) || other.linkedAt == linkedAt)&&(identical(other.lastSeenAt, lastSeenAt) || other.lastSeenAt == lastSeenAt)&&const DeepCollectionEquality().equals(other.accepts, _accepts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,panels,screensaver,groceries,model,linkedBy,linkedAt,lastSeenAt,const DeepCollectionEquality().hash(_accepts));
}

@override
String toString() {
    return 'PhotoFrame(id: $id, name: $name, panels: $panels, screensaver: $screensaver, groceries: $groceries, model: $model, linkedBy: $linkedBy, linkedAt: $linkedAt, lastSeenAt: $lastSeenAt, accepts: $accepts)';
}


}

/// @nodoc
abstract mixin class _$PhotoFrameCopyWith<$Res> implements $PhotoFrameCopyWith<$Res> {
  factory _$PhotoFrameCopyWith(_PhotoFrame value, $Res Function(_PhotoFrame) _then) = __$PhotoFrameCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String name, FramePanels panels,@FrameScreensaverConverter() FrameScreensaver screensaver,@FrameGroceriesConverter() FrameGroceries? groceries, String model, String linkedBy,@NullableTimestampConverter() DateTime? linkedAt,@NullableTimestampConverter() DateTime? lastSeenAt,@JsonKey(fromJson: _acceptsFromJson, includeToJson: false) List<String> accepts
});


@override $FramePanelsCopyWith<$Res> get panels;@override $FrameScreensaverCopyWith<$Res> get screensaver;@override $FrameGroceriesCopyWith<$Res>? get groceries;

}
/// @nodoc
class __$PhotoFrameCopyWithImpl<$Res>
    implements _$PhotoFrameCopyWith<$Res> {
  __$PhotoFrameCopyWithImpl(this._self, this._then);

  final _PhotoFrame _self;
  final $Res Function(_PhotoFrame) _then;

/// Create a copy of PhotoFrame
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? panels = null,Object? screensaver = null,Object? groceries = freezed,Object? model = null,Object? linkedBy = null,Object? linkedAt = freezed,Object? lastSeenAt = freezed,Object? accepts = null,}) {
  return _then(_PhotoFrame(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,panels: null == panels ? _self.panels : panels // ignore: cast_nullable_to_non_nullable
as FramePanels,screensaver: null == screensaver ? _self.screensaver : screensaver // ignore: cast_nullable_to_non_nullable
as FrameScreensaver,groceries: freezed == groceries ? _self.groceries : groceries // ignore: cast_nullable_to_non_nullable
as FrameGroceries?,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,linkedBy: null == linkedBy ? _self.linkedBy : linkedBy // ignore: cast_nullable_to_non_nullable
as String,linkedAt: freezed == linkedAt ? _self.linkedAt : linkedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastSeenAt: freezed == lastSeenAt ? _self.lastSeenAt : lastSeenAt // ignore: cast_nullable_to_non_nullable
as DateTime?,accepts: null == accepts ? _self._accepts : accepts // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of PhotoFrame
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FramePanelsCopyWith<$Res> get panels {
  
  return $FramePanelsCopyWith<$Res>(_self.panels, (value) {
    return _then(_self.copyWith(panels: value));
  });
}/// Create a copy of PhotoFrame
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FrameScreensaverCopyWith<$Res> get screensaver {
  
  return $FrameScreensaverCopyWith<$Res>(_self.screensaver, (value) {
    return _then(_self.copyWith(screensaver: value));
  });
}/// Create a copy of PhotoFrame
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FrameGroceriesCopyWith<$Res>? get groceries {
    if (_self.groceries == null) {
    return null;
  }

  return $FrameGroceriesCopyWith<$Res>(_self.groceries!, (value) {
    return _then(_self.copyWith(groceries: value));
  });
}
}

// dart format on

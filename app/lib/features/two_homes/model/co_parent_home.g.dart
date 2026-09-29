// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'co_parent_home.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CoParentHome _$CoParentHomeFromJson(Map<String, dynamic> json) =>
    _CoParentHome(
      name: json['name'] as String,
      color: const MemberColorConverter().fromJson(json['color']),
    );

Map<String, dynamic> _$CoParentHomeToJson(_CoParentHome instance) =>
    <String, dynamic>{
      'name': instance.name,
      'color': const MemberColorConverter().toJson(instance.color),
    };

_CoParentHomes _$CoParentHomesFromJson(Map<String, dynamic> json) =>
    _CoParentHomes(
      a: CoParentHome.fromJson(json['a'] as Map<String, dynamic>),
      b: CoParentHome.fromJson(json['b'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CoParentHomesToJson(_CoParentHomes instance) =>
    <String, dynamic>{'a': instance.a.toJson(), 'b': instance.b.toJson()};

import 'package:json_annotation/json_annotation.dart';

import 'member_look.dart';

class MemberLookConverter implements JsonConverter<MemberLook?, Object?> {
  const MemberLookConverter();

  @override
  MemberLook? fromJson(Object? json) => MemberLook.fromFirestore(json);

  @override
  Object? toJson(MemberLook? value) => null;
}

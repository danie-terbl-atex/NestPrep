import 'package:json_annotation/json_annotation.dart';

import '../../../design/tokens/nest_member_palette.dart';

/// A member's colour, stored as the palette entry's name. A colour outside the
/// palette is never written and never rendered — the palette is the whole set,
/// and it is proven readable in both themes by the contrast test
/// (design-system ADR-0001).
class MemberColorConverter implements JsonConverter<MemberColor, Object?> {
  const MemberColorConverter();

  @override
  MemberColor fromJson(Object? json) =>
      json is String ? MemberColor.fromName(json) : MemberColor.violet;

  @override
  Object toJson(MemberColor value) => value.name;
}

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../../shared/time/calendar_date.dart';
import '../../household/model/member.dart';
import '../model/avatar_catalogue.g.dart';
import '../model/avatar_place.dart';
import '../model/member_look.dart';
import '../model/resolved_avatar.dart';
import 'avatar_place_of.dart';

ResolvedAvatar? resolvedAvatarOf(
  BuildContext context,
  Member member, {
  MemberLook? look,
  bool listen = true,
}) {
  final flags = listen
      ? context.watch<FeatureFlagsController?>()
      : context.read<FeatureFlagsController?>();
  final shown = look ?? member.look;
  if (shown == null || !(flags?.isOn(FeatureFlag.avatars) ?? false)) {
    return null;
  }
  final place = avatarPlaceOf(context, listen: listen);
  return resolveAvatarAt(place, member, shown);
}

ResolvedAvatar resolveAvatarAt(
  AvatarPlace? place,
  Member member,
  MemberLook look,
) => ResolvedAvatar.of(
  look,
  today: place?.today ?? CalendarDate.fromDateTime(DateTime.now()),
  hemisphere: place?.hemisphere ?? AvatarHemisphere.north,
  birthday: member.birthday,
);

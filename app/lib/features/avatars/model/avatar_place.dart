import 'package:flutter/foundation.dart';

import '../../../shared/time/calendar_date.dart';
import 'avatar_catalogue.g.dart';
import 'avatar_hemisphere_of.dart';

@immutable
final class AvatarPlace {
  const AvatarPlace({
    required this.householdId,
    required this.today,
    required this.hemisphere,
  });

  factory AvatarPlace.of({
    required String householdId,
    required String timeZone,
    required CalendarDate today,
  }) => AvatarPlace(
    householdId: householdId,
    today: today,
    hemisphere: avatarHemisphereOf(timeZone),
  );

  final String householdId;
  final CalendarDate today;
  final AvatarHemisphere hemisphere;

  @override
  bool operator ==(Object other) =>
      other is AvatarPlace &&
      other.householdId == householdId &&
      other.today == today &&
      other.hemisphere == hemisphere;

  @override
  int get hashCode => Object.hash(householdId, today, hemisphere);
}

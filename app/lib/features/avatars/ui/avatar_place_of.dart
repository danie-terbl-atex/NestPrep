import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../shared/time/household_clock.dart';
import '../../household/model/household_view.dart';
import '../model/avatar_place.dart';

AvatarPlace? avatarPlaceOf(BuildContext context, {bool listen = true}) {
  final provided = Provider.of<AvatarPlace?>(context, listen: listen);
  if (provided != null) return provided;
  final household = Provider.of<HouseholdView?>(
    context,
    listen: listen,
  )?.household;
  final clock = Provider.of<HouseholdClock?>(context, listen: listen);
  if (household == null || clock == null) return null;
  return AvatarPlace.of(
    householdId: household.id,
    timeZone: household.timeZone,
    today: clock.today,
  );
}

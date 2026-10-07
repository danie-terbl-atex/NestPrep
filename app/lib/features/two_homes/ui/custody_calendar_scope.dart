import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../household/model/household_view.dart';
import '../data/two_homes_repository.dart';
import '../model/two_homes_access.dart';
import '../state/custody_calendar.dart';

/// Puts the linked children's days under the household's week (household
/// ADR-0004) — when the `coParenting` flag is on and the viewer reads the
/// calendar. Otherwise it adds nothing, and the week draws no bands: turning
/// the flag off hides them without touching a document.
class CustodyCalendarScope extends StatelessWidget {
  const CustodyCalendarScope({
    required this.householdId,
    required this.child,
    super.key,
  });

  final String householdId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isOn = context.watch<FeatureFlagsController>().isOn(
      FeatureFlag.coParenting,
    );
    final canSee = TwoHomesAccess.of(
      context.watch<HouseholdView>(),
    ).canSeeSchedule;
    if (!isOn || !canSee) return child;
    return ChangeNotifierProvider(
      create: (context) => CustodyCalendar(
        twoHomesRepository: context.read<TwoHomesRepository>(),
        householdId: householdId,
      ),
      child: child,
    );
  }
}

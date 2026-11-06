import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/family_route.dart';
import '../../../app/household_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../family_profiles/model/family_access.dart';
import '../model/household_view.dart';
import '../model/people_view.dart';

/// *Household | Profiles* under the People title (design-system ADR-0022),
/// for whoever the `familyProfiles` grant lets see profiles; nothing for
/// anybody else.
///
/// A tab is a place on the screen, not a step into it: switching replaces the
/// page, so back leaves People for wherever it was opened from.
class PeopleViewSwitch extends StatelessWidget {
  const PeopleViewSwitch({required this.current, super.key});

  final PeopleView current;

  @override
  Widget build(BuildContext context) {
    final view = context.watch<HouseholdView>();
    if (!FamilyAccess.of(view).isVisible) return const SizedBox.shrink();
    final householdId = view.household.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.xl),
      child: NestSegmentedControl<PeopleView>(
        segments: const [
          NestSegment(
            value: PeopleView.household,
            label: MoreCopy.peopleHousehold,
            icon: LucideIcons.house,
          ),
          NestSegment(
            value: PeopleView.profiles,
            label: MoreCopy.peopleProfiles,
            icon: LucideIcons.contactRound,
          ),
        ],
        selected: current,
        onSelect: (selected) {
          if (selected == current) return;
          context.replace(switch (selected) {
            PeopleView.household => HouseholdRoute.householdPathFor(
              householdId,
            ),
            PeopleView.profiles => FamilyRoute.pathFor(householdId),
          });
        },
      ),
    );
  }
}

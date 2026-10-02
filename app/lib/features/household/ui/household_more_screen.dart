import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/household_shell.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../../notifications/ui/notification_bell.dart';
import '../model/household_view.dart';
import 'household_people_card.dart';
import 'household_places.dart';

/// The More tab: the household's people and every place it has beyond the
/// four tabs in the bar, one tap from anywhere (design-system ADR-0005).
///
/// It reads the household the shell has already loaded, so it has no async
/// state of its own to wait on — the shell rendered the four states (`FE-08`).
class HouseholdMoreScreen extends StatelessWidget {
  const HouseholdMoreScreen({required this.onSelectTab, super.key});

  final ValueChanged<HouseholdTab> onSelectTab;

  @override
  Widget build(BuildContext context) {
    final view = context.watch<HouseholdView>();
    return NestScaffold(
      title: view.household.name,
      subtitle: MoreCopy.subtitle,
      trailing: const [NotificationBell(), AccountMenuButton()],
      bottomBar: HouseholdTabBar(
        current: HouseholdTab.more,
        onSelect: onSelectTab,
      ),
      body: ListView(
        children: [
          HouseholdPeopleCard(view: view),
          HouseholdPlaces(view: view),
          // Clear of the floating bar, so the last tile can be scrolled into
          // reach (`FE-14`).
          const SizedBox(height: NestSize.bottomBarHeight + NestSpace.huge),
        ],
      ),
    );
  }
}

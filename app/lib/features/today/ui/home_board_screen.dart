import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/household_shell.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/household_clock.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_place.dart';
import '../../household/model/household_view.dart';
import '../../household/ui/household_place_tile.dart';
import '../../notifications/ui/notification_bell.dart';
import '../../welcome_tour/model/tour_target.dart';
import '../../welcome_tour/ui/tour_anchor.dart';
import 'home_board_tab_tile.dart';
import 'home_layout_button.dart';
import 'today_agenda_section.dart';

/// The card home (design-system ADR-0019): no bar, every place a card.
class HomeBoardScreen extends StatelessWidget {
  const HomeBoardScreen({required this.onOpenTab, super.key});

  final ValueChanged<HouseholdTab> onOpenTab;

  static const _everyDayTabs = [
    HouseholdTab.week,
    HouseholdTab.todos,
    HouseholdTab.groceries,
    HouseholdTab.lunch,
    HouseholdTab.meals,
  ];
  static const _familyPlaces = [
    HouseholdPlace.sharedWeek,
    HouseholdPlace.familyProfiles,
    HouseholdPlace.whereWeAre,
    HouseholdPlace.twoHomes,
    HouseholdPlace.nannyHub,
    HouseholdPlace.homeCare,
    HouseholdPlace.documents,
    HouseholdPlace.photoFrames,
  ];

  @override
  Widget build(BuildContext context) {
    final view = context.watch<HouseholdView>();
    final today = context.read<HouseholdClock>().today;
    final permissions = view.permissions;
    final open = HouseholdPlace.openTo(
      view,
      context.watch<FeatureFlagsController>().flags,
    );
    final everyDay = [
      for (final tab in _everyDayTabs)
        if (tab.isOpenTo(permissions))
          HomeBoardTabTile(tab: tab, onTap: () => onOpenTab(tab)),
      if (open.contains(HouseholdPlace.stars))
        HouseholdPlaceTile(place: HouseholdPlace.stars, view: view),
    ];
    final family = [
      for (final place in _familyPlaces)
        if (open.contains(place)) HouseholdPlaceTile(place: place, view: view),
      NestPlaceTile(
        icon: LucideIcons.settings,
        tint: NestTileTint.lilac,
        title: HomeBoardCopy.peopleTitle,
        subtitle: HomeBoardCopy.peopleBody,
        onTap: () => onOpenTab(HouseholdTab.more),
      ),
    ];

    return NestScaffold(
      eyebrow: NestDates.full(today, today),
      title: view.household.name,
      trailing: const [
        HomeLayoutButton(),
        TourAnchor(target: TourTarget.bell, child: NotificationBell()),
        TourAnchor(target: TourTarget.accountMenu, child: AccountMenuButton()),
      ],
      body: ListView(
        padding: const EdgeInsets.only(bottom: NestSpace.huge),
        children: [
          if (everyDay.isNotEmpty)
            NestRiseIn(child: NestPlaceGrid(children: everyDay)),
          const SizedBox(height: NestSpace.xxl),
          if (permissions.canUse(HouseholdArea.calendar))
            NestRiseIn(
              index: 1,
              child: TodayAgendaSection(
                onOpen: () => onOpenTab(HouseholdTab.week),
              ),
            ),
          NestRiseIn(
            index: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const NestSectionHeader(title: HomeBoardCopy.sectionFamily),
                const SizedBox(height: NestSpace.md),
                NestPlaceGrid(children: family),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

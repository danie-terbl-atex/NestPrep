import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/household_shell.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/household_clock.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../../notifications/ui/notification_bell.dart';
import '../../welcome_tour/model/tour_target.dart';
import '../../welcome_tour/ui/tour_anchor.dart';
import 'home_layout_button.dart';
import 'today_agenda_section.dart';
import 'today_attention_card.dart';
import 'today_lists_section.dart';
import 'today_lunch_section.dart';

/// The household's home (design-system ADR-0009): the day at a glance, the
/// calendar first (ADR-0017), each section a door into the tab that owns it,
/// and only the sections this person's grant opens.
class TodayScreen extends StatelessWidget {
  const TodayScreen({required this.onSelectTab, super.key});

  final ValueChanged<HouseholdTab> onSelectTab;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final view = context.watch<HouseholdView>();
    final clock = context.read<HouseholdClock>();
    final permissions = view.permissions;
    final today = clock.today;
    final firstName = view.viewerMember?.displayName.split(' ').first;
    // The calendar leads, because the family's day is its events; the
    // lunches follow the to-dos as a row a child (design-system ADR-0017).
    final sections = [
      if (permissions.canUse(HouseholdArea.calendar))
        TodayAgendaSection(onOpen: () => onSelectTab(HouseholdTab.week)),
      if (permissions.canUse(HouseholdArea.todos))
        TodayTodoSection(onOpen: () => onSelectTab(HouseholdTab.todos)),
      if (permissions.canUse(HouseholdArea.lunch))
        TourAnchor(
          target: TourTarget.todayLunch,
          child: TodayLunchSection(
            onOpen: () => onSelectTab(HouseholdTab.lunch),
          ),
        ),
      if (permissions.canUse(HouseholdArea.groceries))
        TodayGrocerySection(onOpen: () => onSelectTab(HouseholdTab.groceries)),
    ];

    return NestScaffold(
      leading: const NestBrandLockup(semanticsLabel: AppCopy.appName),
      trailing: const [
        HomeLayoutButton(),
        TourAnchor(target: TourTarget.bell, child: NotificationBell()),
        TourAnchor(target: TourTarget.accountMenu, child: AccountMenuButton()),
      ],
      bottomBar: HouseholdTabBar(
        current: HouseholdTab.today,
        onSelect: onSelectTab,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: NestSize.bottomBarHeight * 2),
        children: [
          NestRiseIn(child: NestEyebrow(NestDates.full(today, today))),
          const SizedBox(height: NestSpace.xs),
          NestRiseIn(
            index: 1,
            child: Text(
              TodayCopy.greeting(clock.minutesOfDay(clock.now), firstName),
              style: nest.text.display,
            ),
          ),
          const SizedBox(height: NestSpace.xxl),
          const NestRiseIn(index: 2, child: TodayAttentionCard()),
          if (sections.isEmpty)
            NestEmptyView(
              icon: LucideIcons.layoutGrid,
              title: TodayCopy.nothingHere,
              message: TodayCopy.nothingHereBody,
              actionLabel: TodayCopy.openMore,
              onAction: () => onSelectTab(HouseholdTab.more),
            ),
          for (final (index, section) in sections.indexed)
            NestRiseIn(index: index + 3, child: section),
        ],
      ),
    );
  }
}

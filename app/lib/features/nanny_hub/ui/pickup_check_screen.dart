import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/nanny_hub_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/household_clock.dart';
import '../model/contact_kind.dart';
import '../model/pickup_collector.dart';
import '../model/pickup_plan.dart';
import '../state/nanny_hub_controller.dart';
import 'allowed_person_card.dart';
import 'collector_avatar.dart';
import 'collector_look.dart';
import 'do_not_release_card.dart';
import 'nanny_hub_screen.dart';
import 'pickup_page.dart';

/// "Who is at the door?" for one child (nanny-hub ADR-0005): every adult a
/// parent said may collect them, photo first, today's expected one on top —
/// and, always on screen, what to do when the person at the door is not
/// here. A child nobody is listed for shows only that.
class PickupCheckScreen extends StatelessWidget {
  const PickupCheckScreen({required this.childId, super.key});

  final String childId;

  @override
  Widget build(BuildContext context) => PickupPage(
    title: NannyPickupCopy.checkTitle,
    trailing: const [EmergencyLinkButton()],
    isEmpty: (view) => view.hub.childById(childId) == null,
    emptyBuilder: (_) => const NestEmptyView(
      title: NannyPickupCopy.childGoneTitle,
      message: NannyPickupCopy.childGoneBody,
      icon: Icons.person_off_outlined,
    ),
    builder: (context, view) => _CheckBody(view: view, childId: childId),
  );
}

class _CheckBody extends StatelessWidget {
  const _CheckBody({required this.view, required this.childId});

  final PickupView view;
  final String childId;

  static String _expected(PickupPlan plan) => switch (plan.atMinute) {
    final minute? => NannyPickupCopy.expectedAt(NestDates.timeOfDay(minute)),
    null => NannyPickupCopy.expectedToday,
  };

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final hub = context.read<NannyHubController>();
    final child = view.hub.childById(childId)!.member;
    final pickups = view.pickups;
    final plan = pickups.planFor(childId, context.read<HouseholdClock>().today);
    final collector = plan?.collector;
    final allowed = pickups.allowedFor(childId);
    final expectedFirst = [
      ...allowed.where((person) => person.id == collector?.personId),
      ...allowed.where((person) => person.id != collector?.personId),
    ];
    final parents = [
      for (final contact in view.hub.hub.contacts)
        if (contact.kind == ContactKind.parent) contact,
    ];
    final sections = <Widget>[
      Text(
        NannyPickupCopy.checkIntro(child.displayName),
        style: nest.text.bodyStrong,
      ),
      if (plan != null && collector is CollectedByMember)
        _ExpectedMember(
          look: lookOfCollector(
            collector,
            pickups: pickups,
            memberById: hub.memberById,
          ),
          label: _expected(plan),
        ),
      for (final person in expectedFirst)
        AllowedPersonCard(
          key: ValueKey(person.id),
          person: person,
          expectedLabel: plan != null && person.id == collector?.personId
              ? _expected(plan)
              : null,
          onCall: switch (person.dialLink) {
            final link? => () => hub.call(link),
            null => null,
          },
        ),
    ];
    final doNotRelease = DoNotReleaseCard(
      childName: child.displayName,
      size: allowed.isEmpty ? DoNotReleaseSize.full : DoNotReleaseSize.pinned,
      parents: parents,
      onCall: (parent) => hub.call(parent.dialLink),
      onOpenEmergency: () =>
          context.push(NannyHubRoute.emergencyPathFor(hub.householdId)),
    );
    // Nobody listed: the rule is the whole screen. Otherwise it is pinned
    // under the people, so it never scrolls out of sight at the door.
    if (allowed.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(bottom: NestSpace.huge),
        children: [NestRiseIn(child: doNotRelease)],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: NestSpace.lg),
              children: [
                for (final (index, section) in sections.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: NestSpace.lg),
                    child: NestRiseIn(index: index, child: section),
                  ),
              ],
            ),
          ),
          // At most half the screen, however large the text: the people
          // above stay reachable, and the rule scrolls within its own half.
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: constraints.maxHeight / 2),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: NestSpace.lg),
              child: doNotRelease,
            ),
          ),
        ],
      ),
    );
  }
}

/// Today's collector is one of the household — the carer, a parent — who
/// has no card here, so they are named on their own.
class _ExpectedMember extends StatelessWidget {
  const _ExpectedMember({required this.look, required this.label});

  final CollectorLook look;
  final String label;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return NestCard(
      variant: NestCardVariant.tinted,
      child: Row(
        children: [
          CollectorAvatar(look: look),
          const SizedBox(width: NestSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: nest.text.label),
                Text(look.name, style: nest.text.title),
                if (look.detail case final detail?)
                  Text(detail, style: nest.text.bodySecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

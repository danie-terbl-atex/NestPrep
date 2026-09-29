import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/nanny_hub_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/household_clock.dart';
import '../../household/model/household_view.dart';
import '../../household/model/member.dart';
import '../../household/model/member_role.dart';
import '../model/pickup_change.dart';
import '../model/pickup_person.dart';
import '../state/nanny_hub_controller.dart';
import '../state/pickup_controller.dart';
import 'collector_look.dart';
import 'nanny_hub_screen.dart';
import 'pickup_change_sheet.dart';
import 'pickup_changes_section.dart';
import 'pickup_page.dart';
import 'pickup_people_section.dart';
import 'pickup_person_sheet.dart';
import 'school_run_sheet.dart';
import 'school_run_week.dart';
import 'today_pickup_card.dart';

/// The school run and who may collect (nanny-hub ADR-0005): today first,
/// child by child, with the big way into the door check; then who may
/// collect, the usual week, and the days that differ. Family edits each part
/// from its own corner; everybody else reads.
class PickupsScreen extends StatelessWidget {
  const PickupsScreen({super.key});

  @override
  Widget build(BuildContext context) => PickupPage(
    title: NannyPickupCopy.title,
    trailing: const [EmergencyLinkButton()],
    builder: (context, view) => _PickupsBody(view: view),
  );
}

class _PickupsBody extends StatelessWidget {
  const _PickupsBody({required this.view});

  final PickupView view;

  List<Member> get _children => [
    for (final child in view.hub.children) child.member,
  ];

  /// The household's grown-ups who could do a school run themselves.
  List<Member> _adults(BuildContext context) {
    final childIds = {for (final child in _children) child.id};
    return [
      for (final member in context.read<HouseholdView>().members)
        if (member.role != MemberRole.kid && !childIds.contains(member.id))
          member,
    ];
  }

  Future<void> _editPerson(
    BuildContext context, {
    PickupPerson? existing,
  }) async {
    final pickups = context.read<PickupController>();
    final outcome = await showPickupPersonSheet(
      context: context,
      children: _children,
      onPick: context.read<NannyHubController>().pickPhoto,
      existing: existing,
    );
    if (outcome == null) return;
    if (existing != null && outcome.isRemoval) {
      await pickups.removePerson(existing);
      return;
    }
    await pickups.savePerson(
      outcome.draft,
      personId: existing?.id,
      photo: outcome.photo,
      currentPhotoId: existing?.photoId,
    );
  }

  Future<void> _editRun(BuildContext context, Member child, int weekday) async {
    final pickups = context.read<PickupController>();
    final outcome = await showSchoolRunSheet(
      context: context,
      child: child,
      weekday: weekday,
      people: view.pickups.allowedFor(child.id),
      adults: _adults(context),
      existing: view.pickups.runFor(child.id, weekday),
    );
    if (outcome == null) return;
    if (outcome.isRemoval) {
      await pickups.removeRun(child.id, weekday);
    } else {
      await pickups.saveRun(outcome.draft);
    }
  }

  Future<void> _editChange(
    BuildContext context, {
    PickupChange? existing,
  }) async {
    final pickups = context.read<PickupController>();
    final outcome = await showPickupChangeSheet(
      context: context,
      children: _children,
      adults: _adults(context),
      pickups: view.pickups,
      today: context.read<HouseholdClock>().today,
      existing: existing,
    );
    if (outcome == null) return;
    if (existing != null && outcome.isRemoval) {
      await pickups.removeChange(existing);
    } else {
      await pickups.saveChange(outcome.draft);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final hub = context.read<NannyHubController>();
    final canEdit = context.watch<PickupController>().canEdit;
    final today = context.read<HouseholdClock>().today;
    final householdId = hub.householdId;
    final pickups = view.pickups;
    final sections = <Widget>[
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NestSectionHeader(title: NannyPickupCopy.today),
          Text(
            NannyPickupCopy.todayOn(NestDates.full(today, today)),
            style: nest.text.bodySecondary,
          ),
          if (_children.isEmpty) ...[
            const SizedBox(height: NestSpace.sm),
            Text(NannyPickupCopy.noChildren, style: nest.text.bodySecondary),
          ],
          for (final child in _children) ...[
            const SizedBox(height: NestSpace.md),
            TodayPickupCard(
              key: ValueKey('today/${child.id}'),
              child: child,
              plan: pickups.planFor(child.id, today),
              look: switch (pickups.planFor(child.id, today)) {
                final plan? => lookOfCollector(
                  plan.collector,
                  pickups: pickups,
                  memberById: hub.memberById,
                ),
                null => null,
              },
              onCheck: () => context.push(
                NannyHubRoute.pickupCheckPathFor(householdId, child.id),
              ),
            ),
          ],
        ],
      ),
      PickupPeopleSection(
        children: _children,
        pickups: pickups,
        onAdd: canEdit ? () => _editPerson(context) : null,
        onEdit: canEdit
            ? (person) => _editPerson(context, existing: person)
            : null,
      ),
      SchoolRunWeek(
        children: _children,
        pickups: pickups,
        memberById: hub.memberById,
        onEdit: canEdit
            ? (child, weekday) => _editRun(context, child, weekday)
            : null,
      ),
      PickupChangesSection(
        pickups: pickups,
        today: today,
        memberById: hub.memberById,
        onAdd: canEdit && _children.isNotEmpty
            ? () => _editChange(context)
            : null,
        onEdit: canEdit
            ? (change) => _editChange(context, existing: change)
            : null,
      ),
    ];
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        for (final (index, section) in sections.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.xl),
            child: NestRiseIn(index: index, child: section),
          ),
      ],
    );
  }
}

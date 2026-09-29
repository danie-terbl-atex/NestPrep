import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/family_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../model/family_entry.dart';
import '../model/family_roster.dart';
import '../state/family_controller.dart';
import 'family_member_card.dart';
import 'school_flows.dart';
import 'schools_card.dart';

/// The family list: children, then everyone else, then the schools. Each card
/// arrives once, in reading order, and the list comes to rest (design-system
/// ADR-0002).
class FamilyList extends StatelessWidget {
  const FamilyList({required this.roster, required this.controller, super.key});

  final FamilyRoster roster;
  final FamilyController controller;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final today = context.read<HouseholdClock>().today;
    final canManageSchools = controller.access.canManageSchools;
    final children = roster.children;
    final others = roster.everyoneElse;
    // One arrival order across both groups, so the list arrives top-down.
    Widget arriving(FamilyEntry entry, int index) => _ArrivingCard(
      key: ValueKey(entry.memberId),
      entry: entry,
      index: index,
      age: entry.member.birthday?.ageOn(today),
      householdId: controller.householdId,
    );

    return ListView(
      children: [
        const NestSectionHeader(title: FamilyCopy.children),
        const SizedBox(height: NestSpace.sm),
        if (children.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.md),
            child: NestCard(
              variant: NestCardVariant.tinted,
              child: Text(
                FamilyCopy.noChildrenYet,
                style: nest.text.bodySecondary,
              ),
            ),
          ),
        for (final (index, entry) in children.indexed) arriving(entry, index),
        if (others.isNotEmpty) ...[
          const SizedBox(height: NestSpace.md),
          const NestSectionHeader(title: FamilyCopy.everyoneElse),
          const SizedBox(height: NestSpace.sm),
          for (final (index, entry) in others.indexed)
            arriving(entry, children.length + index),
        ],
        if (canManageSchools || roster.schools.isNotEmpty) ...[
          const SizedBox(height: NestSpace.md),
          SchoolsCard(
            schools: roster.schools,
            onAdd: canManageSchools
                ? () => addSchoolFlow(context, controller)
                : null,
            onEdit: canManageSchools
                ? (school) => editSchoolFlow(
                    context,
                    controller,
                    school: school,
                    pupils: roster.pupilsAt(school.id),
                  )
                : null,
          ),
        ],
        const SizedBox(height: NestSpace.lg),
        Text(
          FamilyCopy.privacyNote,
          style: nest.text.caption,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: NestSpace.huge),
      ],
    );
  }
}

class _ArrivingCard extends StatelessWidget {
  const _ArrivingCard({
    required this.entry,
    required this.index,
    required this.age,
    required this.householdId,
    super.key,
  });

  final FamilyEntry entry;
  final int index;
  final int? age;
  final String householdId;

  @override
  Widget build(BuildContext context) {
    return NestRiseIn(
      index: index,
      child: Padding(
        padding: const EdgeInsets.only(bottom: NestSpace.md),
        child: FamilyMemberCard(
          entry: entry,
          age: age,
          onTap: () => context.push(
            FamilyRoute.memberPathFor(householdId, entry.memberId),
          ),
        ),
      ),
    );
  }
}

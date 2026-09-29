import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../model/family_entry.dart';
import '../model/family_roster.dart';
import '../state/family_controller.dart';
import '../state/member_health_controller.dart';
import 'allergy_section.dart';
import 'family_profile_header.dart';
import 'food_rules_summary.dart';
import 'food_section.dart';
import 'medication_section.dart';
import 'profile_edit_flows.dart';
import 'school_section.dart';
import 'sizes_section.dart';

/// The sections of one profile, in the order a carer needs them: who, what
/// they must not eat, what they eat, medication, school, sizes. Every edit
/// button is absent — not disabled — for a viewer the rules would refuse
/// (`FE-04`).
class FamilyMemberBody extends StatelessWidget {
  const FamilyMemberBody({
    required this.entry,
    required this.roster,
    required this.family,
    required this.health,
    super.key,
  });

  final FamilyEntry entry;
  final FamilyRoster roster;
  final FamilyController family;
  final MemberHealthController health;

  bool get _hasRoomForMedication => switch (health.health) {
    AsyncData(:final value) => value.canAddMedication,
    _ => false,
  };

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final today = context.read<HouseholdClock>().today;
    final access = family.access;
    final canEdit = access.canEdit(entry.memberId);
    final canEditHealth = access.canEditHealth(entry.memberId);
    final profile = entry.profile;
    final flows = ProfileEditFlows(
      family: family,
      health: health,
      entry: entry,
      roster: roster,
    );
    const gap = SizedBox(height: NestSpace.lg);
    final showsRules =
        entry.foodRules.hasSevereAllergy || entry.foodRules.isNutFree;
    return ListView(
      children: [
        FamilyProfileHeader(
          entry: entry,
          age: entry.member.birthday?.ageOn(today),
          onToggleChild: canEdit ? flows.toggleChild : null,
        ),
        gap,
        if (showsRules) ...[FoodRulesSummary(rules: entry.foodRules), gap],
        AllergySection(
          allergies: entry.foodRules.allergies,
          onAdd: canEdit ? () => flows.addAllergy(context) : null,
          onEdit: canEdit
              ? (allergy) => flows.editAllergy(context, allergy)
              : null,
        ),
        gap,
        FoodSection(
          likes: profile.likes,
          dislikes: profile.dislikes,
          diet: profile.diet,
          onEdit: canEdit ? () => flows.editFood(context) : null,
        ),
        gap,
        MedicationSection(
          isVisible: health.isVisible,
          health: health.health,
          onRetry: health.retry,
          onAdd: canEditHealth && _hasRoomForMedication
              ? () => flows.addMedication(context)
              : null,
          onEdit: canEditHealth
              ? (id, medication) =>
                    flows.editMedication(context, id, medication)
              : null,
        ),
        gap,
        SchoolSection(
          school: entry.school,
          grade: profile.grade,
          onEdit: canEdit ? () => flows.editSchooling(context) : null,
        ),
        gap,
        SizesSection(
          clothingSize: profile.clothingSize,
          shoeSize: profile.shoeSize,
          onEdit: canEdit ? () => flows.editSizes(context) : null,
        ),
        gap,
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

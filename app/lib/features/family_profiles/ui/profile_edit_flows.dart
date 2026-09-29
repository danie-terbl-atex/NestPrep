import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/allergy.dart';
import '../model/family_entry.dart';
import '../model/family_roster.dart';
import '../model/medication.dart';
import '../state/family_controller.dart';
import '../state/member_health_controller.dart';
import 'allergy_sheet.dart';
import 'food_sheet.dart';
import 'medication_sheet.dart';
import 'school_flows.dart';
import 'schooling_sheet.dart';
import 'sheet_outcome.dart';
import 'sizes_sheet.dart';

/// What each edit button on a profile does: open its sheet, and hand what came
/// back to the controller that owns the write. The screen only wires buttons
/// to these (`FE-01`); the sheets only collect (`FE-03`).
final class ProfileEditFlows {
  const ProfileEditFlows({
    required this.family,
    required this.health,
    required this.entry,
    required this.roster,
  });

  final FamilyController family;
  final MemberHealthController health;
  final FamilyEntry entry;
  final FamilyRoster roster;

  String get _memberId => entry.memberId;

  Future<void> toggleChild() =>
      family.edit.setIsChild(_memberId, isChild: !entry.isChild);

  Future<void> addAllergy(BuildContext context) => editAllergy(context, null);

  Future<void> editAllergy(BuildContext context, Allergy? existing) async {
    final outcome = await showAllergySheet(
      context: context,
      existing: existing,
      taken: entry.foodRules.allergens,
      canAddOther: entry.profile.canAddOtherAllergy,
    );
    switch (outcome) {
      case null:
        return;
      case SheetSaved(:final value):
        await family.edit.saveAllergy(_memberId, value, replacing: existing);
      case SheetRemoved():
        if (existing == null || !context.mounted) return;
        final confirmed = await showNestConfirm(
          context: context,
          title: FamilyCopy.removeAllergyConfirm,
          confirmLabel: FamilyCopy.remove,
          cancelLabel: FamilyCopy.cancel,
          isDangerous: true,
        );
        if (confirmed != true) return;
        await family.edit.removeAllergy(_memberId, existing);
    }
  }

  Future<void> editFood(BuildContext context) async {
    final draft = await showFoodSheet(context: context, profile: entry.profile);
    if (draft == null) return;
    await family.edit.saveFood(
      _memberId,
      likes: draft.likes,
      dislikes: draft.dislikes,
      diet: draft.diet,
    );
  }

  Future<void> editSchooling(BuildContext context) async {
    final draft = await showSchoolingSheet(
      context: context,
      profile: entry.profile,
      schools: roster.schools,
      onAddSchool: family.access.canManageSchools
          ? () => addSchoolFlow(context, family)
          : null,
    );
    if (draft == null) return;
    await family.edit.saveSchooling(
      _memberId,
      schoolId: draft.schoolId,
      grade: draft.grade,
    );
  }

  Future<void> editSizes(BuildContext context) async {
    final draft = await showSizesSheet(
      context: context,
      profile: entry.profile,
    );
    if (draft == null) return;
    await family.edit.saveSizes(
      _memberId,
      clothingSize: draft.clothingSize,
      shoeSize: draft.shoeSize,
    );
  }

  Future<void> addMedication(BuildContext context) =>
      editMedication(context, null, null);

  Future<void> editMedication(
    BuildContext context,
    String? medicationId,
    Medication? existing,
  ) async {
    final outcome = await showMedicationSheet(
      context: context,
      existing: existing,
    );
    switch (outcome) {
      case null:
        return;
      case SheetSaved(:final value):
        await health.saveMedication(value, medicationId: medicationId);
      case SheetRemoved():
        if (medicationId == null || !context.mounted) return;
        final confirmed = await showNestConfirm(
          context: context,
          title: FamilyCopy.removeMedicationConfirm,
          confirmLabel: FamilyCopy.remove,
          cancelLabel: FamilyCopy.cancel,
          isDangerous: true,
        );
        if (confirmed != true) return;
        await health.removeMedication(medicationId);
    }
  }
}

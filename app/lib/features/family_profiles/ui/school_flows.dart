import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/school.dart';
import '../state/family_controller.dart';
import 'school_sheet.dart';
import 'sheet_outcome.dart';

/// Adds a school through its sheet, and answers with it so whoever asked — the
/// schooling sheet — can choose it straight away. Null when the person backed
/// out or the write was refused (the refusal is already a banner).
Future<School?> addSchoolFlow(
  BuildContext context,
  FamilyController controller,
) async {
  final outcome = await showSchoolSheet(context: context);
  if (outcome is! SheetSaved<SchoolDraft>) return null;
  final draft = outcome.value;
  final id = await controller.edit.addSchool(
    name: draft.name,
    nutFree: draft.nutFree,
  );
  if (id == null) return null;
  return School(id: id, name: draft.name, nutFree: draft.nutFree);
}

/// Renames a school, changes its nut-free rule, or deletes it — asking first,
/// and saying how many people it is set for, because deleting it leaves them
/// with none.
Future<void> editSchoolFlow(
  BuildContext context,
  FamilyController controller, {
  required School school,
  required int pupils,
}) async {
  final outcome = await showSchoolSheet(context: context, existing: school);
  switch (outcome) {
    case null:
      return;
    case SheetSaved(:final value):
      await controller.edit.updateSchool(
        school.id,
        name: value.name,
        nutFree: value.nutFree,
      );
    case SheetRemoved():
      if (!context.mounted) return;
      final confirmed = await showNestConfirm(
        context: context,
        title: FamilyCopy.deleteSchoolConfirm,
        message: FamilyCopy.deleteSchoolBody(pupils),
        confirmLabel: FamilyCopy.deleteSchool,
        cancelLabel: FamilyCopy.cancel,
        isDangerous: true,
      );
      if (confirmed != true) return;
      await controller.edit.deleteSchool(school.id);
  }
}

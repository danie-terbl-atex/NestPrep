import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/allergy.dart';
import '../model/allergy_draft.dart';

/// The fields one allergy change merges into a profile — kept apart from the
/// repository so the decision it makes can be tested without Firestore.
///
/// One write both adds the new entry and deletes the one it replaces, so
/// changing peanuts to sesame, or a fixed allergen to a free-text one, never
/// leaves a moment with both or neither. Every field of the entry is written,
/// null included, because a merge keeps whatever it is not told about — a
/// cleared note would otherwise survive. `toJson` is called by hand because
/// Firestore never calls it (the nested-model lesson).
Map<String, Object?> allergyWriteFields({
  required AllergyDraft draft,
  required String Function() newOtherId,
  Allergy? replacing,
}) {
  final allergen = draft.allergen;
  final keptOtherId = replacing?.otherId;
  final otherId = allergen == null ? keptOtherId ?? newOtherId() : null;
  final allergies = <String, Object?>{
    if (replacing?.allergen case final old? when old != allergen)
      old.name: FieldValue.delete(),
    if (allergen != null) allergen.name: draft.detail.toJson(),
  };
  final others = <String, Object?>{
    if (keptOtherId != null && keptOtherId != otherId)
      keptOtherId: FieldValue.delete(),
    ?otherId: draft.asOther.toJson(),
  };
  return {
    if (allergies.isNotEmpty) 'allergies': allergies,
    if (others.isNotEmpty) 'otherAllergies': others,
  };
}

/// The fields that remove one allergy, whichever map it lives in.
Map<String, Object?> allergyRemovalFields(Allergy allergy) {
  final allergen = allergy.allergen;
  final otherId = allergy.otherId;
  return {
    if (allergen != null) 'allergies': {allergen.name: FieldValue.delete()},
    if (otherId != null) 'otherAllergies': {otherId: FieldValue.delete()},
  };
}

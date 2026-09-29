import 'nanny_limits.dart';
import 'pickup_drafts.dart';

/// Blank is nothing, surrounding space is not part of what was said, and past
/// [longest] is cut — the sheets already hold people to it as they type, so
/// this is the second line for a caller that did not (`FE-10`).
String? tidyText(String? text, int longest) {
  final trimmed = text?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed.length <= longest ? trimmed : trimmed.substring(0, longest);
}

/// A person as the rules will take them: trimmed, bounded, and at most
/// [NannyLimits.pickupChildren] children.
PickupPersonDraft tidyPerson(PickupPersonDraft draft) => (
  name: tidyText(draft.name, NannyLimits.pickupName) ?? '',
  relationship:
      tidyText(draft.relationship, NannyLimits.pickupRelationship) ?? '',
  idNote: tidyText(draft.idNote, NannyLimits.pickupIdNote),
  phone: tidyText(draft.phone, 20),
  childIds: draft.childIds.take(NannyLimits.pickupChildren).toSet(),
);

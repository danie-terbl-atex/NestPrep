import 'package:flutter/foundation.dart';

import '../../../shared/text/normalised_name.dart';
import '../../family_profiles/model/allergen.dart';
import 'lunch_item.dart';
import 'lunch_slot.dart';

/// What the item sheet collected: everything about a library item a person
/// types or ticks, and nothing the app stamps on it.
@immutable
class LunchItemDraft {
  const LunchItemDraft({
    required this.name,
    required this.slot,
    required this.allergens,
    this.prepAhead = false,
    this.prepNote,
  });

  factory LunchItemDraft.of(LunchItem item) => LunchItemDraft(
    name: item.name,
    slot: item.slot ?? LunchSlot.main,
    allergens: item.knownAllergens,
    prepAhead: item.prepAhead,
    prepNote: item.prepNote,
  );

  final String name;
  final LunchSlot slot;
  final Set<Allergen> allergens;
  final bool prepAhead;
  final String? prepNote;

  bool get isValid {
    final trimmed = name.trim();
    final note = prepNote?.trim() ?? '';
    return trimmed.isNotEmpty &&
        trimmed.length <= LunchItem.nameLimit &&
        (!prepAhead || note.length <= LunchItem.prepNoteLimit);
  }

  /// A new library item in [addedBy]'s name. The repository gives it an id.
  LunchItem toNewItem(String addedBy) => LunchItem.named(
    id: '',
    name: name,
    slot: slot,
    allergens: allergens,
    addedBy: addedBy,
    prepAhead: prepAhead,
    prepNote: prepAhead ? prepNote : null,
  );

  /// [item] changed to say what this draft says. Its slot stays: an item
  /// already in boxes is in their slot keys.
  LunchItem applyTo(LunchItem item) {
    final note = prepNote?.trim();
    return item.copyWith(
      name: name.trim(),
      nameKey: normalisedName(name),
      allergens: [
        for (final allergen in Allergen.values)
          if (allergens.contains(allergen)) allergen.name,
        // A code this build does not know stays on the item (`BE-10`).
        for (final code in item.allergens)
          if (Allergen.fromCode(code) == null) code,
      ],
      prepAhead: prepAhead,
      prepNote: prepAhead && note != null && note.isNotEmpty ? note : null,
    );
  }
}

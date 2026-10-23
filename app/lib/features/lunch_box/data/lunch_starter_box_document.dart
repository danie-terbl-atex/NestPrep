import '../../../shared/firestore/document_fields.dart';
import '../../../shared/firestore/parsed_document.dart';
import '../../family_profiles/model/allergen.dart';
import '../model/lunch_slot.dart';
import '../model/lunch_starter_box.dart';

/// `lunchStarterBoxes/{boxId}` as this build reads it (`ENG-09`, `BE-10`).
/// A compartment this build cannot read — an unknown slot or kind, a pick
/// without a name, an allergen code it does not know — is left out of the
/// box, never guessed at; a box left with no compartment, or not published,
/// is left out whole.
abstract final class LunchStarterBoxDocument {
  static const published = 'published';

  static ParsedDocument<LunchStarterBox> parse(
    String id,
    Map<String, Object?> data,
  ) {
    final name = DocumentFields.text(data['name']);
    if (name == null) return const RejectedDocument('name');
    if (data['status'] != published) return const RejectedDocument('status');
    final fields = data['picks'];
    if (fields is! Map<Object?, Object?>) {
      return const RejectedDocument('picks');
    }
    final picks = <LunchSlot, StarterBoxPick>{};
    final dropped = <String>[];
    for (final MapEntry(:key, :value) in fields.entries) {
      final slot = key is String ? LunchSlot.fromName(key) : null;
      final pick = _pick(value);
      if (slot == null || pick == null) {
        dropped.add('pick');
      } else {
        picks[slot] = pick;
      }
    }
    if (picks.isEmpty) return const RejectedDocument('picks');
    return ValidDocument(
      LunchStarterBox(
        id: id,
        name: name,
        blurb: DocumentFields.text(data['blurb']) ?? '',
        order: DocumentFields.whole(data['order']) ?? 0,
        picks: picks,
      ),
      dropped: dropped,
    );
  }

  static StarterBoxPick? _pick(Object? value) {
    if (value is! Map<Object?, Object?>) return null;
    final name = DocumentFields.text(value['name']);
    final allergens = Allergen.parseCodes(value['allergens']);
    if (name == null || allergens == null) return null;
    return switch ((value['kind'], value['recipeId'], value['seedKey'])) {
      ('recipe', final String recipeId, _) when recipeId.isNotEmpty =>
        RecipeBoxPick(recipeId: recipeId, name: name, allergens: allergens),
      ('quickPick', _, final String seedKey) when seedKey.isNotEmpty =>
        QuickBoxPick(seedKey: seedKey, name: name, allergens: allergens),
      _ => null,
    };
  }
}

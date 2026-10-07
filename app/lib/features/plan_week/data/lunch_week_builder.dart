import '../../lunch_box/model/lunch_week.dart';
import '../model/idea_search.dart';
import '../model/lunch_week_reply.dart';
import '../model/packing_preference.dart';

/// Asks the model to build the week from what the shop had (lunch-box
/// ADR-0012, step 4). Behind an interface so a test decides what comes back
/// without Functions (`FE-20`).
///
/// It writes nothing. The phone sends only what it found — product ids,
/// names, prices, the allergen codes NestPrep read and whether anything was
/// known, and the brief's packing choices — never the area, and never anything about a child. Refusals arrive
/// as `LunchIdeaDrafter`'s do.
abstract interface class LunchWeekBuilder {
  Future<LunchWeekReply> build({
    required String householdId,
    required LunchWeek week,
    required Set<String> childIds,
    required List<IdeaSearch> searches,
    required PackingChoice packing,
  });
}

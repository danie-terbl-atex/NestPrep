import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../family_profiles/model/food_rules.dart';
import '../../lunch_box/model/lunch_board.dart';
import '../../lunch_box/model/lunch_slot.dart';
import '../../lunch_box/model/lunch_week.dart';
import '../data/lunch_idea_drafter.dart';
import '../model/idea_search.dart';
import '../model/lunch_idea.dart';
import '../model/plan_fallback.dart';
import '../model/usual_ideas.dart';

/// The ideas step's answer: the list, and who made it.
typedef IdeaList = ({
  List<LunchIdea> ideas,
  PlanSource source,
  PlanFallbackReason? reason,
  int? callsLeft,
});

/// Step 2 of *Plan my week* (lunch-box ADR-0012): the lunchbox aisle's
/// shelves (ADR-0013), then the model's ideas for what they lack, already
/// struck out per child by the server — or, when it cannot help, the
/// household's own usuals, said so — and the parent's edits to the list.
final class PlanWeekIdeas {
  PlanWeekIdeas({required this._drafter, required this.onChange});

  final LunchIdeaDrafter _drafter;
  final void Function() onChange;

  AsyncState<IdeaList> _state = const AsyncLoading();
  var _ownIdeas = 0;
  var _generation = 0;

  AsyncState<IdeaList> get state => _state;

  /// Ideas still for a child, in the order they are searched.
  List<LunchIdea> get active => switch (_state) {
    AsyncData(:final value) => [
      for (final idea in value.ideas)
        if (!idea.isStruckOut) idea,
    ],
    _ => const [],
  };

  Future<void> draft({
    required String householdId,
    required LunchWeek week,
    required LunchBoard board,
    required Set<String> childIds,
    List<IdeaSearch> aisle = const [],
    List<AisleShelfNames> aisleForModel = const [],
  }) async {
    final generation = ++_generation;
    final shelves = [for (final shelf in aisle) shelf.idea];
    _state = const AsyncLoading();
    onChange();
    AsyncState<IdeaList> next;
    try {
      final reply = await _drafter.draft(
        householdId: householdId,
        week: week,
        childIds: childIds,
        aisle: aisleForModel,
      );
      next = AsyncData((
        ideas: [
          ...shelves,
          for (final idea in reply.ideas) _keptTo(idea, childIds),
        ],
        source: PlanSource.ai,
        reason: null,
        callsLeft: reply.callsLeft,
      ));
    } on AppFailure catch (failure) {
      final reason = PlanFallbackReason.of(failure);
      next = reason == null
          ? AsyncFailure(failure)
          : AsyncData((
              ideas: [...shelves, ...UsualIdeas.from(board, childIds)],
              source: PlanSource.fallback,
              reason: reason,
              callsLeft: null,
            ));
    }
    if (generation != _generation) return;
    _state = next;
    onChange();
  }

  void remove(String ideaId) => _edit(
    (ideas) => [
      for (final idea in ideas)
        if (idea.id != ideaId) idea,
    ],
  );

  /// A parent's own idea, checked on the phone against each chosen child.
  void addOwn(LunchSlot slot, String text, Map<String, FoodRules> rules) {
    final idea = text.trim();
    if (idea.isEmpty || idea.length > LunchIdea.textLimit) return;
    _edit(
      (ideas) => [
        ...ideas,
        LunchIdea.checked(
          id: 'own-${++_ownIdeas}',
          slot: slot,
          idea: idea,
          rulesByChild: rules,
          origin: IdeaOrigin.own,
        ),
      ],
    );
  }

  /// Forgets the list; an answer still on its way is dropped.
  void clear() {
    _generation++;
    _state = const AsyncLoading();
  }

  void _edit(List<LunchIdea> Function(List<LunchIdea>) edit) {
    final state = _state;
    if (state is! AsyncData<IdeaList>) return;
    final list = state.value;
    _state = AsyncData((
      ideas: edit(list.ideas),
      source: list.source,
      reason: list.reason,
      callsLeft: list.callsLeft,
    ));
    onChange();
  }

  /// The server's idea, kept to the children chosen on this phone.
  static LunchIdea _keptTo(LunchIdea idea, Set<String> childIds) => LunchIdea(
    id: idea.id,
    slot: idea.slot,
    idea: idea.idea,
    searchTerm: idea.searchTerm,
    why: idea.why,
    childIds: idea.childIds.where(childIds.contains).toList(),
    excluded: idea.excluded,
    origin: idea.origin,
  );
}

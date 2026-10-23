import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/plan_week/model/lunch_idea.dart';
import 'package:nestprep/features/plan_week/model/lunch_ideas_reply.dart';
import 'package:nestprep/features/plan_week/model/lunch_week_reply.dart';

import 'checkers_fakes_for_plan_week.dart';
import 'lunch_fixtures.dart';
import 'plan_week_rig.dart';

/// One idea, one product and one AI-built lunch: the shortest *Plan my
/// week* that runs from the brief to done with the model answering every
/// step — for tests about who did the work rather than what it found.
extension PlanWeekOneIdea on PlanWeekRig {
  void stockOneIdeaWeek() {
    drafter.reply = LunchIdeasReply(
      ideas: [
        LunchIdea(
          id: 'idea-1',
          slot: LunchSlot.snack,
          idea: 'Fruit yoghurt',
          searchTerm: 'yoghurt',
          why: 'Lwazi eats yoghurt',
          childIds: const [LunchFixtures.lwaziId],
          excluded: const [],
          origin: IdeaOrigin.drafted,
        ),
      ],
      budgetCents: 30000,
      callsLeft: 12,
    );
    shop.byQuery['yoghurt'] = [
      planWeekProduct(
        'Fruit yoghurt 6 x 100g',
        id: 'yog',
        cents: 3600,
        packCount: 6,
        ingredients: 'Milk',
      ),
    ];
    builder.reply = LunchWeekReply(
      lunches: const [
        ReplyLunch(
          childId: LunchFixtures.lwaziId,
          day: 3,
          slot: LunchSlot.snack,
          ideaId: 'idea-1',
          productId: 'yog',
        ),
      ],
      boxesPerPack: const {'yog': 6},
      budgetCents: 30000,
      dropped: 0,
      callsLeft: 11,
    );
  }
}

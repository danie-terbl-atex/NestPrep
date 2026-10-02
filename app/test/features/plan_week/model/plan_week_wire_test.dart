import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/family_profiles/model/food_rules.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/plan_week/data/lunch_week_request.dart';
import 'package:nestprep/features/plan_week/model/checked_product.dart';
import 'package:nestprep/features/plan_week/model/idea_search.dart';
import 'package:nestprep/features/plan_week/model/left_out_reason.dart';
import 'package:nestprep/features/plan_week/model/lunch_idea.dart';
import 'package:nestprep/features/plan_week/model/lunch_ideas_reply.dart';
import 'package:nestprep/features/plan_week/model/lunch_week_reply.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/checkers_fakes_for_plan_week.dart';
import '../../../support/lunch_fixtures.dart';

/// The two callables' wire, as the contract in lunch-box ADR-0012 spells it:
/// replies parsed and never cast, a wrong shape an unreadable answer, and
/// what the phone sends kept within the contract's bounds.
void main() {
  const lwazi = LunchFixtures.lwaziId;
  const ayanda = LunchFixtures.ayandaId;

  group('draftLunchIdeas answers', () {
    test('ideas with their children and exclusions, the budget and the '
        'calls left', () {
      final reply = LunchIdeasReply.fromWire({
        'week': '2026-W40',
        'budgetCents': 45000,
        'callsLeft': 38,
        'ideas': [
          {
            'id': 'idea-1',
            'slot': 'snack',
            'idea': 'Peanut butter crackers',
            'searchTerm': 'peanut butter crackers',
            'why': 'child-2 likes crackers',
            'childIds': [ayanda],
            'excluded': [
              {'childId': lwazi, 'reason': 'allergy', 'allergen': 'peanut'},
            ],
          },
          {
            'id': 'idea-2',
            'slot': 'pudding',
            'idea': 'x',
            'searchTerm': 'x',
            'childIds': <Object?>[],
          },
          {
            'id': 'idea-3',
            'slot': 'fruit',
            'idea': 'Kiwi',
            'searchTerm': '',
            'childIds': <Object?>[],
            'excluded': [
              {'childId': lwazi, 'reason': 'allergy', 'allergen': null},
              {'childId': ayanda, 'reason': 'dislike', 'allergen': null},
            ],
          },
        ],
      });
      expect(reply.budgetCents, 45000);
      expect(reply.callsLeft, 38);
      expect([for (final idea in reply.ideas) idea.id], ['idea-1', 'idea-3']);
      final crackers = reply.ideas.first;
      expect(crackers.slot, LunchSlot.snack);
      expect(crackers.childIds, [ayanda]);
      expect(
        crackers.excluded.single,
        const LeftOutReason(
          LeftOutKind.allergy,
          childId: lwazi,
          allergen: Allergen.peanut,
        ),
      );
      final kiwi = reply.ideas.last;
      expect(kiwi.isStruckOut, isTrue);
      expect(kiwi.searchTerm, 'Kiwi');
      expect(
        [for (final r in kiwi.excluded) r.kind],
        [LeftOutKind.otherAllergy, LeftOutKind.dislike],
      );
    });

    test('a reply of the wrong shape is the AI unreadable', () {
      expect(
        () => LunchIdeasReply.fromWire({'lunches': <Object?>[]}),
        throwsA(isA<AiFailure>()),
      );
    });
  });

  group('buildLunchWeek answers', () {
    test('lunches and packs, a bad entry left out', () {
      final reply = LunchWeekReply.fromWire({
        'week': '2026-W40',
        'lunches': [
          {
            'childId': ayanda,
            'day': 5,
            'slot': 'treat',
            'ideaId': 'idea-4',
            'productId': 'p1',
          },
          {
            'childId': ayanda,
            'day': 6,
            'slot': 'main',
            'ideaId': 'idea-1',
            'productId': 'p2',
          },
        ],
        'packs': [
          {'productId': 'p1', 'boxesPerPack': 6},
          {'productId': 'p2', 'boxesPerPack': 0},
        ],
        'budgetCents': null,
        'dropped': 2,
        'callsLeft': 37,
      });
      expect(reply.lunches.single.slot, LunchSlot.treat);
      expect(reply.boxesPerPack, {'p1': 6});
      expect(reply.budgetCents, isNull);
      expect(reply.dropped, 2);
    });

    test('a reply of the wrong shape is the AI unreadable', () {
      expect(() => LunchWeekReply.fromWire('nope'), throwsA(isA<AiFailure>()));
    });
  });

  group('what the phone sends buildLunchWeek', () {
    final rules = <String, FoodRules>{
      lwazi: LunchFixtures.lwaziEntry.foodRules,
      ayanda: LunchFixtures.ayandaEntry.foodRules,
    };

    test('kept products only, six an idea, with what NestPrep read', () {
      final idea = LunchIdea.checked(
        id: 'idea-1',
        slot: LunchSlot.snack,
        idea: 'Yoghurt',
        rulesByChild: rules,
        origin: IdeaOrigin.drafted,
      );
      final found = [
        for (var index = 0; index < 8; index++)
          CheckedProduct.of(
            planWeekProduct(
              'Yoghurt $index ${'x' * 130}',
              id: 'y$index',
              ingredients: 'Milk',
              packCount: 6,
            ),
            rules,
          ),
        CheckedProduct.of(planWeekProduct('Gone', isInStock: false), rules),
      ];
      final wire = LunchWeekRequest.toWire(
        householdId: 'h1',
        week: LunchFixtures.week,
        childIds: {ayanda, lwazi},
        searches: [
          IdeaSearch(idea: idea, status: IdeaSearchStatus.done, found: found),
          IdeaSearch.waiting(idea),
        ],
      );
      expect(wire['week'], LunchFixtures.week.key);
      expect(wire['childIds'], [ayanda, lwazi]..sort());
      final ideas = wire['ideas']! as List<Object?>;
      expect(ideas, hasLength(1));
      final products =
          (ideas.single! as Map<String, Object?>)['products']! as List<Object?>;
      expect(products, hasLength(LunchWeekRequest.productLimit));
      final first = products.first! as Map<String, Object?>;
      expect((first['name']! as String).length, 120);
      expect(first['allergens'], ['milk']);
      expect(first['allergensKnown'], isTrue);
      expect(first['packQuantity'], 6);
      expect(first['priceCents'], 2500);
    });
  });
}

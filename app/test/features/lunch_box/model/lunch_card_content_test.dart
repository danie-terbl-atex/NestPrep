import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/family_profiles/model/family_profile.dart';
import 'package:nestprep/features/family_profiles/model/family_roster.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/features/lunch_box/model/lunch_board.dart';
import 'package:nestprep/features/lunch_box/model/lunch_card_content.dart';
import 'package:nestprep/features/lunch_box/model/lunch_card_naming.dart';
import 'package:nestprep/features/lunch_box/model/lunch_card_options.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';

import '../../../support/lunch_card_fixtures.dart';
import '../../../support/lunch_fixtures.dart';

/// What a shared card may carry (lunch-box ADR-0005): the week's food and
/// nothing about the child the parent did not choose, this time.
void main() {
  const lwazi = LunchCardOptions(childId: LunchFixtures.lwaziId);

  /// Every word the card could put in a picture.
  List<String> wordsOn(LunchCardContent content) => [
    ...content.itemNames,
    for (final child in content.children) ?child.label,
  ];

  group('the privacy default', () {
    test('names nobody: a child is their initial, never their name', () {
      final content = LunchCardFixtures.content(lwazi);
      expect(content.children.single.label, 'L');
      expect(content.children.single.isFirstName, isFalse);
      expect(wordsOn(content).join(' '), isNot(contains('Lwazi')));
    });

    test('carries no allergy, no nut rule and no school — even for a child '
        'with a severe peanut allergy at a nut-free school', () {
      final content = LunchCardFixtures.content(lwazi);
      final words = wordsOn(content).join(' ').toLowerCase();
      for (final never in ['peanut', 'nut-free', 'oakwood', 'allerg']) {
        expect(words, isNot(contains(never)));
      }
      final picks = [
        for (final day in content.children.single.days)
          for (final (_, pick) in day.box.filled) pick,
      ];
      expect(picks, hasLength(21));
      expect(picks.every((pick) => pick.allergens.isEmpty), isTrue);
    });

    test('a first name only when the parent chooses first names', () {
      final content = LunchCardFixtures.content(
        lwazi.copyWith(naming: LunchCardNaming.firstNames),
      );
      expect(content.children.single.label, 'Lwazi');
      expect(content.children.single.isFirstName, isTrue);
    });

    test('never a surname, even when the profile has one', () {
      final board = LunchBoard.from(
        week: LunchFixtures.week,
        today: LunchFixtures.today,
        roster: FamilyRoster(
          members: [
            LunchFixtures.lwazi.copyWith(displayName: 'Lwazi Dube'),
            LunchFixtures.ayanda,
          ],
          profiles: [LunchFixtures.lwaziProfile, LunchFixtures.ayandaProfile],
          schools: const [LunchFixtures.oakwood],
        ),
        library: LunchCardFixtures.library,
        favourites: const [],
        plans: [LunchCardFixtures.lwaziWeek],
      );
      final named = LunchCardContent.from(
        board,
        lwazi.copyWith(naming: LunchCardNaming.firstNames),
      );
      expect(named.children.single.label, 'Lwazi');
      expect(LunchCardContent.from(board, lwazi).children.single.label, 'LD');
    });

    test('no names at all leaves each child a number', () {
      final content = LunchCardFixtures.content(
        const LunchCardOptions(childId: null, naming: LunchCardNaming.none),
      );
      expect([for (final child in content.children) child.label], [null, null]);
      expect([for (final child in content.children) child.number], [1, 2]);
    });
  });

  group('what is on it', () {
    test('one child: their five school days, as the week packed them', () {
      final content = LunchCardFixtures.content(lwazi);
      final days = content.children.single.days;
      expect(content.isFamily, isFalse);
      expect(days, hasLength(5));
      expect(days.first.date, LunchFixtures.week.monday);
      expect(days.first.itemNames, [
        'Cheese rolls',
        'Naartjie',
        'Carrot sticks',
        'Biltong',
      ]);
      expect(days.last.box[LunchSlot.treat]?.name, 'Banana muffin');
    });

    test('an item is shown by the name the library gives it now', () {
      final renamed = [
        for (final item in LunchCardFixtures.library)
          item.seedKey == 'cheese-rolls'
              ? item.copyWith(name: 'Cheesy rolls')
              : item,
      ];
      final content = LunchCardContent.from(
        LunchCardFixtures.board(items: renamed),
        lwazi,
      );
      expect(
        content.children.single.days.first.itemNames.first,
        'Cheesy rolls',
      );
    });

    test('everyone: every child side by side, each thing named once', () {
      final content = LunchCardFixtures.content(
        const LunchCardOptions(childId: null),
      );
      expect(content.isFamily, isTrue);
      expect([for (final child in content.children) child.label], ['L', 'A']);
      expect(content.itemNames.where((name) => name == 'Carrot sticks'), [
        'Carrot sticks',
      ]);
      expect(content.itemNames.first, 'Cheese rolls');
    });

    test('a family card draws four children and counts the rest', () {
      final extra = [
        for (var index = 0; index < 4; index++)
          Member(
            id: 'm-extra-$index',
            displayName: 'Extra $index',
            color: MemberColor.values[index],
            roleName: 'kid',
          ),
      ];
      final board = LunchBoard.from(
        week: LunchFixtures.week,
        today: LunchFixtures.today,
        roster: FamilyRoster(
          members: [LunchFixtures.lwazi, LunchFixtures.ayanda, ...extra],
          profiles: [
            LunchFixtures.lwaziProfile,
            LunchFixtures.ayandaProfile,
            for (final member in extra)
              FamilyProfile(id: member.id, isChild: true),
          ],
          schools: const [LunchFixtures.oakwood],
        ),
        library: LunchCardFixtures.library,
        favourites: const [],
        plans: const [],
      );
      const everyone = LunchCardOptions(childId: null);
      final card = LunchCardContent.from(board, everyone);
      expect(card.children, hasLength(LunchCardContent.maxChildren));
      expect(card.hiddenChildCount, 2);
      final planner = LunchCardContent.from(board, everyone, limit: 6);
      expect(planner.children, hasLength(6));
      expect(planner.hiddenChildCount, 0);
    });

    test('a week with nothing packed is empty, and says so', () {
      final content = LunchCardContent.from(
        LunchCardFixtures.board(plans: const []),
        lwazi,
      );
      expect(content.isEmpty, isTrue);
      expect(content.itemNames, isEmpty);
      expect(LunchCardFixtures.content(lwazi).isEmpty, isFalse);
    });

    test('a child who is no longer on the board falls back to the first', () {
      final content = LunchCardFixtures.content(
        const LunchCardOptions(childId: 'm-gone'),
      );
      expect(content.children.single.label, 'L');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/avatars/model/avatar_buddy.dart';
import 'package:nestprep/features/avatars/model/avatar_catalogue.g.dart';
import 'package:nestprep/features/avatars/model/avatar_creation.dart';
import 'package:nestprep/features/avatars/model/avatar_keepsake.dart';
import 'package:nestprep/features/avatars/model/creation_allowance.dart';
import 'package:nestprep/features/avatars/ui/creation_refused_view.dart';
import 'package:nestprep/features/household/model/household.dart';
import 'package:nestprep/shared/copy/avatar_creation_copy.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:timezone/data/latest.dart' as tz_data;

void main() {
  const hash = '0123456789abcdef0123456789abcdef';
  final now = DateTime.utc(2026, 11, 13, 10);
  final clock = HouseholdClock('Africa/Johannesburg', now: () => now);

  setUpAll(tz_data.initializeTimeZones);

  AvatarCreation creation({int? left, DateTime? at, CreationRefusal? reason}) =>
      AvatarCreation(
        id: 'c',
        memberId: 'm',
        recipe: CreationRecipe.buddy,
        left: left,
        reason: reason,
        requestedAt: at ?? now,
      );

  group('a creation as the trigger writes it', () {
    test('reads its status, reason, picture and what is left', () {
      final read = AvatarCreation.fromFirestore('c1', {
        'memberId': 'm-kid',
        'recipe': 'drawing',
        'status': 'refused',
        'reason': 'limitReached',
        'imageHash': hash,
        'left': 0,
        'requestedAt': now,
      })!;
      expect(read.recipe, CreationRecipe.drawing);
      expect(read.status, CreationStatus.refused);
      expect(read.reason, CreationRefusal.limitReached);
      expect(read.left, 0);
      expect(read.isSettled, isTrue);
      expect(read.isReady, isFalse);
    });

    test('an unknown reason on a refusal is read as not allowed', () {
      final read = AvatarCreation.fromFirestore('c1', {
        'memberId': 'm',
        'recipe': 'pet',
        'status': 'refused',
        'reason': 'somethingNew',
      })!;
      expect(read.reason, CreationRefusal.notAllowed);
    });

    test('ready needs a well-formed picture', () {
      final read = AvatarCreation.fromFirestore('c1', {
        'memberId': 'm',
        'recipe': 'buddy',
        'status': 'ready',
        'imageHash': 'not-a-hash',
      })!;
      expect(read.isReady, isFalse);
    });

    test('an unknown recipe is no creation at all', () {
      expect(
        AvatarCreation.fromFirestore('c1', {'memberId': 'm', 'recipe': 'x'}),
        isNull,
      );
    });
  });

  group('a keepsake', () {
    test('keeps its original, style and chips', () {
      final keepsake = AvatarKeepsake.fromFirestore('k1', {
        'memberId': 'm',
        'recipe': 'buddy',
        'style': 'plush',
        'originalPath': null,
        'buddy': {'creature': 'dragon', 'colour': 'purple', 'loves': 'nope'},
        'imageHash': hash,
        'createdAt': now,
      })!;
      expect(keepsake.style, CreationStyle.plush);
      expect(keepsake.originalPath, isNull);
      expect(keepsake.buddy!.picks, {
        AvatarBuddyKind.creature: 'dragon',
        AvatarBuddyKind.colour: 'purple',
      });
    });

    test('a portrait has no style and is never worn', () {
      final keepsake = AvatarKeepsake.fromFirestore('k1', {
        'memberId': 'm',
        'recipe': 'portrait',
        'style': null,
        'imageHash': hash,
      })!;
      expect(keepsake.isPortrait, isTrue);
      expect(keepsake.style, isNull);
    });

    test('the shelf is newest first, a fresh one before the rest', () {
      AvatarKeepsake at(String id, DateTime? when) => AvatarKeepsake(
        id: id,
        memberId: 'm',
        recipe: CreationRecipe.pet,
        imageHash: hash,
        createdAt: when,
      );
      final shelf = [
        at('old', DateTime(2026, 2)),
        at('new', DateTime(2026, 11)),
        at('pending', null),
      ]..sort(AvatarKeepsake.newestFirst);
      expect(shelf.map((k) => k.id), ['pending', 'new', 'old']);
    });
  });

  group('what is left to make', () {
    test('a household that never asked is not told a count', () {
      expect(CreationAllowance.from(const [], clock: clock).left, isNull);
    });

    test('this month counts, the newest answer first', () {
      final allowance = CreationAllowance.from([
        creation(),
        creation(left: 8),
        creation(left: 9),
      ], clock: clock);
      expect(allowance.left, 8);
    });

    test('a refusal for Premium says nothing about the month', () {
      final allowance = CreationAllowance.from([
        creation(left: 0, reason: CreationRefusal.premiumRequired),
        creation(left: 8),
      ], clock: clock);
      expect(allowance.left, 8);
    });

    test('last month’s count says nothing about this month', () {
      final allowance = CreationAllowance.from([
        creation(left: 0, at: DateTime.utc(2026, 10, 30)),
      ], clock: clock);
      expect(allowance.left, isNull);
    });

    test('the month is the household’s, not the phone’s', () {
      final lastNight = DateTime.utc(2026, 11, 30, 5);
      final lateOnTheLast = DateTime.utc(2026, 11, 30, 23);
      CreationAllowance where(String zone) => CreationAllowance.from([
        creation(left: 0, at: lastNight),
      ], clock: HouseholdClock(zone, now: () => lateOnTheLast));
      expect(where('Africa/Johannesburg').left, isNull);
      expect(where('America/Sao_Paulo').left, 0);
    });

    test('tries used up this month leave nothing, whatever the count says', () {
      final allowance = CreationAllowance.from([
        creation(left: 7, reason: CreationRefusal.limitReached),
      ], clock: clock);
      expect(allowance.left, 0);
    });

    test('more come on the first of the month after today', () {
      expect(
        CreationRefusedView.nextMonthFrom(CalendarDate(2026, 11, 13)),
        '1 December',
      );
      expect(
        CreationRefusedView.nextMonthFrom(CalendarDate(2026, 12, 31)),
        '1 January',
      );
    });
  });

  group('the buddy, in words', () {
    test('reads like a sentence a child would say', () {
      const buddy = AvatarBuddy({
        AvatarBuddyKind.creature: 'dragon',
        AvatarBuddyKind.colour: 'purple',
        AvatarBuddyKind.loves: 'pancakes',
        AvatarBuddyKind.wears: 'cape',
        AvatarBuddyKind.power: 'flying',
      });
      expect(
        AvatarCreationCopy.buddySentence(buddy),
        'A purple dragon who loves pancakes, wears a cape and can fly',
      );
      expect(buddy.isComplete, isTrue);
    });

    test('builds as the chips are tapped, with the right article', () {
      expect(
        AvatarCreationCopy.buddySentence(const AvatarBuddy()),
        AvatarCreationCopy.buddyStart,
      );
      expect(
        AvatarCreationCopy.buddySentence(
          const AvatarBuddy({
            AvatarBuddyKind.colour: 'orange',
            AvatarBuddyKind.creature: 'octopus',
          }),
        ),
        'An orange octopus',
      );
      expect(
        AvatarCreationCopy.buddySentence(
          const AvatarBuddy({
            AvatarBuddyKind.creature: 'owl',
            AvatarBuddyKind.wears: 'glasses',
            AvatarBuddyKind.loves: 'beach',
          }),
        ),
        'An owl who loves the beach and wears glasses',
      );
    });

    test('every power in the catalogue has words of its own', () {
      for (final power in avatarBuddy[AvatarBuddyKind.power]!) {
        final sentence = AvatarCreationCopy.buddySentence(
          AvatarBuddy({AvatarBuddyKind.power: power.id}),
        );
        expect(sentence, isNot(contains('powers')), reason: power.id);
      }
    });
  });

  test('the household switch reads as on until somebody turns it off', () {
    final household = Household.fromJson(const {
      'id': 'h1',
      'name': 'Oak Street',
      'timeZone': 'Africa/Johannesburg',
    });
    expect(household.avatarCreationsOn, isTrue);
    expect(household.toJson(), isNot(contains('avatarCreationsOn')));
    expect(
      Household.fromJson(const {
        'id': 'h1',
        'name': 'Oak Street',
        'timeZone': 'Africa/Johannesburg',
        'avatarCreationsOn': false,
      }).avatarCreationsOn,
      isFalse,
    );
  });
}

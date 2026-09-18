import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/calendar/model/household_event.dart';
import 'package:nestprep/shared/audience/member_audience.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

/// "Nobody named means everybody" — the rule both todos and the calendar are
/// built on, and the one that had no test of its own.
///
/// It was written three times in the same words, and the copy on `Task` was
/// never called by anything, which is how coverage found it: 0 of 3 lines on a
/// model nine tests touch. A dead copy of a live rule is the one nobody fixes
/// when the rule changes.
void main() {
  group('an empty audience', () {
    test('is everybody', () {
      expect(MemberAudience.isEveryone(const []), isTrue);
    });

    test('includes whoever asks', () {
      // *Somebody take the bins out* is the task people most need reminding
      // of. A filter that dropped it would be wrong for exactly that one.
      expect(MemberAudience.includes(const [], 'm-anyone'), isTrue);
    });
  });

  group('a named audience', () {
    test('is not everybody', () {
      expect(MemberAudience.isEveryone(const ['m-sam']), isFalse);
    });

    test('includes the member it names', () {
      expect(MemberAudience.includes(const ['m-sam'], 'm-sam'), isTrue);
    });

    test('excludes a member it does not name', () {
      expect(MemberAudience.includes(const ['m-sam'], 'm-thandi'), isFalse);
    });

    test('includes any one of several', () {
      const both = ['m-sam', 'm-thandi'];
      expect(MemberAudience.includes(both, 'm-sam'), isTrue);
      expect(MemberAudience.includes(both, 'm-thandi'), isTrue);
      expect(MemberAudience.includes(both, 'm-kid'), isFalse);
    });

    test('does not match on a prefix', () {
      // Member ids are opaque; `contains` on a list is exact, and this pins it
      // so nobody rewrites it as a string search.
      expect(MemberAudience.includes(const ['m-sam'], 'm-sa'), isFalse);
      expect(MemberAudience.includes(const ['m-sam'], 'm-samuel'), isFalse);
    });
  });

  group('the models that share it', () {
    HouseholdEvent event({List<String> memberIds = const []}) => HouseholdEvent(
      id: 'e1',
      title: 'School run',
      date: CalendarDate(2026, 9, 21),
      memberIds: memberIds,
      createdBy: 'm-sam',
    );

    test('an event for nobody is for everybody', () {
      expect(event().isForEveryone, isTrue);
      expect(event().isFor('m-kid'), isTrue);
    });

    test('an event for one member is not for another', () {
      final theirs = event(memberIds: const ['m-kid']);
      expect(theirs.isForEveryone, isFalse);
      expect(theirs.isFor('m-kid'), isTrue);
      expect(theirs.isFor('m-sam'), isFalse);
    });
  });
}

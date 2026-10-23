import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The copy ratchet (`one_home_for_copy_test.dart`) for the two copy files
/// that sit beside `AppCopy` — calendar sync's and quick add's (calendar
/// ADR-0003, ADR-0004). Words nothing says are a capability stopped one layer
/// short of the screen, the same as they are in `AppCopy`.
void main() {
  final dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.path.endsWith('.g.dart'))
      .where((file) => !file.path.endsWith('.freezed.dart'))
      .toList();

  for (final (className, path) in [
    ('CalendarSyncCopy', 'lib/shared/copy/calendar_sync_copy.dart'),
    ('QuickAddCopy', 'lib/shared/copy/quick_add_copy.dart'),
    // todos phase 2: stars and rewards (todos ADR-0003).
    ('PointsCopy', 'lib/shared/copy/points_copy.dart'),
    // lunch-box phase 2: the shareable card (lunch-box ADR-0005).
    ('LunchShareCopy', 'lib/shared/copy/lunch_share_copy.dart'),
    // lunch-box V2 (lunch-box ADR-0006 to ADR-0008).
    ('LunchPlanningCopy', 'lib/shared/copy/lunch_planning_copy.dart'),
    ('LunchPantryCopy', 'lib/shared/copy/lunch_pantry_copy.dart'),
    ('LunchBudgetCopy', 'lib/shared/copy/lunch_budget_copy.dart'),
    ('LunchKidPicksCopy', 'lib/shared/copy/lunch_kid_picks_copy.dart'),
    // account data (accounts ADR-0006).
    ('AccountDataCopy', 'lib/shared/copy/account_data_copy.dart'),
    // notifications (notifications ADR-0001 to ADR-0003).
    ('NotificationsCopy', 'lib/shared/copy/notifications_copy.dart'),
  ]) {
    test('$className carries no words nothing says', () {
      final source = File(path).readAsStringSync();
      final names = RegExp(r'static (?:const|String) (\w+)')
          .allMatches(source)
          .map((match) => match.group(1)!)
          .toSet();
      expect(names, isNotEmpty);

      final unused = <String>{
        for (final name in names)
          if (!dartFiles.any((file) {
            final text = file.readAsStringSync();
            return file.path.endsWith(path.split('/').last)
                ? RegExp('\\b$name\\b').allMatches(text).length > 1
                : text.contains('$className.$name');
          }))
            name,
      };
      expect(unused, isEmpty, reason: 'wire it up, or do not write it yet');
    });
  }
}

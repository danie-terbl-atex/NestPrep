import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/shared/copy/app_copy.dart';

final addButton = find.byTooltip(AppCopy.todosAdd);

Finder addChoice(String label) => find.descendant(
  of: find.byType(NestActionMenu),
  matching: find.text(label),
);

Future<void> tapAdd(WidgetTester tester) async {
  await tester.tap(addButton);
  await tester.pumpAndSettle();
}

Future<void> addFromMenu(
  WidgetTester tester, [
  String choice = AppCopy.todosAddTask,
]) async {
  await tapAdd(tester);
  await tester.tap(addChoice(choice));
  await tester.pumpAndSettle();
}

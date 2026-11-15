import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';

/// A page opened from its photo still leaves by the iPhone's edge swipe,
/// keeps what was typed on it when the swipe is let go early, and is left
/// alone on Android, where there is no such swipe.
void main() {
  Future<void> openDetail(WidgetTester tester, TargetPlatform platform) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: platform),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                NestPhotoRoute<void>(
                  motion: NestMotion.of(context),
                  builder: (context) =>
                      const Scaffold(body: TextField(key: Key('note'))),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('note')), findsOneWidget);
  }

  Future<void> swipeFromTheEdge(WidgetTester tester, double distance) async {
    final gesture = await tester.startGesture(const Offset(4, 300));
    await gesture.moveBy(Offset(distance / 2, 0));
    await tester.pump();
    await gesture.moveBy(Offset(distance / 2, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('on iOS a swipe from the edge goes back', (tester) async {
    await openDetail(tester, TargetPlatform.iOS);
    await swipeFromTheEdge(tester, 600);

    expect(find.byKey(const Key('note')), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('a swipe let go early stays, with what was typed', (
    tester,
  ) async {
    await openDetail(tester, TargetPlatform.iOS);
    await tester.enterText(find.byKey(const Key('note')), 'peanut-free');
    await swipeFromTheEdge(tester, 60);

    expect(find.text('peanut-free'), findsOneWidget);
  });

  testWidgets('on Android the same drag does nothing', (tester) async {
    await openDetail(tester, TargetPlatform.android);
    await swipeFromTheEdge(tester, 600);

    expect(find.byKey(const Key('note')), findsOneWidget);
  });

  Future<void> openPager(WidgetTester tester, {required bool withEdge}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => Scaffold(
                    body: Stack(
                      fit: StackFit.expand,
                      children: [
                        PageView(
                          children: const [Text('first'), Text('second')],
                        ),
                        if (withEdge) const NestBackSwipeEdge(),
                      ],
                    ),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('a pager at the screen edge takes the swipe for itself', (
    tester,
  ) async {
    await openPager(tester, withEdge: false);
    await swipeFromTheEdge(tester, 600);

    expect(find.text('first'), findsOneWidget);
  });

  testWidgets('the edge strip gives the swipe back to the page', (
    tester,
  ) async {
    await openPager(tester, withEdge: true);
    await swipeFromTheEdge(tester, 600);

    expect(find.text('first'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('and leaves the rest of the pager to page as before', (
    tester,
  ) async {
    await openPager(tester, withEdge: true);
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(find.text('second'), findsOneWidget);
  });
}

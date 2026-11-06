import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/chore_points/state/kid_points_controller.dart';
import 'package:nestprep/features/kid_accounts/state/kid_home_controller.dart';
import 'package:nestprep/features/kid_accounts/ui/kid_chore_tile.dart';
import 'package:nestprep/features/kid_accounts/ui/kid_home_screen.dart';
import 'package:nestprep/features/todos/ui/chore_picture_view.dart';
import 'package:nestprep/shared/copy/kid_copy.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/kid_home_fixture.dart';
import '../../../support/pump_screen.dart';

/// A kid's chore wearing its picture (todos ADR-0005): big, leading the tile,
/// for a child who cannot read yet. The tile is still one button that says
/// done in words, and every tick sits at the end, pictured or not.
void main() {
  setUpAll(tz_data.initializeTimeZones);

  late KidHomeFixture fixture;

  setUp(() => fixture = KidHomeFixture());
  tearDown(() => fixture.close());

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) => pumpScreen(
    tester,
    const KidHomeScreen(),
    providers: [
      ChangeNotifierProvider<KidHomeController>.value(
        value: fixture.controller,
      ),
      ChangeNotifierProvider<KidPointsController>.value(value: fixture.stars),
    ],
    brightness: brightness,
    textScale: scale,
  );

  Finder tile(String title) =>
      find.ancestor(of: find.text(title), matching: find.byType(KidChoreTile));
  Finder picture(String id) => find.byKey(ValueKey('chore-picture-$id'));

  testWidgets('the picture leads the tile, and every tick is at the end', (
    tester,
  ) async {
    await pump(tester);
    await tester.runAsync(
      () => fixture.arrive(
        tasks: [
          KidHomeFixture.chore('teeth', 'Brush teeth', picture: 'brush-teeth'),
          KidHomeFixture.chore('call', 'Call Gran'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final pictured = tile('Brush teeth');
    final art = find.descendant(of: pictured, matching: picture('brush-teeth'));
    expect(art, findsOneWidget);
    expect(tester.getSize(art).width, NestSize.stickerLarge);
    final tick = find.descendant(
      of: pictured,
      matching: find.byType(AnimatedContainer),
    );
    expect(
      tester.getCenter(art).dx,
      lessThan(tester.getCenter(find.text('Brush teeth')).dx),
    );
    expect(
      tester.getCenter(tick).dx,
      greaterThan(tester.getCenter(find.text('Brush teeth')).dx),
    );

    final plain = tile('Call Gran');
    expect(
      find.descendant(of: plain, matching: find.byType(ChorePictureView)),
      findsNothing,
    );
    final plainTick = find.descendant(
      of: plain,
      matching: find.byType(AnimatedContainer),
    );
    expect(
      tester.getCenter(plainTick).dx,
      greaterThan(tester.getCenter(find.text('Call Gran')).dx),
    );
    expect(
      tester.getCenter(plainTick).dx,
      tester.getCenter(tick).dx,
      reason: 'the ticks form one column',
    );
    expect(
      tester.getTopLeft(find.text('Call Gran')).dx,
      lessThan(tester.getTopLeft(art).dx + NestSize.stickerLarge),
      reason: 'with no picture, the title leads',
    );
  });

  testWidgets('an id this build does not ship draws nothing', (tester) async {
    await pump(tester);
    await tester.runAsync(
      () => fixture.arrive(
        tasks: [
          KidHomeFixture.chore(
            'newer',
            'Feed the fish',
            picture: 'from-a-newer-build',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NestSticker), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tap on the picture ticks it; done fades it and says so', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    await tester.runAsync(
      () => fixture.arrive(
        tasks: [
          KidHomeFixture.chore('bed', 'Make your bed', picture: 'make-bed'),
          KidHomeFixture.chore('teeth', 'Brush teeth', picture: 'brush-teeth'),
        ],
        completions: [KidHomeFixture.done('teeth')],
      ),
    );
    await tester.pumpAndSettle();

    double opacity(String id) =>
        tester.widget<AnimatedOpacity>(picture(id)).opacity;
    expect(opacity('make-bed'), 1);
    expect(opacity('brush-teeth'), ChorePictureView.fadedOpacity);
    expect(
      tester.getSemantics(tile('Brush teeth')),
      isSemantics(
        label: 'Brush teeth, ${KidCopy.choreDone}',
        isButton: true,
        isChecked: true,
        hasCheckedState: true,
      ),
    );

    await tester.tap(picture('make-bed'));
    await tester.pump();
    expect(fixture.todos.completed.single.taskId, 'bed');
    await tester.pumpAndSettle();
    semantics.dispose();
  });

  testWidgets('the celebration shows the chore"s picture', (tester) async {
    await pump(tester);
    await tester.runAsync(
      () => fixture.arrive(
        tasks: [
          KidHomeFixture.chore('bed', 'Make your bed', picture: 'make-bed'),
          KidHomeFixture.chore('teeth', 'Brush teeth'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Make your bed'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(KidCopy.wellDone('Kid')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(NestCelebration),
        matching: picture('make-bed'),
      ),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
  });

  testWidgets('pictured chores survive dark at 200% text, 360 wide', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, brightness: Brightness.dark, scale: 2);
    await tester.runAsync(
      () => fixture.arrive(
        tasks: [
          KidHomeFixture.chore(
            'bed',
            'Make your bed before school starts',
            picture: 'make-bed',
            points: 10,
            needsApproval: true,
          ),
          KidHomeFixture.chore('teeth', 'Brush teeth', picture: 'brush-teeth'),
          KidHomeFixture.chore('dog', 'Feed the dog'),
        ],
        completions: [KidHomeFixture.done('teeth')],
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Feed the dog'), 200);
    expect(tester.takeException(), isNull);
  });
}

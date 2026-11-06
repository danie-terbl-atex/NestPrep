import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/features/photo_frames/data/photo_frame_directory.dart';
import 'package:nestprep/features/photo_frames/state/frame_photos_controller.dart';
import 'package:nestprep/features/photo_frames/state/photo_frames_controller.dart';
import 'package:nestprep/features/photo_frames/ui/frame_scanner.dart';
import 'package:nestprep/features/photo_frames/ui/photo_frames_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_photo_frames.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

void main() {
  late FakePhotoFrameRepository repository;
  late FakePhotoFrameDirectory directory;
  late FakeFrameScanner scanner;
  late PhotoFramesController controller;

  void build({List<Member>? members}) {
    controller = PhotoFramesController(
      photoFrameRepository: repository,
      householdId: Fixtures.householdId,
      members: members ?? [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
    );
  }

  setUp(() {
    repository = FakePhotoFrameRepository();
    directory = FakePhotoFrameDirectory();
    scanner = FakeFrameScanner();
    build();
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  Future<void> openSheet(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpScreen(
      tester,
      const PhotoFramesScreen(),
      providers: [
        ChangeNotifierProvider<PhotoFramesController>.value(value: controller),
        ChangeNotifierProvider<FramePhotosController>(
          create: (_) => FramePhotoFixtures.controller(),
        ),
        Provider<PhotoFrameDirectory>.value(value: directory),
        Provider<FrameScanner>.value(value: scanner),
      ],
    );
    repository.emit(const []);
    await tester.pumpAndSettle();
    await tester.tap(find.text(PhotoFrameCopy.link));
    await tester.pumpAndSettle();
  }

  Future<void> scan(WidgetTester tester, String raw) async {
    scanner.scan(raw);
    await tester.pumpAndSettle();
  }

  Future<void> link(WidgetTester tester) async {
    await tester.tap(find.text(PhotoFrameCopy.linkAction));
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the camera, with a way to type instead', (
    tester,
  ) async {
    await openSheet(tester);
    expect(find.text(PhotoFrameCopy.scanBody), findsOneWidget);
    expect(find.text(PhotoFrameCopy.typeInstead), findsOneWidget);
  });

  testWidgets('a scanned frame code goes on to naming it', (tester) async {
    await openSheet(tester);
    await scan(tester, 'nestprep://frame/K7MQ9Z');

    expect(find.text(PhotoFrameCopy.codeFound('K7MQ9Z')), findsOneWidget);
    expect(find.text(PhotoFrameCopy.defaultName), findsOneWidget);
  });

  testWidgets('another QR code is refused kindly, and scanning goes on', (
    tester,
  ) async {
    await openSheet(tester);
    await scan(tester, 'https://example.com/menu');

    expect(find.text(PhotoFrameCopy.notAFrameCode), findsOneWidget);
    expect(find.text(PhotoFrameCopy.scanBody), findsOneWidget);

    await scan(tester, 'nestprep://frame/K7MQ9Z');
    expect(find.text(PhotoFrameCopy.codeFound('K7MQ9Z')), findsOneWidget);
  });

  testWidgets('a typed code links with the name and the panels', (
    tester,
  ) async {
    await openSheet(tester);
    await tester.tap(find.text(PhotoFrameCopy.typeInstead));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<NestButton>(
            find.widgetWithText(NestButton, PhotoFrameCopy.next),
          )
          .onPressed,
      isNull,
      reason: 'half a code goes nowhere',
    );
    await tester.enterText(find.byType(TextField), 'k7m-q9z');
    await tester.pumpAndSettle();
    await tester.tap(find.text(PhotoFrameCopy.next));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Hall frame');
    await tester.tap(find.text(PhotoFrameCopy.todos));
    await tester.pumpAndSettle();
    await link(tester);

    final claim = directory.claimed.single;
    expect(claim.code, 'K7MQ9Z');
    expect(claim.name, 'Hall frame');
    expect(claim.panels.todos, isFalse);
    expect(claim.panels.calendar, isTrue);
    expect(claim.panels.helperMemberId, isNull);
    expect(find.text(PhotoFrameCopy.linked), findsOneWidget);

    await tester.tap(find.text(PhotoFrameCopy.done));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('lunch boxes start off and link when switched on', (
    tester,
  ) async {
    await openSheet(tester);
    await scan(tester, 'K7MQ9Z');

    expect(find.text(PhotoFrameCopy.lunch), findsOneWidget);
    await tester.tap(find.text(PhotoFrameCopy.lunch));
    await tester.pumpAndSettle();
    await link(tester);

    expect(directory.claimed.single.panels.lunch, isTrue);
  });

  testWidgets('adding events starts on, and only with the calendar', (
    tester,
  ) async {
    await openSheet(tester);
    await scan(tester, 'K7MQ9Z');

    Switch adding() => tester.widget<Switch>(
      find.descendant(
        of: find.ancestor(
          of: find.text(PhotoFrameCopy.addEvents),
          matching: find.byType(NestListRow),
        ),
        matching: find.byType(Switch),
      ),
    );
    expect(find.text(PhotoFrameCopy.addEventsBody), findsOneWidget);
    expect(adding().value, isTrue);
    expect(adding().onChanged, isNotNull);

    await tester.tap(find.text(PhotoFrameCopy.calendar));
    await tester.pumpAndSettle();
    expect(adding().value, isFalse);
    expect(adding().onChanged, isNull);

    await tester.tap(find.text(PhotoFrameCopy.calendar));
    await tester.pumpAndSettle();
    await tester.tap(find.text(PhotoFrameCopy.addEvents));
    await tester.pumpAndSettle();
    await link(tester);

    expect(directory.claimed.single.panels.calendar, isTrue);
    expect(directory.claimed.single.panels.addEvents, isFalse);
  });

  testWidgets('opening shared pages starts on, and can be left off', (
    tester,
  ) async {
    await openSheet(tester);
    await scan(tester, 'K7MQ9Z');

    expect(find.text(PhotoFrameCopy.shareBody), findsOneWidget);
    await tester.ensureVisible(find.text(PhotoFrameCopy.share));
    await tester.pumpAndSettle();
    await tester.tap(find.text(PhotoFrameCopy.share));
    await tester.pumpAndSettle();
    await link(tester);

    expect(directory.claimed.single.panels.share, isFalse);
  });

  testWidgets('a new frame opens shared pages', (tester) async {
    await openSheet(tester);
    await scan(tester, 'K7MQ9Z');
    await link(tester);

    expect(directory.claimed.single.panels.share, isTrue);
  });

  testWidgets('a helper’s day names whose', (tester) async {
    await openSheet(tester);
    await scan(tester, 'K7MQ9Z');

    expect(find.text(PhotoFrameCopy.helperTitle), findsOneWidget);
    expect(find.text(PhotoFrameCopy.chooseHelper), findsNothing);
    await tester.tap(find.text(PhotoFrameCopy.helperTitle));
    await tester.pumpAndSettle();
    expect(find.text(PhotoFrameCopy.chooseHelper), findsOneWidget);
    expect(find.text(Fixtures.thandi.displayName), findsOneWidget);
    await link(tester);

    expect(
      directory.claimed.single.panels.helperMemberId,
      Fixtures.thandiMemberId,
    );
  });

  testWidgets('no helper in the household, no helper’s day', (tester) async {
    controller.dispose();
    build(members: [Fixtures.sam, Fixtures.kid]);
    await openSheet(tester);
    await scan(tester, 'K7MQ9Z');

    expect(find.text(PhotoFrameCopy.calendar), findsOneWidget);
    expect(find.text(PhotoFrameCopy.helperTitle), findsNothing);
  });

  testWidgets('a frame that shows nothing is not linked', (tester) async {
    controller.dispose();
    build(members: [Fixtures.sam]);
    await openSheet(tester);
    await scan(tester, 'K7MQ9Z');

    for (final panel in [
      PhotoFrameCopy.calendar,
      PhotoFrameCopy.todos,
      PhotoFrameCopy.meals,
    ]) {
      await tester.tap(find.text(panel));
      await tester.pumpAndSettle();
    }
    await link(tester);

    expect(directory.claimed, isEmpty);
  });

  testWidgets('a refused claim is said in the sheet, in its own words', (
    tester,
  ) async {
    directory.failWith = const PhotoFrameFailure(
      PhotoFrameProblem.frameCodeNotFound,
    );
    await openSheet(tester);
    await scan(tester, 'K7MQ9Z');
    await link(tester);

    expect(
      find.text(PhotoFrameCopy.problem(PhotoFrameProblem.frameCodeNotFound)),
      findsOneWidget,
    );
    expect(find.text(PhotoFrameCopy.linked), findsNothing);

    await tester.ensureVisible(find.text(PhotoFrameCopy.differentCode));
    await tester.pumpAndSettle();
    await tester.tap(find.text(PhotoFrameCopy.differentCode));
    await tester.pumpAndSettle();
    expect(find.text(PhotoFrameCopy.scanBody), findsOneWidget);
    expect(
      find.text(PhotoFrameCopy.problem(PhotoFrameProblem.frameCodeNotFound)),
      findsNothing,
    );
  });
}

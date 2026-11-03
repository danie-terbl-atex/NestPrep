import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/photo_frames/data/photo_frame_directory.dart';
import 'package:nestprep/features/photo_frames/model/frame_panels.dart';
import 'package:nestprep/features/photo_frames/state/frame_photos_controller.dart';
import 'package:nestprep/features/photo_frames/state/photo_frames_controller.dart';
import 'package:nestprep/features/photo_frames/ui/frame_scanner.dart';
import 'package:nestprep/features/photo_frames/ui/photo_frames_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/fake_photo_frames.dart';
import '../test/support/household_fixtures.dart';
import 'review_press.dart';

/// Not a test — photo frames' half of the screenshot press (photo-frames
/// ADR-0001): the frames, the camera step and naming a new one, in light and
/// dark. Regenerate with
///
///     flutter test tool/photo_frames_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  Future<void> press(
    WidgetTester tester,
    String name,
    Brightness brightness, {
    bool empty = false,
    Future<void> Function(FakeFrameScanner scanner)? act,
  }) async {
    final repository = FakePhotoFrameRepository();
    final scanner = FakeFrameScanner();
    addTearDown(repository.close);
    final controller = PhotoFramesController(
      photoFrameRepository: repository,
      householdId: Fixtures.householdId,
      members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
    );
    addTearDown(controller.dispose);
    final now = DateTime.utc(2026, 10, 24, 8, 30);
    await captureScreen(
      tester,
      '$name-${brightness.name}',
      screen: const PhotoFramesScreen(),
      providers: [
        ChangeNotifierProvider<PhotoFramesController>.value(value: controller),
        ChangeNotifierProvider<FramePhotosController>(
          create: (_) => FramePhotoFixtures.controller(),
        ),
        Provider<PhotoFrameDirectory>.value(value: FakePhotoFrameDirectory()),
        Provider<FrameScanner>.value(value: scanner),
        Provider<HouseholdClock>.value(
          value: HouseholdClock('Africa/Johannesburg', now: () => now),
        ),
      ],
      brightness: brightness,
      emit: () async => repository.emit(
        empty
            ? const []
            : [
                FrameFixtures.frame(
                  linkedAt: now.subtract(const Duration(days: 3)),
                  lastSeenAt: now.subtract(const Duration(minutes: 4)),
                ),
                FrameFixtures.frame(
                  id: 'frame-hall',
                  name: 'Hallway frame',
                  panels: const FramePanels(
                    todos: false,
                    meals: false,
                    helperMemberId: Fixtures.thandiMemberId,
                  ),
                  linkedAt: now.subtract(const Duration(days: 3)),
                  lastSeenAt: now.subtract(const Duration(hours: 5)),
                ),
                FrameFixtures.frame(
                  id: 'frame-study',
                  name: 'Study frame',
                  panels: const FramePanels(calendar: false),
                  linkedAt: now.subtract(const Duration(minutes: 1)),
                ),
              ],
      ),
      act: act == null ? null : () => act(scanner),
    );
  }

  for (final brightness in Brightness.values) {
    testWidgets('photo frames — ${brightness.name}', (tester) async {
      await press(tester, 'photo-frames', brightness);
    });

    testWidgets('no photo frames yet — ${brightness.name}', (tester) async {
      await press(tester, 'photo-frames-empty', brightness, empty: true);
    });

    testWidgets('scanning a frame — ${brightness.name}', (tester) async {
      await press(
        tester,
        'photo-frame-scan',
        brightness,
        act: (scanner) async {
          await tester.tap(find.text(PhotoFrameCopy.link));
          await tester.pumpAndSettle();
        },
      );
    });

    testWidgets('naming a new frame — ${brightness.name}', (tester) async {
      await press(
        tester,
        'photo-frame-link',
        brightness,
        act: (scanner) async {
          await tester.tap(find.text(PhotoFrameCopy.link));
          await tester.pumpAndSettle();
          scanner.scan('nestprep://frame/K7MQ9Z');
          await tester.pumpAndSettle();
          await tester.tap(find.text(PhotoFrameCopy.helperTitle));
        },
      );
    });

    testWidgets('a frame’s settings — ${brightness.name}', (tester) async {
      await press(
        tester,
        'photo-frame-settings',
        brightness,
        act: (scanner) async {
          await tester.tap(find.text('Hallway frame'));
        },
      );
    });
  }
}

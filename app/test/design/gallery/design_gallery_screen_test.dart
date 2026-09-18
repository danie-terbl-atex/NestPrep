import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/design_gallery_access.dart';
import 'package:nestprep/design/gallery/design_gallery_screen.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/shared/copy/app_copy.dart';

/// The gallery renders every primitive in the kit, and until now nothing
/// rendered the gallery.
///
/// Its four files sat at 1 of 53, 1 of 41, 1 of 28 and 1 of 25 lines — the
/// showcase for the design system was the least-exercised code in the app. That
/// matters twice over. It is the one screen that instantiates every primitive,
/// so a renamed token or a changed kit signature breaks it and nothing says so
/// until somebody opens it. And it is no longer debug-only: a release build may
/// opt in with `NESTPREP_CRASH_TEST`, because proving a crash reaches
/// Crashlytics needs a release build *and* a trigger (observability ADR-0001).
///
/// So this is a smoke test, deliberately. It does not assert how anything looks
/// — `nest_contrast_test.dart` and the tap-target test do that. It asserts that
/// all three sections build, in both themes, at 200% text, without throwing.
void main() {
  Future<void> pumpGallery(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    final nest = brightness == Brightness.dark
        ? NestTheme.dark()
        : NestTheme.light();
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp(
          theme: nestThemeData(nest),
          home: const DesignGalleryScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  /// Every tab, by the label on its bottom-bar item.
  const tabs = [
    AppCopy.galleryControls,
    AppCopy.gallerySurfaces,
    AppCopy.galleryStates,
  ];

  testWidgets('it opens on the controls section', (tester) async {
    await pumpGallery(tester);
    expect(find.text(AppCopy.galleryTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final label in tabs) {
    testWidgets('the $label section builds', (tester) async {
      await pumpGallery(tester);
      await tester.tap(find.bySemanticsLabel(label));
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: 'a primitive in this section no longer builds',
      );
      // The section is on screen, not merely constructed.
      expect(find.byType(DesignGalleryScreen), findsOneWidget);
    });
  }

  testWidgets('every section builds in dark too', (tester) async {
    // The gallery carries its own `Theme`, so a token missing from one palette
    // shows up here and nowhere else.
    await pumpGallery(tester, brightness: Brightness.dark);
    for (final label in tabs) {
      await tester.tap(find.bySemanticsLabel(label));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: '$label in dark');
    }
  });

  testWidgets('and at 200% text, which is the bar every screen holds to', (
    tester,
  ) async {
    // `FE-13`/`FE-14` apply to the gallery as much as to a feature screen, and
    // more so: it is where an overflowing primitive would be noticed first.
    await pumpGallery(tester, textScale: 2);
    for (final label in tabs) {
      await tester.tap(find.bySemanticsLabel(label));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: '$label at 200%');
    }
  });

  testWidgets('the theme toggle swaps brightness without rebuilding wrong', (
    tester,
  ) async {
    await pumpGallery(tester);
    expect(find.text(Brightness.light.name), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(AppCopy.galleryToggleTheme));
    await tester.pump();

    expect(find.text(Brightness.dark.name), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('who can reach it', () {
    test('a debug build always can, and this is one', () {
      expect(DesignGalleryAccess.isAvailable, isTrue);
    });

    test('the opt-in is a define, so an ordinary release build is unchanged', () {
      // Named here so that renaming the define breaks a test rather than
      // quietly turning the crash button on or off for the next release build.
      expect(DesignGalleryAccess.defineName, 'NESTPREP_CRASH_TEST');
    });
  });
}

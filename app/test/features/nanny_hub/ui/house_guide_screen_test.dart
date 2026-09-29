import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nestprep/app/nanny_hub_route.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/nanny_hub/data/photo_picker.dart';
import 'package:nestprep/features/nanny_hub/model/guide_spot.dart';
import 'package:nestprep/features/nanny_hub/ui/nanny_photo.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/nanny_fixtures.dart';
import '../../../support/pump_nanny_hub.dart';

void main() {
  late NannyFakes fakes;

  setUp(() => fakes = NannyFakes());
  tearDown(() => fakes.close());

  Future<void> open(
    WidgetTester tester, {
    HouseholdView? view,
    List<GuideSpot>? guide,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpNannyHub(
      tester,
      fakes,
      location: NannyHubRoute.guidePathFor(Fixtures.householdId),
      view: view,
      brightness: brightness,
      textScale: textScale,
    );
    fakes.answerEverything(guide: guide ?? [NannyFixtures.nappies]);
    await tester.pumpAndSettle();
  }

  testWidgets('shows each place, and what is where', (tester) async {
    await open(tester, view: NannyFixtures.carerView());
    expect(find.text('Spare nappies'), findsOneWidget);
    expect(find.text('Top shelf of the linen cupboard'), findsOneWidget);
  });

  testWidgets('an empty guide tells a parent what to photograph', (
    tester,
  ) async {
    await open(tester, guide: const []);
    expect(find.text(NannyCopy.guideEmptyBody), findsOneWidget);
    expect(find.text(NannyCopy.addSpot), findsOneWidget);
  });

  testWidgets('and a carer at view who will add it', (tester) async {
    await open(
      tester,
      view: NannyFixtures.lookOnlyCarerView(),
      guide: const [],
    );
    expect(find.text(NannyCopy.guideEmptyCarer), findsOneWidget);
    expect(find.text(NannyCopy.addSpot), findsNothing);
  });

  testWidgets('a photo reads from Storage once the claim is on the token', (
    tester,
  ) async {
    fakes.photos.objects['photo-shelf'] = _aPicture();
    await open(
      tester,
      guide: [NannyFixtures.nappies.copyWith(photoId: 'photo-shelf')],
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
    expect(fakes.documents.syncCount, 1);
    expect(fakes.photos.reads, ['photo-shelf']);
    expect(find.byType(NannyPhoto), findsOneWidget);
  });

  testWidgets('a photo that will not load says so, with a retry', (
    tester,
  ) async {
    fakes.photos.failReadsWith = const UnavailableFailure();
    await open(
      tester,
      guide: [NannyFixtures.nappies.copyWith(photoId: 'photo-shelf')],
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
    expect(find.text(NannyCopy.photoFailed), findsOneWidget);
  });

  testWidgets('a parent adds a place with a title, and it is saved', (
    tester,
  ) async {
    await open(tester, guide: const []);
    await tester.tap(find.text(NannyCopy.addSpot));
    await tester.pumpAndSettle();
    await tester.enterText(
      fieldLabelled(NannyCopy.spotTitle),
      '  First-aid kit ',
    );
    await tester.enterText(fieldLabelled(NannyCopy.spotNote), 'Under the sink');
    await tester.pumpAndSettle();
    await tester.tap(find.text(NannyCopy.save));
    await tester.pumpAndSettle();
    final (method, arguments) = fakes.hub.writes.single;
    expect(method, 'addGuideSpot');
    expect(arguments['title'], 'First-aid kit');
    expect(arguments['note'], 'Under the sink');
    expect(arguments['photoId'], isNull);
  });

  testWidgets('a camera that will not open is said, and nothing is saved', (
    tester,
  ) async {
    fakes.picker.failWith = const NannyHubFailure(
      NannyHubProblem.cameraUnavailable,
    );
    await open(tester, guide: const []);
    await tester.tap(find.text(NannyCopy.addSpot));
    await tester.pumpAndSettle();
    await tester.tap(find.text(NannyCopy.takePhoto));
    await tester.pumpAndSettle();
    expect(fakes.picker.asked, [PhotoSource.camera]);
    Navigator.of(tester.element(find.text(NannyCopy.takePhoto))).pop();
    await tester.pumpAndSettle();
    expect(
      find.text(
        AppCopy.failure(
          const NannyHubFailure(NannyHubProblem.cameraUnavailable),
        ),
      ),
      findsOneWidget,
    );
    expect(fakes.hub.writes, isEmpty);
  });

  testWidgets('a parent removes a place, after saying so', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip(NannyCopy.editSpot));
    await tester.pumpAndSettle();
    await tester.tap(find.text(NannyCopy.delete));
    await tester.pumpAndSettle();
    await tester.tap(find.text(NannyCopy.delete).last);
    await tester.pumpAndSettle();
    expect(fakes.hub.writes.single.$1, 'removeGuideSpot');
  });

  testWidgets('holds at 360 wide, in dark, at 200% text', (tester) async {
    await open(tester, brightness: Brightness.dark, textScale: 2);
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

/// A real, tiny picture, so the image codec has something it can draw.
Uint8List _aPicture() =>
    Uint8List.fromList(img.encodePng(img.Image(width: 4, height: 3)));

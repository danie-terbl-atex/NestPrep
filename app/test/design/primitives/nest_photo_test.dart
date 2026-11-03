import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';

import '../../support/pump_kit.dart';

/// A photo opening into its page: the photo flies with its card, arrives
/// whole and at its zoom, and never blinks back to what stands in for it.
void main() {
  final jpeg = File('assets/brand/welcome_lunch.jpg').readAsBytesSync();
  const under = ColoredBox(color: Colors.brown);

  Iterable<double> opacitiesAbove(WidgetTester tester, Finder image) => tester
      .widgetList<FadeTransition>(
        find.ancestor(of: image, matching: find.byType(FadeTransition)),
      )
      .map((fade) => fade.opacity.value);

  double scaleAbove(WidgetTester tester, Finder image) => tester
      .widgetList<Transform>(
        find.ancestor(of: image, matching: find.byType(Transform)),
      )
      .map((transform) => transform.transform.getMaxScaleOnAxis())
      .reduce((a, b) => a * b);

  Future<void> pumpCard(
    WidgetTester tester, {
    required Future<Uint8List?> bytes,
    required WidgetBuilder page,
  }) async {
    await pumpKit(
      tester,
      Builder(
        builder: (context) => SizedBox(
          width: 320,
          child: NestPhotoCard(
            heroTag: 'photo',
            photo: NestPhotoBytes(bytes: bytes, under: under),
            onTap: () => Navigator.of(context).push(
              NestPhotoRoute<void>(
                motion: NestMotion.of(context),
                builder: page,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a photo still on its way fades in over what stands for it', (
    tester,
  ) async {
    final arriving = Completer<Uint8List?>();
    await pumpKit(
      tester,
      SizedBox.square(
        dimension: 200,
        child: NestPhotoBytes(bytes: arriving.future, under: under),
      ),
    );
    arriving.complete(jpeg);
    await tester.pump();

    expect(opacitiesAbove(tester, find.byType(Image)), contains(0));
    await tester.pumpAndSettle();
    expect(opacitiesAbove(tester, find.byType(Image)), everyElement(1));
  });

  testWidgets('a lunch photo flies whole and lands at its zoom', (
    tester,
  ) async {
    final bytes = Future<Uint8List?>.value(jpeg);
    await pumpCard(
      tester,
      bytes: bytes,
      page: (_) => Scaffold(
        body: SizedBox(
          width: 360,
          height: 270,
          child: NestPhotoFrame(
            heroTag: 'photo',
            zoomed: true,
            child: NestPhotoBytes(bytes: bytes, under: under),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(NestPhotoCard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(Image), findsOneWidget);
    expect(
      opacitiesAbove(tester, find.byType(Image)).first,
      1,
      reason: 'the photo in flight is the photo, not the drawn box',
    );

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(Image), findsOneWidget);
    expect(opacitiesAbove(tester, find.byType(Image)), everyElement(1));
    expect(
      scaleAbove(tester, find.byType(Image)),
      closeTo(NestMotion.photoZoom, 0.001),
      reason: 'the zoom the flight carried is not played again on landing',
    );
  });

  testWidgets('a photo flying to a page edge squares its corners on the way', (
    tester,
  ) async {
    await pumpCard(
      tester,
      bytes: Future.value(jpeg),
      page: (_) => Scaffold(
        body: NestPhotoHero(
          heroTag: 'photo',
          photo: NestPhotoBytes(bytes: Future.value(jpeg), under: under),
          backLabel: 'Back',
          onBack: () {},
        ),
      ),
    );

    await tester.tap(find.byType(NestPhotoCard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    final corners = tester
        .widgetList<ClipRRect>(find.byType(ClipRRect))
        .map((clip) => (clip.borderRadius as BorderRadius).topLeft.x);
    expect(
      corners.where((radius) => radius > 0 && radius < NestRadius.xxl),
      hasLength(1),
    );
  });
}

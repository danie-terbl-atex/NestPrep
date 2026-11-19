import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/photo_frame_route.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/photo_frames/state/pending_frame_code.dart';
import 'package:nestprep/features/photo_frames/ui/frame_link_host.dart';
import 'package:nestprep/shared/copy/photo_frame_copy.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_feature_flag_source.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

void main() {
  late StreamController<Uri> links;
  late PendingFrameCode pending;

  setUp(() {
    links = StreamController<Uri>();
    pending = PendingFrameCode(links: links.stream);
  });

  tearDown(() async {
    pending.dispose();
    await links.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    HouseholdView? view,
    bool flagOn = true,
  }) => pumpRouter(
    tester,
    router: GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const FrameLinkHost(child: Scaffold(body: SizedBox.expand())),
        ),
        GoRoute(
          path: PhotoFrameRoute.path,
          builder: (context, state) => Scaffold(
            body: Text(
              'frames ${state.uri.queryParameters[PhotoFrameRoute.linkCodeParameter]}',
            ),
          ),
        ),
      ],
    ),
    providers: [
      featureFlagsProvider(defaultOn: flagOn),
      ChangeNotifierProvider<PendingFrameCode>.value(value: pending),
    ],
    view: view,
  );

  Future<void> scan(WidgetTester tester, String link) async {
    links.add(Uri.parse(link));
    await tester.pumpAndSettle();
  }

  testWidgets('a parent lands on Link a frame with the code in', (
    tester,
  ) async {
    await pump(tester);
    await scan(tester, 'nestprep://frame/K7MQ9Z');

    expect(find.text('frames K7MQ9Z'), findsOneWidget);
    expect(pending.code, isNull);
  });

  testWidgets('a code that arrived before the household waits for it', (
    tester,
  ) async {
    links.add(Uri.parse('https://app.nestprep.io/frame/K7MQ9Z'));
    await tester.pump();
    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('frames K7MQ9Z'), findsOneWidget);
  });

  testWidgets('a helper is told a parent links frames', (tester) async {
    await pump(
      tester,
      view: Fixtures.helperView(AccessGrant.uniform(AccessLevel.edit)),
    );
    await scan(tester, 'nestprep://frame/K7MQ9Z');

    expect(find.text(PhotoFrameCopy.linkNeedsFamily), findsOneWidget);
    expect(find.textContaining('frames K7MQ9Z'), findsNothing);
    expect(pending.code, isNull);
  });

  testWidgets('with frames switched off, nobody is sent there', (tester) async {
    await pump(tester, flagOn: false);
    await scan(tester, 'nestprep://frame/K7MQ9Z');

    expect(find.textContaining('frames K7MQ9Z'), findsNothing);
    expect(find.text(PhotoFrameCopy.linkNeedsFamily), findsOneWidget);
  });
}

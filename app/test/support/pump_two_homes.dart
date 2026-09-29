import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/two_homes_route.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:provider/single_child_widget.dart';

import 'pump_screen.dart';

/// Where a pushed two-homes screen lands in a test: a page that names the
/// path, so a test can prove the tap went where it should (`FE-17`).
class LandedOn extends StatelessWidget {
  const LandedOn(this.path, {super.key});

  final String path;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('landed on $path')));
}

/// Pumps one two-homes screen at `/`, with every other two-homes path — and
/// the household screen — a page that says where it is.
Future<void> pumpTwoHomes(
  WidgetTester tester,
  Widget screen, {
  required List<SingleChildWidget> providers,
  HouseholdView? view,
  Brightness brightness = Brightness.light,
  double textScale = 1,
  bool narrow = false,
}) async {
  if (narrow) {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }
  GoRoute landing(String path) => GoRoute(
    path: path,
    builder: (context, state) => LandedOn(state.uri.path),
  );
  await pumpRouter(
    tester,
    router: GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => screen),
        landing(TwoHomesRoute.path),
        landing(TwoHomesRoute.setupPath),
        landing(TwoHomesRoute.joinPath),
        landing(TwoHomesRoute.privacyPath),
        landing(TwoHomesRoute.linkPath),
        landing(TwoHomesRoute.schedulePath),
        landing(TwoHomesRoute.handoverPath),
        landing('/households/:householdId/household'),
      ],
    ),
    providers: providers,
    view: view,
    brightness: brightness,
    textScale: textScale,
  );
  await tester.pump();
}

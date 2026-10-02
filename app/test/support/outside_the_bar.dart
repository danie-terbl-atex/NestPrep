import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';

/// Text on the screen itself, not in the bottom bar. A tab's title and its
/// name in the bar are the same words (design-system ADR-0005), so a test
/// asking whether the header held its place looks past the bar.
Finder textOutsideTheBar(String text) => find.byElementPredicate(
  (element) =>
      element.widget is Text &&
      (element.widget as Text).data == text &&
      element.findAncestorWidgetOfExactType<NestBottomBar>() == null,
  description: 'text "$text" outside the bottom bar',
);

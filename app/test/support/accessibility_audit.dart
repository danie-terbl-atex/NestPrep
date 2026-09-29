import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// `FE-13`'s two silent halves, as a check any screen test can run: **every
/// control has an accessible label**, and **every touch target is at least
/// 44×44**. It reads the semantics tree rather than the widgets, because that
/// is what a screen reader and the platform's accessibility scanner read.
///
/// Moved out of `tap_targets_and_labels_test.dart` when family profiles added
/// its screens, so the audit has one home and the screens can each have a file.

/// Apple and Android both ask for 44; this app's own token is 48.
const _floor = 44.0;

/// Nodes that are a control: something a person can act on.
bool _isAControl(SemanticsData data) =>
    data.hasAction(SemanticsAction.tap) ||
    data.flagsCollection.isButton ||
    data.flagsCollection.isTextField;

/// Walks the semantics tree, keeping each node's rect in screen coordinates.
void _visit(
  SemanticsNode node,
  Matrix4 inherited,
  void Function(SemanticsData data, Rect onScreen) found,
) {
  final transform = inherited.multiplied(node.transform ?? Matrix4.identity());
  final data = node.getSemanticsData();
  found(data, MatrixUtils.transformRect(transform, node.rect));
  node.visitChildren((child) {
    _visit(child, transform, found);
    return true;
  });
}

({List<String> unlabelled, List<String> tooSmall}) _auditOf(
  WidgetTester tester,
) {
  // Semantics rects are in the root coordinate space, which is *physical*
  // pixels. On a 3x device every target looks three times the size it is,
  // and a check against 44 passes whatever the layout says — this test did
  // exactly that until the mutation of a real button failed to fail it.
  final ratio = tester.view.devicePixelRatio;
  final unlabelled = <String>[];
  final tooSmall = <String>[];
  final root =
      // `rootPipelineOwner` is the documented replacement and has no
      // semantics owner in a widget test — this is the tree the test is
      // actually rendering.
      // ignore: deprecated_member_use
      tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;

  _visit(root, Matrix4.identity(), (data, onScreen) {
    if (!_isAControl(data)) return;
    // A node scrolled out of view has no size worth measuring — whether it
    // is gone entirely or only kept in the list's cache, clipped to a
    // sliver at the edge. The first long screen (a family profile) was the
    // first to put a control in that cache.
    if (onScreen.isEmpty || data.flagsCollection.isHidden) return;

    final label = data.label.trim().isNotEmpty
        ? data.label.trim()
        : data.tooltip.trim();
    if (label.isEmpty) {
      unlabelled.add('a control at ${onScreen.topLeft} has no label');
      return;
    }
    final width = onScreen.width / ratio;
    final height = onScreen.height / ratio;
    if (width < _floor || height < _floor) {
      tooSmall.add(
        '"$label" is ${width.toStringAsFixed(0)}×${height.toStringAsFixed(0)}',
      );
    }
  });
  return (unlabelled: unlabelled, tooSmall: tooSmall);
}

Future<void> expectAccessible(WidgetTester tester, String screen) async {
  final handle = tester.ensureSemantics();
  await tester.pumpAndSettle();
  final audit = _auditOf(tester);

  expect(
    audit.unlabelled,
    isEmpty,
    reason:
        '$screen: a screen reader announces these as "button" and '
        'nothing else (`FE-13`)',
  );
  expect(
    audit.tooSmall,
    isEmpty,
    reason:
        '$screen: below ${_floor.toInt()}×${_floor.toInt()}, and the '
        'people who miss are the least likely to report it (`FE-13`)',
  );
  handle.dispose();
}

/// A phone, because a target's size depends on the space it is given.
void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360 * 3, 800 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Draws a widget to a PNG without it ever being on screen (lunch-box
/// ADR-0005): a render tree of its own, a `RepaintBoundary` at the root, laid
/// out at [logicalSize] and captured at [pixelRatio].
///
/// Nothing about the phone leaks in — not its size, its text setting or its
/// theme — so the same widget gives the same bytes every time. Images are
/// decoded before the first frame, because an offscreen tree gets one frame
/// and an image still loading would be a hole in the picture.
final class OffscreenWidgetRenderer {
  const OffscreenWidgetRenderer();

  Future<Uint8List> renderPng(
    Widget widget, {
    required Size logicalSize,
    required double pixelRatio,
    List<ImageProvider> images = const [],
  }) async {
    await Future.wait(images.map(_decode));
    final image = await _render(widget, logicalSize, pixelRatio);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        throw StateError('the engine returned no PNG bytes');
      }
      return bytes.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  Future<ui.Image> _render(Widget widget, Size size, double pixelRatio) async {
    final boundary = RenderRepaintBoundary();
    final renderView = RenderView(
      view: ui.PlatformDispatcher.instance.implicitView!,
      child: RenderPositionedBox(child: boundary),
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(size),
        physicalConstraints: BoxConstraints.tight(size * pixelRatio),
        devicePixelRatio: pixelRatio,
      ),
    );
    final pipeline = PipelineOwner()..rootNode = renderView;
    renderView.prepareInitialFrame();
    final buildOwner = BuildOwner(focusManager: FocusManager());
    final root = RenderObjectToWidgetAdapter<RenderBox>(
      container: boundary,
      child: widget,
    ).attachToRenderTree(buildOwner);
    try {
      buildOwner
        ..buildScope(root)
        ..finalizeTree();
      pipeline
        ..flushLayout()
        ..flushCompositingBits()
        ..flushPaint();
      return await boundary.toImage(pixelRatio: pixelRatio);
    } finally {
      // The tree is thrown away once painted; unmounting it lets every
      // State dispose of what it holds.
      buildOwner
        ..buildScope(
          root,
          () => root.update(
            RenderObjectToWidgetAdapter<RenderBox>(container: boundary),
          ),
        )
        ..finalizeTree();
    }
  }

  /// Resolves an image into the cache and waits until it has a frame, so
  /// the offscreen tree finds it already decoded.
  static Future<void> _decode(ImageProvider provider) {
    final done = Completer<void>();
    final stream = provider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (image, synchronousCall) {
        stream.removeListener(listener);
        if (!done.isCompleted) done.complete();
      },
      onError: (error, stackTrace) {
        stream.removeListener(listener);
        if (!done.isCompleted) done.completeError(error, stackTrace);
      },
    );
    stream.addListener(listener);
    return done.future;
  }
}

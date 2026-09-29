import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// The picture of whatever [key]'s `RepaintBoundary` has painted, as a PNG at
/// the phone's own sharpness — or null when there is nothing painted to take
/// a picture of. The controller turns null into words (`ENG-10`).
Future<Uint8List?> captureCard(GlobalKey key, {double pixelRatio = 3}) async {
  // The tap that asked for the picture has just changed the screen; wait for
  // the frame that paints it, so the picture is of what is there.
  await WidgetsBinding.instance.endOfFrame;
  final boundary = key.currentContext?.findRenderObject();
  if (boundary is! RenderRepaintBoundary) return null;
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

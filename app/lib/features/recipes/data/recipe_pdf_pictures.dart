import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../model/recipe_document.dart';
import 'recipe_pdf.dart';

/// Run on a background isolate: a page is megabytes of pixels.
abstract final class RecipePdfPictures {
  static const halfShare = 0.55;

  static Uint8List whole(
    PdfRasterPage page, {
    required int longEdge,
    int quality = 72,
  }) => img.encodeJpg(_scaled(onWhite(page), longEdge), quality: quality);

  /// Top and bottom, each [halfShare] of the page, so a line across the
  /// middle is whole in one of them.
  static (Uint8List, Uint8List) halves(
    PdfRasterPage page, {
    required int longEdge,
    int quality = 78,
  }) {
    final image = _scaled(onWhite(page), longEdge);
    final share = (image.height * halfShare).round();
    final top = img.copyCrop(
      image,
      x: 0,
      y: 0,
      width: image.width,
      height: share,
    );
    final bottom = img.copyCrop(
      image,
      x: 0,
      y: image.height - share,
      width: image.width,
      height: share,
    );
    return (
      img.encodeJpg(top, quality: quality),
      img.encodeJpg(bottom, quality: quality),
    );
  }

  static Uint8List cropped(
    PdfRasterPage page,
    DocumentPhotoBox box, {
    int quality = 90,
  }) {
    final image = onWhite(page);
    final left = (box.left / 1000 * image.width).round();
    final top = (box.top / 1000 * image.height).round();
    final right = (box.right / 1000 * image.width).round();
    final bottom = (box.bottom / 1000 * image.height).round();
    return img.encodeJpg(
      img.copyCrop(
        image,
        x: left,
        y: top,
        width: max(1, right - left),
        height: max(1, bottom - top),
      ),
      quality: quality,
    );
  }

  /// Both platforms draw on transparency, which a JPEG would turn black.
  static img.Image onWhite(PdfRasterPage page) {
    final rgba = page.rgba;
    final pixels = page.width * page.height;
    final rgb = Uint8List(pixels * 3);
    for (var from = 0, to = 0; from < pixels * 4; from += 4, to += 3) {
      final uncovered = 255 - rgba[from + 3];
      rgb[to] = min(255, rgba[from] + uncovered);
      rgb[to + 1] = min(255, rgba[from + 1] + uncovered);
      rgb[to + 2] = min(255, rgba[from + 2] + uncovered);
    }
    return img.Image.fromBytes(
      width: page.width,
      height: page.height,
      bytes: rgb.buffer,
      numChannels: 3,
    );
  }

  static img.Image _scaled(img.Image image, int longEdge) {
    if (max(image.width, image.height) <= longEdge) return image;
    return image.width >= image.height
        ? img.copyResize(
            image,
            width: longEdge,
            interpolation: img.Interpolation.average,
          )
        : img.copyResize(
            image,
            height: longEdge,
            interpolation: img.Interpolation.average,
          );
  }
}

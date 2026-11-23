import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../model/recipe_snap.dart';

sealed class RecipeSnapCut {
  const RecipeSnapCut();
}

final class RecipeSnapReady extends RecipeSnapCut {
  const RecipeSnapReady(this.snap);

  final RecipeSnap snap;
}

final class RecipeSnapUnreadable extends RecipeSnapCut {
  const RecipeSnapUnreadable();
}

final class RecipeSnapTooLong extends RecipeSnapCut {
  const RecipeSnapTooLong();
}

/// Run on a background isolate: a photo is megabytes of pixels.
///
/// Sent with others, a picture is read at one coarse size, and a part taller
/// than it is wide loses its small type (measured, recipes ADR-0010). A photo
/// is scaled to [shortEdge] and cut into overlapping parts, left column first
/// and top to bottom, so a line on a seam is whole in one of them. Sent
/// alone, a picture is read far more finely, so an ordinary photo also keeps
/// a [RecipeSnap.whole] for the read that has nothing else in it.
abstract final class RecipeSnapPictures {
  static const shortEdge = 1024;
  static const partWidth = 1024;
  static const partHeight = 820;
  static const overlapShare = 0.12;
  static const thumbnailEdge = 240;
  static const wholeLongEdge = 2200;
  static const wholeMaxShape = 2.2;
  static const _qualities = [80, 65, 50, 35];

  static RecipeSnapCut cut(Uint8List original, {required int partRoom}) {
    final decoded = _decode(original);
    if (decoded == null) return const RecipeSnapUnreadable();
    final upright = img.bakeOrientation(decoded)
      ..exif = img.ExifData()
      ..iccProfile = null;
    final image = _scaled(upright);
    final lefts = offsets(image.width, partWidth);
    final tops = offsets(image.height, partHeight);
    if (lefts.length * tops.length > partRoom) return const RecipeSnapTooLong();
    final parts = <Uint8List>[];
    for (final left in lefts) {
      for (final top in tops) {
        final part = _encoded(
          img.copyCrop(
            image,
            x: left,
            y: top,
            width: min(partWidth, image.width),
            height: min(partHeight, image.height),
          ),
        );
        if (part == null) return const RecipeSnapUnreadable();
        parts.add(part);
      }
    }
    return RecipeSnapReady(
      RecipeSnap(
        parts: parts,
        layout: RecipeSnapLayout(
          width: image.width,
          height: image.height,
          partWidth: min(partWidth, image.width),
          partHeight: min(partHeight, image.height),
          lefts: lefts,
          tops: tops,
        ),
        whole: _whole(upright),
        thumbnail: img.encodeJpg(
          img.copyResizeCropSquare(image, size: thumbnailEdge),
          quality: 70,
        ),
      ),
    );
  }

  /// The dish's photograph cut out of the parts, or null (recipes ADR-0011).
  /// The model boxes it on one part; an edge on a seam between parts is grown
  /// into the next part while the pixels beyond it are not plain.
  static Uint8List? dishPhoto(RecipeSnap snap, RecipeSnapDish dish) {
    final layout = snap.layout;
    final part = dish.part;
    if (part != null && (part < 1 || part > layout.partCount)) return null;
    final (left, top) = part == null ? (0, 0) : layout.originOf(part - 1);
    final width = part == null ? layout.width : layout.partWidth;
    final height = part == null ? layout.height : layout.partHeight;
    final box = dish.box;
    var x0 = left + box.left * width ~/ 1000;
    var y0 = top + box.top * height ~/ 1000;
    var x1 = left + box.right * width ~/ 1000;
    var y1 = top + box.bottom * height ~/ 1000;
    final onPart = part != null;
    final growsLeft = onPart && box.left <= seamEdge && left > 0;
    final growsUp = onPart && box.top <= seamEdge && top > 0;
    final growsRight =
        onPart && box.right >= 1000 - seamEdge && left + width < layout.width;
    final growsDown =
        onPart && box.bottom >= 1000 - seamEdge && top + height < layout.height;
    final bandLeft = max(0, x0 - (growsLeft ? width : 0));
    final bandTop = max(0, y0 - (growsUp ? height : 0));
    final bandRight = min(layout.width, x1 + (growsRight ? width : 0));
    final bandBottom = min(layout.height, y1 + (growsDown ? height : 0));
    final band = _composed(
      snap,
      left: bandLeft,
      top: bandTop,
      width: bandRight - bandLeft,
      height: bandBottom - bandTop,
    );
    if (band == null) return null;
    x0 -= bandLeft;
    x1 -= bandLeft;
    y0 -= bandTop;
    y1 -= bandTop;
    if (growsUp) {
      while (y0 > 0 && !_isPlain(band, y0 - 1, x0, x1, isRow: true)) {
        y0 -= 1;
      }
    }
    if (growsDown) {
      while (y1 < band.height && !_isPlain(band, y1, x0, x1, isRow: true)) {
        y1 += 1;
      }
    }
    if (growsLeft) {
      while (x0 > 0 && !_isPlain(band, x0 - 1, y0, y1, isRow: false)) {
        x0 -= 1;
      }
    }
    if (growsRight) {
      while (x1 < band.width && !_isPlain(band, x1, y0, y1, isRow: false)) {
        x1 += 1;
      }
    }
    if (x1 - x0 < minDishEdge || y1 - y0 < minDishEdge) return null;
    return img.encodeJpg(
      img.copyCrop(band, x: x0, y: y0, width: x1 - x0, height: y1 - y0),
      quality: 90,
    );
  }

  static const seamEdge = 30;
  static const minDishEdge = 64;
  static const plainRange = 16;
  static const _plainSamples = 64;

  /// The scaled photo's pixels in one rectangle, laid together from the parts
  /// that cover it.
  static img.Image? _composed(
    RecipeSnap snap, {
    required int left,
    required int top,
    required int width,
    required int height,
  }) {
    final layout = snap.layout;
    if (width <= 0 || height <= 0) return null;
    final canvas = img.Image(width: width, height: height);
    for (var at = 0; at < snap.parts.length; at += 1) {
      final (partLeft, partTop) = layout.originOf(at);
      final x0 = max(left, partLeft);
      final y0 = max(top, partTop);
      final x1 = min(left + width, partLeft + layout.partWidth);
      final y1 = min(top + height, partTop + layout.partHeight);
      if (x1 <= x0 || y1 <= y0) continue;
      final part = _decode(snap.parts[at]);
      if (part == null) return null;
      // compositeImage misplaces a source drawn from a negative offset.
      img.compositeImage(
        canvas,
        img.copyCrop(
          part,
          x: x0 - partLeft,
          y: y0 - partTop,
          width: x1 - x0,
          height: y1 - y0,
        ),
        dstX: x0 - left,
        dstY: y0 - top,
      );
    }
    return canvas;
  }

  /// A row (or column) at [at], between [from] and [to], whose brightness
  /// barely changes: page background, never a photograph.
  static bool _isPlain(
    img.Image image,
    int at,
    int from,
    int to, {
    required bool isRow,
  }) {
    var darkest = 255.0;
    var lightest = 0.0;
    final span = max(1, to - from);
    for (var sample = 0; sample < _plainSamples; sample += 1) {
      final along = from + sample * span ~/ _plainSamples;
      final pixel = isRow
          ? image.getPixel(along, at)
          : image.getPixel(at, along);
      final luminance = pixel.luminanceNormalized * 255;
      darkest = min(darkest, luminance.toDouble());
      lightest = max(lightest, luminance.toDouble());
    }
    return lightest - darkest <= plainRange;
  }

  /// Where each part starts along a side of [length], spread evenly with at
  /// least [overlapShare] of a part shared between neighbours.
  static List<int> offsets(int length, int part) {
    if (length <= part) return const [0];
    final overlap = (part * overlapShare).round();
    final count = ((length - overlap) / (part - overlap)).ceil();
    return [
      for (var at = 0; at < count; at += 1)
        (at * (length - part) / (count - 1)).round(),
    ];
  }

  /// Null for a long scroll, which a single picture would shrink to nothing.
  static Uint8List? _whole(img.Image image) {
    final long = max(image.width, image.height);
    final short = min(image.width, image.height);
    if (long > short * wholeMaxShape) return null;
    final isWide = image.width >= image.height;
    final sized = long <= wholeLongEdge
        ? image
        : img.copyResize(
            image,
            width: isWide ? wholeLongEdge : null,
            height: isWide ? null : wholeLongEdge,
            interpolation: img.Interpolation.average,
          );
    final bytes = img.encodeJpg(sized, quality: 82);
    return bytes.length <= RecipeSnap.maxWholeBytes ? bytes : null;
  }

  static Uint8List? _encoded(img.Image part) {
    for (final quality in _qualities) {
      final bytes = img.encodeJpg(part, quality: quality);
      if (bytes.length <= RecipeSnap.maxPartBytes) return bytes;
    }
    return null;
  }

  static img.Image _scaled(img.Image image) {
    if (min(image.width, image.height) <= shortEdge) return image;
    return image.width <= image.height
        ? img.copyResize(
            image,
            width: shortEdge,
            interpolation: img.Interpolation.average,
          )
        : img.copyResize(
            image,
            height: shortEdge,
            interpolation: img.Interpolation.average,
          );
  }

  /// The `image` package runs off the end of a truncated file, and some
  /// decoders throw on bytes that are not theirs.
  static img.Image? _decode(Uint8List original) {
    try {
      return img.findDecoderForData(original)?.decode(original);
    } on Exception {
      return null;
    } on RangeError {
      return null;
    } on ArgumentError {
      return null;
    }
  }
}

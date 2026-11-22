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
    final upright = img.bakeOrientation(decoded)..exif = img.ExifData();
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
        whole: _whole(upright),
        thumbnail: img.encodeJpg(
          img.copyResizeCropSquare(image, size: thumbnailEdge),
          quality: 70,
        ),
      ),
    );
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

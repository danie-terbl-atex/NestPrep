import 'package:flutter/widgets.dart';

/// One run of text on a card, measured for fit: what it says and how many
/// lines it may take (null for as many as it needs).
typedef LunchCardTextBlock = ({InlineSpan span, int? maxLines});

/// How small a card lets its words get to say all of what is in a box,
/// rather than cutting it off (lunch-box ADR-0005). A card is a picture with
/// a fixed size, so the type shrinks to the room instead of the room growing
/// to the type — but never below [minScale], where 1080 pixels stop reading
/// at a phone's width. Past that, the caller's own `maxLines` and ellipsis
/// are the last resort.
///
/// The frame fixes the text scale (`LunchCardFrame`), so measuring here is
/// measuring the picture: the same scale on every phone.
abstract final class LunchCardTextFit {
  /// The smallest a card's food names are drawn, against their designed size.
  static const minScale = 0.72;

  /// The scale steps down by this much at a time: few enough layouts to stay
  /// cheap, and the same steps every time, so the image is byte-identical.
  static const _step = 0.04;

  /// The largest scale, from 1 down to [minScale], at which every one of
  /// [blocks], stacked, fits [room] whole — or null when none does.
  static double? scaleFor(
    BuildContext context,
    List<LunchCardTextBlock> blocks,
    Size room,
  ) {
    final defaults = DefaultTextStyle.of(context);
    for (var scale = 1.0; scale >= minScale - 1e-9; scale -= _step) {
      if (_fits(defaults, blocks, room, TextScaler.linear(scale))) {
        return scale;
      }
    }
    return null;
  }

  static bool _fits(
    DefaultTextStyle defaults,
    List<LunchCardTextBlock> blocks,
    Size room,
    TextScaler scaler,
  ) {
    var height = 0.0;
    for (final block in blocks) {
      // Laid out as `Text.rich` lays it out: under the inherited style.
      final painter = TextPainter(
        text: TextSpan(style: defaults.style, children: [block.span]),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: block.maxLines,
        textHeightBehavior: defaults.textHeightBehavior,
      )..layout(maxWidth: room.width);
      final exceeded = painter.didExceedMaxLines;
      height += painter.height;
      painter.dispose();
      if (exceeded || height > room.height) return false;
    }
    return true;
  }
}

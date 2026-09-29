import 'package:flutter/material.dart';

import '../../../../design/nest_kit.dart';
import '../../model/lunch_card_format.dart';
import 'lunch_card_palette.dart';

/// Everything around a card that the phone would otherwise decide: its own
/// token set, text at its designed size, no motion, left to right, at the
/// format's size (lunch-box ADR-0005). The preview and the exported image
/// both sit inside one of these, so the preview is the image — and the image
/// is the same on every phone, in either theme, at any text setting.
class LunchCardFrame extends StatelessWidget {
  const LunchCardFrame({
    required this.palette,
    required this.format,
    required this.child,
    super.key,
  });

  final LunchCardPalette palette;
  final LunchCardFormat format;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = format.logicalSize;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(
          size: size,
          devicePixelRatio: LunchCardFormat.pixelRatio,
          disableAnimations: true,
        ),
        child: Theme(
          data: nestThemeData(palette.theme),
          child: DefaultTextStyle(
            style: palette.theme.text.body,
            child: SizedBox.fromSize(size: size, child: child),
          ),
        ),
      ),
    );
  }
}

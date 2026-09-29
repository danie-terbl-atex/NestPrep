import 'package:flutter/material.dart';

import '../../../../design/nest_kit.dart';
import '../../../../shared/copy/app_copy.dart';
import '../../model/lunch_card_content.dart';
import '../../model/lunch_card_options.dart';
import '../card/lunch_share_card.dart';

/// The card exactly as it will be sent, scaled to fit the screen
/// (lunch-box ADR-0005). The card inside keeps its own size, look and text,
/// so the phone's theme and text setting change the screen around it and
/// never the picture. To a screen reader it is one sentence.
class LunchCardPreview extends StatelessWidget {
  const LunchCardPreview({
    required this.content,
    required this.options,
    required this.inviteHost,
    super.key,
  });

  final LunchCardContent content;
  final LunchCardOptions options;
  final String? inviteHost;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final size = options.format.logicalSize;
    return Semantics(
      container: true,
      image: true,
      label: LunchShareCopy.previewLabel(
        LunchShareCopy.itemList(content.itemNames),
      ),
      child: ExcludeSemantics(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: NestSize.pagesHeight),
            child: AspectRatio(
              aspectRatio: size.aspectRatio,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(NestRadius.lg),
                  boxShadow: nest.shadows.floating,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(NestRadius.lg),
                  child: FittedBox(
                    child: LunchShareCard(
                      content: content,
                      format: options.format,
                      style: options.style,
                      showsInvite: options.showsInvite,
                      inviteHost: inviteHost,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

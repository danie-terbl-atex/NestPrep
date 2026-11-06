import 'package:flutter/widgets.dart';

import '../../../design/nest_kit.dart';
import '../model/chore_picture.dart';

/// A task's picture (todos ADR-0005), or nothing at all for none and for an id
/// this build does not ship. Decoration: the title beside it says the same.
class ChorePictureView extends StatelessWidget {
  const ChorePictureView({
    required this.id,
    this.size = NestSize.stickerSmall,
    this.isFaded = false,
    super.key,
  });

  final String? id;
  final double size;

  /// Done: the picture steps back with the title.
  final bool isFaded;

  static const fadedOpacity = 0.5;

  @override
  Widget build(BuildContext context) {
    final picture = ChorePicture.byId(id);
    if (picture == null) return const SizedBox.shrink();
    return AnimatedOpacity(
      key: ValueKey('chore-picture-${picture.id}'),
      duration: NestMotion.of(context).standard,
      opacity: isFaded ? fadedOpacity : 1,
      child: NestSticker(asset: picture.asset, size: size),
    );
  }
}

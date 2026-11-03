import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../tokens/nest_motion.dart';

/// A photo whose bytes are on their way, faded in over [under] once they
/// arrive (`FE-18`). Bytes the same [bytes] future has already delivered are
/// shown at once, without the fade: a photo carried into its page by a hero,
/// or opened again, never blinks back to [under] on the way.
///
/// The future is remembered, so a source hands out one future per photo.
class NestPhotoBytes extends StatelessWidget {
  const NestPhotoBytes({required this.bytes, required this.under, super.key});

  final Future<Uint8List?> bytes;
  final Widget under;

  static final _delivered = Expando<Uint8List>();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: bytes,
      initialData: _delivered[bytes],
      builder: (context, snapshot) {
        final photo = snapshot.data;
        if (photo != null) _delivered[bytes] = photo;
        return Stack(
          fit: StackFit.expand,
          children: [
            under,
            AnimatedOpacity(
              opacity: photo == null ? 0 : 1,
              duration: NestMotion.of(context).slow,
              curve: NestMotion.enter,
              child: photo == null
                  ? const SizedBox.shrink()
                  : Image.memory(
                      photo,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      excludeFromSemantics: true,
                    ),
            ),
          ],
        );
      },
    );
  }
}

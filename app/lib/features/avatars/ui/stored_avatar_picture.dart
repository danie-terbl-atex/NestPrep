import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../data/avatar_photo_store.dart';

class StoredAvatarPicture extends StatefulWidget {
  const StoredAvatarPicture.made({
    required String this.householdId,
    required String this.memberId,
    required String this.hash,
    required this.label,
    this.aspectRatio = 1,
    super.key,
  }) : path = null;

  const StoredAvatarPicture.original({
    required String this.path,
    required this.label,
    this.aspectRatio = 1,
    super.key,
  }) : householdId = null,
       memberId = null,
       hash = null;

  final String? householdId;
  final String? memberId;
  final String? hash;
  final String? path;
  final String label;
  final double aspectRatio;

  @override
  State<StoredAvatarPicture> createState() => _StoredAvatarPictureState();
}

class _StoredAvatarPictureState extends State<StoredAvatarPicture> {
  Future<Uint8List?>? _bytes;
  String? _asked;

  String get _key =>
      widget.path ?? '${widget.householdId}/${widget.memberId}/${widget.hash}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _follow();
  }

  @override
  void didUpdateWidget(StoredAvatarPicture oldWidget) {
    super.didUpdateWidget(oldWidget);
    _follow();
  }

  void _follow() {
    if (_asked == _key) return;
    _asked = _key;
    final store = context.read<AvatarPhotoStore?>();
    final path = widget.path;
    _bytes = store == null
        ? Future.value()
        : path != null
        ? store.readAt(path)
        : store.read(
            householdId: widget.householdId!,
            memberId: widget.memberId!,
            hash: widget.hash!,
          );
  }

  @override
  Widget build(BuildContext context) {
    final c = NestTheme.of(context).colors;
    return Semantics(
      label: widget.label,
      image: true,
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(NestRadius.lg),
          child: NestPhotoBytes(
            bytes: _bytes ?? Future.value(),
            under: ColoredBox(
              color: c.surfaceTint,
              child: Center(
                child: Icon(
                  LucideIcons.image,
                  color: c.inkTertiary,
                  size: NestSize.iconLarge,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

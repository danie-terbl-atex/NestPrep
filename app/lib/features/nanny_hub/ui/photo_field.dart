import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../data/photo_picker.dart';
import '../model/photo_change.dart';
import 'nanny_photo.dart';

/// A record's photo inside an editing sheet: what it is now, and the three
/// things a person can do to it — take one, choose one, take it away. It only
/// reports the change; the controller stores it when the sheet is saved
/// (`FE-05`).
class PhotoField extends StatefulWidget {
  const PhotoField({
    required this.currentPhotoId,
    required this.label,
    required this.onPick,
    required this.onChanged,
    super.key,
  });

  /// The photo the record has now, if any.
  final String? currentPhotoId;

  /// What the photo shows, for a screen reader.
  final String label;
  final Future<Uint8List?> Function(PhotoSource source) onPick;
  final ValueChanged<PhotoChange> onChanged;

  @override
  State<PhotoField> createState() => _PhotoFieldState();
}

class _PhotoFieldState extends State<PhotoField> {
  PhotoChange _change = const PhotoKept();

  Future<void> _pick(PhotoSource source) async {
    final bytes = await widget.onPick(source);
    if (bytes == null || !mounted) return;
    _set(PhotoPicked(bytes));
  }

  void _set(PhotoChange change) {
    setState(() => _change = change);
    widget.onChanged(change);
  }

  bool get _hasPhoto => switch (_change) {
    PhotoKept() => widget.currentPhotoId != null,
    PhotoPicked() => true,
    PhotoRemoved() => false,
  };

  @override
  Widget build(BuildContext context) {
    final current = widget.currentPhotoId;
    final preview = switch (_change) {
      PhotoPicked(:final bytes) => ClipRRect(
        borderRadius: BorderRadius.circular(NestRadius.lg),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Semantics(
            image: true,
            label: widget.label,
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
      PhotoKept() when current != null => NannyPhoto(
        photoId: current,
        label: widget.label,
      ),
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?preview,
        if (preview != null) const SizedBox(height: NestSpace.sm),
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            NestChip(
              label: NannyCopy.takePhoto,
              icon: LucideIcons.camera,
              onTap: () => _pick(PhotoSource.camera),
            ),
            NestChip(
              label: NannyCopy.choosePhoto,
              icon: LucideIcons.images,
              onTap: () => _pick(PhotoSource.library),
            ),
            if (_hasPhoto)
              NestChip(
                label: NannyCopy.removePhoto,
                icon: LucideIcons.trash2,
                onTap: () => _set(const PhotoRemoved()),
              ),
          ],
        ),
      ],
    );
  }
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/photos/compressed_photo.dart';
import '../data/avatar_photo_picker.dart';
import '../model/avatar_studio.dart';
import '../state/avatar_photo_crop.dart';

class PhotoTab extends StatefulWidget {
  const PhotoTab({
    required this.studio,
    required this.isSaving,
    required this.onSave,
    super.key,
  });

  final AvatarStudio studio;
  final bool isSaving;
  final Future<void> Function(Uint8List jpeg) onSave;

  @override
  State<PhotoTab> createState() => _PhotoTabState();
}

class _PhotoTabState extends State<PhotoTab> {
  CompressedPhoto? _picked;
  Rect _area = const Rect.fromLTWH(0, 0, 1, 1);
  bool _isWorking = false;
  AppFailure? _failure;

  AvatarPhotoCrop get _crop =>
      context.read<AvatarPhotoCrop?>() ?? const AvatarPhotoCrop();

  Future<void> _pick(AvatarPhotoSource source) async {
    final picker = context.read<AvatarPhotoPicker>();
    final crop = _crop;
    setState(() {
      _isWorking = true;
      _failure = null;
    });
    try {
      final original = await picker.pick(source);
      final upright = original == null ? null : await crop.upright(original);
      if (!mounted) return;
      setState(() => _picked = upright);
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _use(CompressedPhoto picked) async {
    final crop = _crop;
    setState(() {
      _isWorking = true;
      _failure = null;
    });
    try {
      final square = await crop.crop(picked.bytes, _area);
      await widget.onSave(square.bytes);
      if (mounted) setState(() => _picked = null);
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final picked = _picked;
    final busy = _isWorking || widget.isSaving;
    final failure = _failure;
    final banner = failure == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.lg),
            child: NestBanner(
              message: AppCopy.failure(failure),
              tone: NestBannerTone.danger,
              actionLabel: AppCopy.back,
              onAction: () => setState(() => _failure = null),
            ),
          );
    if (picked != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?banner,
          Text(AvatarCopy.cropTitle, style: nest.text.title),
          const SizedBox(height: NestSpace.xs),
          Text(AvatarCopy.cropHint, style: nest.text.bodySecondary),
          const SizedBox(height: NestSpace.lg),
          NestCircleCropper(
            image: MemoryImage(picked.bytes),
            imageSize: Size(picked.width.toDouble(), picked.height.toDouble()),
            label: AvatarCopy.cropTitle,
            onArea: (area) => _area = area,
          ),
          const SizedBox(height: NestSpace.xl),
          NestButton(
            label: widget.isSaving
                ? AvatarCopy.savingPhoto
                : AvatarCopy.usePhoto,
            icon: LucideIcons.check,
            isLoading: busy,
            onPressed: busy ? null : () => _use(picked),
          ),
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: AvatarCopy.tryAnother,
            variant: NestButtonVariant.outline,
            onPressed: busy ? null : () => setState(() => _picked = null),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?banner,
        Text(AvatarCopy.photoBody, style: nest.text.bodySecondary),
        const SizedBox(height: NestSpace.lg),
        NestButton(
          label: AvatarCopy.takePhoto,
          icon: LucideIcons.camera,
          isLoading: busy,
          onPressed: busy ? null : () => _pick(AvatarPhotoSource.camera),
        ),
        const SizedBox(height: NestSpace.sm),
        NestButton(
          label: AvatarCopy.choosePhoto,
          icon: LucideIcons.images,
          variant: NestButtonVariant.outline,
          onPressed: busy ? null : () => _pick(AvatarPhotoSource.library),
        ),
      ],
    );
  }
}

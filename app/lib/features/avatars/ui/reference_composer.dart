import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/photos/compressed_photo.dart';
import '../data/avatar_photo_picker.dart';
import '../model/avatar_creation.dart';
import '../state/creation_reference.dart';
import 'creation_disclosure.dart';
import 'creation_style_picker.dart';

class ReferenceComposer extends StatefulWidget {
  const ReferenceComposer({
    required this.recipe,
    required this.onMake,
    required this.onBack,
    super.key,
  });

  final CreationRecipe recipe;
  final Future<void> Function(CreationStyle style, Uint8List jpeg) onMake;
  final VoidCallback onBack;

  @override
  State<ReferenceComposer> createState() => _ReferenceComposerState();
}

class _ReferenceComposerState extends State<ReferenceComposer> {
  CreationStyle _style = CreationStyle.plush;
  CompressedPhoto? _picked;
  bool _isWorking = false;
  AppFailure? _failure;

  Future<void> _pick(AvatarPhotoSource source) async {
    final picker = context.read<AvatarPhotoPicker>();
    final reference =
        context.read<CreationReference?>() ?? const CreationReference();
    setState(() {
      _isWorking = true;
      _failure = null;
    });
    try {
      final original = await picker.pick(source, facingUser: false);
      final prepared = original == null
          ? null
          : await reference.prepare(original);
      if (mounted && prepared != null) setState(() => _picked = prepared);
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _make(CompressedPhoto picked) async {
    setState(() => _isWorking = true);
    try {
      await widget.onMake(_style, picked.bytes);
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final picked = _picked;
    final failure = _failure;
    final recipe = widget.recipe;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: NestButton(
            label: AvatarCreationCopy.pickSomethingElse,
            icon: LucideIcons.arrowLeft,
            variant: NestButtonVariant.ghost,
            size: NestButtonSize.small,
            isExpanded: false,
            onPressed: _isWorking ? null : widget.onBack,
          ),
        ),
        const SizedBox(height: NestSpace.sm),
        Text(AvatarCreationCopy.recipeTitle(recipe), style: nest.text.title),
        const SizedBox(height: NestSpace.xs),
        Text(
          AvatarCreationCopy.recipeBody(recipe),
          style: nest.text.bodySecondary,
        ),
        const SizedBox(height: NestSpace.xl),
        CreationStylePicker(
          selected: _style,
          onPick: (style) => setState(() => _style = style),
        ),
        const SizedBox(height: NestSpace.xxl),
        NestSectionHeader(title: AvatarCreationCopy.photoTitle(recipe)),
        const SizedBox(height: NestSpace.sm),
        if (failure != null) ...[
          NestBanner(
            message: AppCopy.failure(failure),
            tone: NestBannerTone.danger,
            actionLabel: AppCopy.back,
            onAction: () => setState(() => _failure = null),
          ),
          const SizedBox(height: NestSpace.md),
        ],
        if (picked == null) ...[
          Text(
            AvatarCreationCopy.photoHint(recipe),
            style: nest.text.bodySecondary,
          ),
          const SizedBox(height: NestSpace.md),
          const CreationDisclosure(
            message: AvatarCreationCopy.pictureDisclosure,
          ),
          const SizedBox(height: NestSpace.lg),
          NestButton(
            label: AvatarCopy.takePhoto,
            icon: LucideIcons.camera,
            isLoading: _isWorking,
            onPressed: _isWorking
                ? null
                : () => _pick(AvatarPhotoSource.camera),
          ),
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: AvatarCopy.choosePhoto,
            icon: LucideIcons.images,
            variant: NestButtonVariant.outline,
            onPressed: _isWorking
                ? null
                : () => _pick(AvatarPhotoSource.library),
          ),
        ] else ...[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: NestSize.previewHeight,
              ),
              child: AspectRatio(
                aspectRatio: picked.width / picked.height,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(NestRadius.lg),
                  child: Image.memory(
                    picked.bytes,
                    fit: BoxFit.cover,
                    semanticLabel: AvatarCreationCopy.pickedLabel(recipe),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: NestSpace.xl),
          NestButton(
            label: AvatarCreationCopy.makeIt,
            icon: LucideIcons.sparkles,
            isLoading: _isWorking,
            onPressed: _isWorking ? null : () => _make(picked),
          ),
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: AvatarCopy.tryAnother,
            variant: NestButtonVariant.outline,
            onPressed: _isWorking ? null : () => setState(() => _picked = null),
          ),
        ],
      ],
    );
  }
}

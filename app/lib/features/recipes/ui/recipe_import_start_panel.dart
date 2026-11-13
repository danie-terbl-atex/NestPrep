import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/failure/app_failure.dart';
import '../../list_scan/data/list_photo_picker.dart';
import '../../photo_frames/model/shared_page.dart';
import '../data/page_link.dart';

class RecipeImportLinkPanel extends StatefulWidget {
  const RecipeImportLinkPanel({
    required this.initial,
    required this.failure,
    required this.isAiWelcome,
    required this.onRead,
    super.key,
  });

  final String initial;
  final AppFailure? failure;
  final bool isAiWelcome;
  final ValueChanged<String> onRead;

  @override
  State<RecipeImportLinkPanel> createState() => _RecipeImportLinkPanelState();
}

class _RecipeImportLinkPanelState extends State<RecipeImportLinkPanel> {
  late final _text = TextEditingController(text: widget.initial);
  bool _isRefused = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final pasted = await Clipboard.getData(Clipboard.kTextPlain);
    final text = pasted?.text;
    if (text == null || !mounted) return;
    setState(() {
      _text.text = SharedPage.firstWebLink(text) ?? text.trim();
      _isRefused = false;
    });
  }

  void _read() {
    final entered = _text.text.trim();
    final link = SharedPage.firstWebLink(entered) ?? entered;
    if (!isPublicPageLink(link)) {
      setState(() => _isRefused = true);
      return;
    }
    widget.onRead(link);
  }

  @override
  Widget build(BuildContext context) => _StartList(
    failure: widget.failure,
    hero: _Hero(
      isAiWelcome: widget.isAiWelcome,
      icon: LucideIcons.link,
      title: RecipeImportCopy.linkHeroTitle,
      body: RecipeImportCopy.linkHeroBody,
    ),
    privacy: RecipeImportCopy.linkPrivacyBody,
    actions: [
      NestTextField(
        key: const ValueKey('recipe-import-link'),
        label: RecipeImportCopy.linkLabel,
        hint: RecipeImportCopy.linkHint,
        controller: _text,
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.go,
        textCapitalization: TextCapitalization.none,
        errorText: _isRefused ? RecipeImportCopy.notAPublicLink : null,
        onChanged: (_) {
          if (_isRefused) setState(() => _isRefused = false);
        },
        onSubmitted: (_) => _read(),
      ),
      const SizedBox(height: NestSpace.sm),
      NestButton(
        key: const ValueKey('recipe-import-paste'),
        label: RecipeImportCopy.paste,
        icon: LucideIcons.clipboardPaste,
        variant: NestButtonVariant.outline,
        onPressed: _paste,
      ),
      const SizedBox(height: NestSpace.sm),
      NestButton(
        key: const ValueKey('recipe-import-read'),
        label: RecipeImportCopy.read,
        icon: LucideIcons.sparkles,
        onPressed: _read,
      ),
    ],
  );
}

class RecipeImportSnapPanel extends StatelessWidget {
  const RecipeImportSnapPanel({
    required this.failure,
    required this.isAiWelcome,
    required this.onPick,
    super.key,
  });

  final AppFailure? failure;
  final bool isAiWelcome;
  final ValueChanged<ListPhotoSource> onPick;

  @override
  Widget build(BuildContext context) => _StartList(
    failure: failure,
    hero: _Hero(
      isAiWelcome: isAiWelcome,
      icon: LucideIcons.camera,
      title: RecipeImportCopy.snapHeroTitle,
      body: RecipeImportCopy.snapHeroBody,
    ),
    privacy: RecipeImportCopy.photoPrivacyBody,
    actions: [
      NestButton(
        key: const ValueKey('recipe-import-camera'),
        label: RecipeImportCopy.takePhoto,
        icon: LucideIcons.camera,
        onPressed: () => onPick(ListPhotoSource.camera),
      ),
      const SizedBox(height: NestSpace.sm),
      NestButton(
        key: const ValueKey('recipe-import-photos'),
        label: RecipeImportCopy.choosePhoto,
        icon: LucideIcons.images,
        variant: NestButtonVariant.tonal,
        onPressed: () => onPick(ListPhotoSource.photos),
      ),
    ],
  );
}

class _StartList extends StatelessWidget {
  const _StartList({
    required this.failure,
    required this.hero,
    required this.actions,
    required this.privacy,
  });

  final AppFailure? failure;
  final Widget hero;
  final List<Widget> actions;
  final String privacy;

  @override
  Widget build(BuildContext context) {
    final shown = failure;
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        if (shown != null) ...[
          NestBanner(
            message: AppCopy.failure(shown),
            tone: NestBannerTone.danger,
          ),
          const SizedBox(height: NestSpace.lg),
        ],
        NestRiseIn(child: hero),
        const SizedBox(height: NestSpace.xl),
        NestRiseIn(
          index: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: actions,
          ),
        ),
        const SizedBox(height: NestSpace.xl),
        NestRiseIn(
          index: 2,
          child: NestToneRow(
            key: const ValueKey('recipe-import-privacy'),
            icon: LucideIcons.lock,
            title: RecipeImportCopy.privacyTitle,
            subtitle: privacy,
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.isAiWelcome,
    required this.icon,
    required this.title,
    required this.body,
  });

  final bool isAiWelcome;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return NestCard(
      variant: NestCardVariant.tinted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAiWelcome)
            const NestTwig(pose: NestTwigPose.welcome, size: NestSize.twigLarge)
          else
            NestIconTile(icon: icon, tint: NestTileTint.basil),
          const SizedBox(height: NestSpace.md),
          Text(title, style: nest.text.title.copyWith(color: nest.colors.ink)),
          const SizedBox(height: NestSpace.sm),
          Text(
            body,
            style: nest.text.body.copyWith(color: nest.colors.inkSecondary),
          ),
        ],
      ),
    );
  }
}

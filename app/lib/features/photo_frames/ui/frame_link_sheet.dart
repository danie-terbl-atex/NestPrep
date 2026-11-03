import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../kid_accounts/ui/kid_code_field.dart';
import '../data/photo_frame_directory.dart';
import '../state/frame_link_controller.dart';
import '../state/photo_frames_controller.dart';
import 'frame_name_field.dart';
import 'frame_panels_editor.dart';
import 'frame_scanner.dart';

Future<void> showFrameLinkSheet({
  required BuildContext context,
  required PhotoFramesController controller,
}) {
  final directory = context.read<PhotoFrameDirectory>();
  final scanner = context.read<FrameScanner>();
  return showNestSheet<void>(
    context: context,
    title: PhotoFrameCopy.link,
    builder: (_) => ChangeNotifierProvider(
      create: (_) => FrameLinkController(
        photoFrameDirectory: directory,
        householdId: controller.householdId,
        helpers: controller.helpers,
      ),
      child: _LinkSheetBody(scanner: scanner),
    ),
  );
}

class _LinkSheetBody extends StatefulWidget {
  const _LinkSheetBody({required this.scanner});

  final FrameScanner scanner;

  @override
  State<_LinkSheetBody> createState() => _LinkSheetBodyState();
}

class _LinkSheetBodyState extends State<_LinkSheetBody> {
  final TextEditingController _name = TextEditingController(
    text: PhotoFrameCopy.defaultName,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final link = context.watch<FrameLinkController>();
    final beat = switch (link.step) {
      FrameLinkStep.code when link.isTyping => _TypeCode(link: link),
      FrameLinkStep.code => _ScanCode(link: link, scanner: widget.scanner),
      FrameLinkStep.details => _Details(
        link: link,
        name: _name,
        onNameChanged: () => setState(() {}),
      ),
      FrameLinkStep.linked => const _Linked(),
    };
    return SingleChildScrollView(
      child: AnimatedSwitcher(
        duration: NestMotion.of(context).standard,
        child: KeyedSubtree(
          key: ValueKey((link.step, link.isTyping)),
          child: beat,
        ),
      ),
    );
  }
}

class _ScanCode extends StatelessWidget {
  const _ScanCode({required this.link, required this.scanner});

  final FrameLinkController link;
  final FrameScanner scanner;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(PhotoFrameCopy.scanBody, style: nest.text.bodySecondary),
        const SizedBox(height: NestSpace.lg),
        ClipRRect(
          borderRadius: BorderRadius.circular(NestRadius.lg),
          child: SizedBox(
            height: NestSize.previewHeight,
            child: scanner.build(onScanned: link.scanned),
          ),
        ),
        if (link.scanWasNotOurs) ...[
          const SizedBox(height: NestSpace.lg),
          const NestBanner(
            message: PhotoFrameCopy.notAFrameCode,
            tone: NestBannerTone.warning,
          ),
        ],
        const SizedBox(height: NestSpace.lg),
        NestButton(
          label: PhotoFrameCopy.typeInstead,
          icon: LucideIcons.keyboard,
          variant: NestButtonVariant.ghost,
          onPressed: link.typeInstead,
        ),
      ],
    );
  }
}

class _TypeCode extends StatelessWidget {
  const _TypeCode({required this.link});

  final FrameLinkController link;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(PhotoFrameCopy.typeBody, style: nest.text.bodySecondary),
        const SizedBox(height: NestSpace.lg),
        KidCodeField(
          code: link.typedCode,
          label: PhotoFrameCopy.codeFieldLabel,
          onChanged: link.setTypedCode,
          onSubmitted: link.useTypedCode,
        ),
        const SizedBox(height: NestSpace.xl),
        NestButton(
          label: PhotoFrameCopy.next,
          icon: LucideIcons.arrowRight,
          onPressed: link.canUseTypedCode ? link.useTypedCode : null,
        ),
        const SizedBox(height: NestSpace.sm),
        NestButton(
          label: PhotoFrameCopy.scanInstead,
          icon: LucideIcons.scanQrCode,
          variant: NestButtonVariant.ghost,
          onPressed: link.scanInstead,
        ),
      ],
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.link,
    required this.name,
    required this.onNameChanged,
  });

  final FrameLinkController link;
  final TextEditingController name;
  final VoidCallback onNameChanged;

  @override
  Widget build(BuildContext context) {
    final failure = link.failure;
    final canLink =
        PhotoFramesController.isValidName(name.text) &&
        link.panels.showsAnything;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (failure != null) ...[
          NestBanner(
            message: AppCopy.failure(failure),
            tone: NestBannerTone.danger,
          ),
          const SizedBox(height: NestSpace.lg),
        ],
        NestListRow(
          title: PhotoFrameCopy.codeFound(link.code ?? ''),
          leading: const NestIconTile(
            icon: LucideIcons.tvMinimal,
            tint: NestTileTint.butter,
            size: NestSize.avatarMedium,
          ),
        ),
        const SizedBox(height: NestSpace.lg),
        FrameNameField(
          controller: name,
          enabled: !link.isLinking,
          onChanged: onNameChanged,
        ),
        const SizedBox(height: NestSpace.xl),
        FramePanelsEditor(
          panels: link.panels,
          helpers: link.helpers,
          onChanged: link.isLinking ? null : link.setPanels,
        ),
        const SizedBox(height: NestSpace.xl),
        NestButton(
          label: PhotoFrameCopy.linkAction,
          icon: LucideIcons.link,
          isLoading: link.isLinking,
          onPressed: canLink ? () => link.link(name.text) : null,
        ),
        const SizedBox(height: NestSpace.sm),
        NestButton(
          label: PhotoFrameCopy.differentCode,
          variant: NestButtonVariant.ghost,
          onPressed: link.isLinking ? null : link.differentCode,
        ),
      ],
    );
  }
}

class _Linked extends StatelessWidget {
  const _Linked();

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const NestRiseIn(
          child: Center(
            child: NestIconTile(
              icon: LucideIcons.partyPopper,
              tint: NestTileTint.basil,
              size: NestSize.mark,
              iconSize: NestSize.iconMark,
            ),
          ),
        ),
        const SizedBox(height: NestSpace.lg),
        Text(
          PhotoFrameCopy.linked,
          textAlign: TextAlign.center,
          style: nest.text.headline,
        ),
        const SizedBox(height: NestSpace.xl),
        NestButton(
          label: PhotoFrameCopy.done,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

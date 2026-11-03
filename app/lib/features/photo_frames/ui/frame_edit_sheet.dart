import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../add_to_checkers/data/checkers_area_preference.dart';
import '../../add_to_checkers/model/checkers_area.dart';
import '../../add_to_checkers/model/retailer_switch.dart';
import '../../groceries/model/product_match.dart';
import '../model/frame_groceries.dart';
import '../model/frame_panels.dart';
import '../model/frame_screensaver.dart';
import '../model/photo_frame.dart';
import '../state/photo_frames_controller.dart';
import 'frame_groceries_editor.dart';
import 'frame_name_field.dart';
import 'frame_panels_editor.dart';
import 'frame_screensaver_editor.dart';

Future<void> showFrameEditSheet({
  required BuildContext context,
  required PhotoFramesController controller,
  required PhotoFrame frame,
  required bool albumIsEmpty,
}) async {
  controller.openSheet();
  await showNestSheet<void>(
    context: context,
    title: PhotoFrameCopy.editTitle,
    builder: (_) => ChangeNotifierProvider.value(
      value: controller,
      child: _EditSheetBody(frame: frame, albumIsEmpty: albumIsEmpty),
    ),
  );
  controller.closeSheet();
}

class _EditSheetBody extends StatefulWidget {
  const _EditSheetBody({required this.frame, required this.albumIsEmpty});

  final PhotoFrame frame;
  final bool albumIsEmpty;

  @override
  State<_EditSheetBody> createState() => _EditSheetBodyState();
}

class _EditSheetBodyState extends State<_EditSheetBody> {
  late final TextEditingController _name = TextEditingController(
    text: widget.frame.name,
  );
  late FramePanels _panels = widget.frame.panels;
  late FrameScreensaver _screensaver = widget.frame.screensaver;
  late FrameGroceries? _groceries = widget.frame.groceries;
  late final Future<CheckersArea?> _phoneArea;

  @override
  void initState() {
    super.initState();
    _phoneArea = Future.value(
      context.read<CheckersAreaPreference?>()?.read(
        context.read<PhotoFramesController>().householdId,
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save(PhotoFramesController controller) async {
    final saved = await controller.save(
      widget.frame,
      name: _name.text,
      panels: _panels,
      screensaver: _screensaver,
      groceries: _groceries,
    );
    if (saved && mounted) Navigator.of(context).pop();
  }

  Future<void> _unlink(PhotoFramesController controller) async {
    final confirmed = await showNestConfirm(
      context: context,
      title: PhotoFrameCopy.unlinkConfirm,
      message: PhotoFrameCopy.unlinkBody(widget.frame.name),
      confirmLabel: PhotoFrameCopy.unlink,
      cancelLabel: PhotoFrameCopy.keep,
      isDangerous: true,
    );
    if (confirmed != true) return;
    final unlinked = await controller.unlink(widget.frame);
    if (unlinked && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PhotoFramesController>();
    final failure = controller.actionFailure;
    final isSaving = controller.isSaving;
    final flags = context.watch<FeatureFlagsController?>();
    final shops = flags == null
        ? const <ProductRetailer>[]
        : shopsOn(flags.isOn);
    final canSave =
        PhotoFramesController.isValidName(_name.text) && _panels.showsAnything;
    return SingleChildScrollView(
      child: Column(
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
          FrameNameField(
            controller: _name,
            enabled: !isSaving,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: NestSpace.xl),
          FramePanelsEditor(
            panels: _panels,
            helpers: controller.helpers,
            onChanged: isSaving
                ? null
                : (panels) => setState(() => _panels = panels),
          ),
          FutureBuilder(
            future: _phoneArea,
            builder: (context, phoneArea) => FrameGroceriesEditor(
              groceries: _groceries,
              shopsOn: shops,
              defaultArea: phoneArea.data ?? CheckersArea.fallback,
              onChanged: isSaving
                  ? null
                  : (groceries) => setState(() => _groceries = groceries),
            ),
          ),
          const SizedBox(height: NestSpace.xl),
          FrameScreensaverEditor(
            screensaver: _screensaver,
            albumIsEmpty: widget.albumIsEmpty,
            onChanged: isSaving
                ? null
                : (screensaver) => setState(() => _screensaver = screensaver),
          ),
          const SizedBox(height: NestSpace.xl),
          NestButton(
            label: PhotoFrameCopy.save,
            isLoading: isSaving,
            onPressed: canSave ? () => _save(controller) : null,
          ),
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: PhotoFrameCopy.unlink,
            icon: LucideIcons.unlink,
            variant: NestButtonVariant.ghost,
            onPressed: isSaving ? null : () => _unlink(controller),
          ),
        ],
      ),
    );
  }
}

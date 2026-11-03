import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/photo_frame_copy.dart';
import '../state/photo_frames_controller.dart';

class FrameNameField extends StatelessWidget {
  const FrameNameField({
    required this.controller,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: NestTextField(
        label: PhotoFrameCopy.nameLabel,
        controller: controller,
        enabled: enabled,
        textInputAction: TextInputAction.done,
        inputFormatters: [
          LengthLimitingTextInputFormatter(PhotoFramesController.nameMaxLength),
        ],
        onChanged: (_) => onChanged(),
      ),
    );
  }
}

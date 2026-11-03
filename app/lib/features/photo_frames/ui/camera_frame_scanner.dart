import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/photo_frame_copy.dart';
import 'frame_scanner.dart';

final class CameraFrameScanner implements FrameScanner {
  const CameraFrameScanner();

  @override
  Widget build({required ValueChanged<String> onScanned}) => MobileScanner(
    onDetect: (capture) {
      final raw = capture.barcodes
          .map((barcode) => barcode.rawValue)
          .nonNulls
          .firstOrNull;
      if (raw != null) onScanned(raw);
    },
    errorBuilder: (context, error) => _CameraProblem(
      message: error.errorCode == MobileScannerErrorCode.permissionDenied
          ? PhotoFrameCopy.cameraRefused
          : PhotoFrameCopy.cameraUnavailable,
    ),
  );
}

class _CameraProblem extends StatelessWidget {
  const _CameraProblem({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return ColoredBox(
      color: nest.colors.surfaceTint,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(NestSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const NestIconTile(
                icon: LucideIcons.cameraOff,
                tint: NestTileTint.lilac,
              ),
              const SizedBox(height: NestSpace.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: nest.text.bodySecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

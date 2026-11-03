import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/photo_frame_copy.dart';
import '../model/frame_screensaver.dart';

class FrameScreensaverEditor extends StatelessWidget {
  const FrameScreensaverEditor({
    required this.screensaver,
    required this.albumIsEmpty,
    required this.onChanged,
    super.key,
  });

  final FrameScreensaver screensaver;
  final bool albumIsEmpty;
  final ValueChanged<FrameScreensaver>? onChanged;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final change = onChanged;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(PhotoFrameCopy.screensaverTitle, style: nest.text.label),
        const SizedBox(height: NestSpace.xs),
        Text(PhotoFrameCopy.screensaverBody, style: nest.text.caption),
        const SizedBox(height: NestSpace.md),
        _Choices(
          values: FrameScreensaver.idleMinuteChoices,
          selected: screensaver.idleMinutes,
          label: (minutes) => minutes == 0
              ? PhotoFrameCopy.screensaverOff
              : PhotoFrameCopy.idleMinutes(minutes),
          semanticLabel: (minutes) => minutes == 0
              ? PhotoFrameCopy.screensaverOffLabel
              : PhotoFrameCopy.idleMinutesLabel(minutes),
          onSelected: change == null
              ? null
              : (minutes) => change(
                  minutes == 0
                      ? FrameScreensaver.off
                      : screensaver.copyWith(idleMinutes: minutes),
                ),
        ),
        if (screensaver.isOn) ...[
          const SizedBox(height: NestSpace.lg),
          Text(PhotoFrameCopy.eachPhoto, style: nest.text.label),
          const SizedBox(height: NestSpace.sm),
          _Choices(
            values: FrameScreensaver.secondsPerPhotoChoices,
            selected: screensaver.secondsPerPhoto,
            label: PhotoFrameCopy.seconds,
            semanticLabel: PhotoFrameCopy.secondsLabel,
            onSelected: change == null
                ? null
                : (seconds) =>
                      change(screensaver.copyWith(secondsPerPhoto: seconds)),
          ),
          if (albumIsEmpty) ...[
            const SizedBox(height: NestSpace.md),
            const NestBanner(
              message: PhotoFrameCopy.screensaverNeedsPhotos,
              tone: NestBannerTone.warning,
            ),
          ],
        ],
      ],
    );
  }
}

class _Choices extends StatelessWidget {
  const _Choices({
    required this.values,
    required this.selected,
    required this.label,
    required this.semanticLabel,
    required this.onSelected,
  });

  final List<int> values;
  final int selected;
  final String Function(int value) label;
  final String Function(int value) semanticLabel;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    final select = onSelected;
    return Wrap(
      spacing: NestSpace.sm,
      runSpacing: NestSpace.sm,
      children: [
        for (final value in values)
          NestChip(
            key: ValueKey(value),
            label: label(value),
            semanticLabel: semanticLabel(value),
            isSelected: value == selected,
            onTap: select == null ? null : () => select(value),
          ),
      ],
    );
  }
}

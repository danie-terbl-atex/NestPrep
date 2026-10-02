import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/spot_mark.dart';
import 'marked_photo.dart';

/// Opens the photo full screen to circle the spot with a finger, and comes
/// back with the marks — or null when the person backed out, leaving the
/// marks they had (home-care ADR-0001).
Future<List<SpotMark>?> showSpotMarker({
  required BuildContext context,
  required Uint8List bytes,
  required double aspectRatio,
  required List<SpotMark> marks,
}) => Navigator.of(context).push(
  MaterialPageRoute<List<SpotMark>>(
    fullscreenDialog: true,
    builder: (context) =>
        SpotMarkerScreen(bytes: bytes, aspectRatio: aspectRatio, marks: marks),
  ),
);

class SpotMarkerScreen extends StatefulWidget {
  const SpotMarkerScreen({
    required this.bytes,
    required this.aspectRatio,
    required this.marks,
    super.key,
  });

  final Uint8List bytes;
  final double aspectRatio;
  final List<SpotMark> marks;

  @override
  State<SpotMarkerScreen> createState() => _SpotMarkerScreenState();
}

class _SpotMarkerScreenState extends State<SpotMarkerScreen> {
  late List<SpotMark> _marks = [...widget.marks];
  List<Offset> _drawing = const [];

  bool get _isFull => _marks.length >= SpotMark.limit;

  void _start(Offset point) {
    if (_isFull) return;
    setState(() => _drawing = [point]);
  }

  void _extend(Offset point) {
    if (_drawing.isEmpty) return;
    setState(() => _drawing = [..._drawing, point]);
  }

  void _finish(Size size) {
    if (_drawing.isEmpty) return;
    setState(() {
      _marks = [..._marks, SpotMark.fromOffsets(_drawing, size)];
      _drawing = const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return NestScaffold(
      title: HomeCareCopy.markTitle,
      subtitle: HomeCareCopy.markHint,
      leading: NestIconButton(
        icon: LucideIcons.x,
        label: HomeCareCopy.markCancel,
        variant: NestIconButtonVariant.plain,
        onPressed: () => Navigator.of(context).pop(),
      ),
      trailing: [
        NestIconButton(
          icon: LucideIcons.undo2,
          label: HomeCareCopy.markUndo,
          onPressed: _marks.isEmpty
              ? null
              : () => setState(
                  () => _marks = _marks.sublist(0, _marks.length - 1),
                ),
        ),
        NestIconButton(
          icon: LucideIcons.eraser,
          label: HomeCareCopy.markClear,
          onPressed: _marks.isEmpty ? null : () => setState(() => _marks = []),
        ),
      ],
      floatingAction: NestButton(
        label: HomeCareCopy.markDone,
        icon: LucideIcons.check,
        isExpanded: false,
        onPressed: () => Navigator.of(context).pop(_marks),
      ),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final fitsWidth = width / widget.aspectRatio <= height;
            final size = fitsWidth
                ? Size(width, width / widget.aspectRatio)
                : Size(height * widget.aspectRatio, height);
            return SizedBox.fromSize(
              size: size,
              child: Semantics(
                label: HomeCareCopy.markSurface(_marks.length),
                child: GestureDetector(
                  onPanStart: (details) => _start(details.localPosition),
                  onPanUpdate: (details) => _extend(details.localPosition),
                  onPanEnd: (_) => _finish(size),
                  onTapUp: (details) {
                    _start(details.localPosition);
                    _finish(size);
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(NestRadius.lg),
                      boxShadow: nest.shadows.card,
                    ),
                    child: MarkedPhoto(
                      bytes: widget.bytes,
                      aspectRatio: widget.aspectRatio,
                      marks: _marks,
                      drawing: _drawing,
                      semanticLabel: HomeCareCopy.beforePhoto,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

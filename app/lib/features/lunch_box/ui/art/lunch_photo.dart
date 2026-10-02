import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../design/nest_kit.dart';
import '../../../../shared/time/calendar_date.dart';
import '../../../household/model/household_view.dart';
import '../../../subscriptions/state/household_entitlement.dart';
import '../../data/lunch_photo_source.dart';
import '../../model/lunch_box.dart';
import '../../model/lunch_slot.dart';
import 'lunch_box_art.dart';
import 'lunch_glyph.dart';

/// What fills a lunch's photo frame (lunch-box ADR-0015): the drawn box on a
/// warm ground tinted by its main, and for a premium household the AI photo
/// of that exact box faded in over it once it arrives. Always in the light
/// palette, as a photo would be: the food brings the colour in both themes.
/// Sizes itself to the frame it is given.
class LunchPhoto extends StatefulWidget {
  const LunchPhoto({
    required this.box,
    required this.childId,
    required this.date,
    super.key,
  });

  final LunchBox box;
  final String childId;
  final CalendarDate date;

  static final _light = nestThemeData(NestTheme.light());

  @override
  State<LunchPhoto> createState() => _LunchPhotoState();
}

class _LunchPhotoState extends State<LunchPhoto> {
  Future<Uint8List?>? _photo;
  String? _askedFor;

  String get _signature => [
    for (final (slot, pick) in widget.box.filled) '${slot.name}:${pick.itemId}',
  ].join(',');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ask(isPremium: context.watch<HouseholdEntitlement?>()?.isPremium ?? false);
  }

  @override
  void didUpdateWidget(LunchPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ask(isPremium: context.read<HouseholdEntitlement?>()?.isPremium ?? false);
  }

  void _ask({required bool isPremium}) {
    final source = context.read<LunchPhotoSource?>();
    final householdId = context.read<HouseholdView?>()?.household.id;
    final ask = '${widget.childId}/${widget.date.iso}/$_signature';
    if (source == null ||
        householdId == null ||
        !isPremium ||
        widget.box.isEmpty) {
      _photo = null;
      _askedFor = null;
      return;
    }
    if (ask == _askedFor) return;
    _askedFor = ask;
    _photo = source.photoFor(
      householdId: householdId,
      childId: widget.childId,
      date: widget.date,
      signature: _signature,
    );
  }

  @override
  Widget build(BuildContext context) {
    final photo = _photo;
    final art = Theme(
      data: LunchPhoto._light,
      child: _LunchPhotoArt(box: widget.box),
    );
    if (photo == null) return art;
    return FutureBuilder<Uint8List?>(
      future: photo,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        return Stack(
          fit: StackFit.expand,
          children: [
            art,
            AnimatedOpacity(
              opacity: bytes == null ? 0 : 1,
              duration: NestMotion.of(context).slow,
              curve: NestMotion.enter,
              child: bytes == null
                  ? const SizedBox.shrink()
                  : Image.memory(
                      bytes,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _LunchPhotoArt extends StatelessWidget {
  const _LunchPhotoArt({required this.box});

  final LunchBox box;

  @override
  Widget build(BuildContext context) {
    final colors = NestTheme.of(context).colors;
    final lead = box.filled.isEmpty ? LunchSlot.fruit : box.filled.first.$1;
    return ColoredBox(
      color: slotFill(colors, lead),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = (constraints.maxHeight * 0.62).clamp(
            0.0,
            constraints.maxWidth * 0.8 / LunchBoxArt.aspect,
          );
          return Center(
            child: LunchBoxArt(box: box, height: height),
          );
        },
      ),
    );
  }
}

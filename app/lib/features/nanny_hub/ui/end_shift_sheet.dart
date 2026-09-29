import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/nanny_limits.dart';

/// Asks before a shift ends — it cannot be added to afterwards — with room for
/// a last word to the parents. Answers the closing note ('' for none), or
/// null when the carer changed their mind.
Future<String?> showEndShiftSheet({required BuildContext context}) =>
    showNestSheet<String>(
      context: context,
      title: NannyCopy.endShiftTitle,
      builder: (_) => const _EndShiftBody(),
    );

class _EndShiftBody extends StatefulWidget {
  const _EndShiftBody();

  @override
  State<_EndShiftBody> createState() => _EndShiftBodyState();
}

class _EndShiftBodyState extends State<_EndShiftBody> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(NannyCopy.endShiftBody, style: nest.text.bodySecondary),
          const SizedBox(height: NestSpace.lg),
          NestTextField(
            label: NannyCopy.closingNote,
            hint: NannyCopy.closingNoteHint,
            controller: _note,
            maxLines: 3,
            inputFormatters: [
              LengthLimitingTextInputFormatter(NannyLimits.entryNote),
            ],
          ),
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: NannyCopy.endShift,
            icon: Icons.nights_stay_outlined,
            onPressed: () => Navigator.of(context).pop(_note.text),
          ),
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: NannyCopy.cancel,
            variant: NestButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

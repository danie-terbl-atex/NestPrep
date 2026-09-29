import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/nanny_limits.dart';

/// What the care-notes sheet collected. Null from `showCareNotesSheet` means
/// the person closed it without saving.
typedef CareNotes = ({String? settling, String? goodToKnow});

Future<CareNotes?> showCareNotesSheet({
  required BuildContext context,
  required String? settling,
  required String? goodToKnow,
}) => showNestSheet<CareNotes>(
  context: context,
  title: NannyCopy.editSettling,
  builder: (_) =>
      _CareNotesSheetBody(settling: settling, goodToKnow: goodToKnow),
);

class _CareNotesSheetBody extends StatefulWidget {
  const _CareNotesSheetBody({required this.settling, required this.goodToKnow});

  final String? settling;
  final String? goodToKnow;

  @override
  State<_CareNotesSheetBody> createState() => _CareNotesSheetBodyState();
}

class _CareNotesSheetBodyState extends State<_CareNotesSheetBody> {
  late final _settling = TextEditingController(text: widget.settling ?? '');
  late final _goodToKnow = TextEditingController(text: widget.goodToKnow ?? '');

  @override
  void dispose() {
    _settling.dispose();
    _goodToKnow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final limit = [LengthLimitingTextInputFormatter(NannyLimits.careNote)];
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NestTextField(
            label: NannyCopy.settling,
            hint: NannyCopy.settlingHint,
            controller: _settling,
            maxLines: 4,
            inputFormatters: limit,
          ),
          const SizedBox(height: NestSpace.lg),
          NestTextField(
            label: NannyCopy.goodToKnow,
            hint: NannyCopy.goodToKnowHint,
            controller: _goodToKnow,
            maxLines: 4,
            inputFormatters: limit,
          ),
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: NannyCopy.save,
            onPressed: () => Navigator.of(context)
                .pop((settling: _settling.text, goodToKnow: _goodToKnow.text)),
          ),
        ],
      ),
    );
  }
}

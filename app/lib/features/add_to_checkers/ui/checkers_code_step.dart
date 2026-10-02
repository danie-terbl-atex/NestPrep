import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/checkers_copy.dart';
import '../state/checkers_link_controller.dart';

/// The code from Checkers' SMS. Four to six digits, as the server accepts.
class CheckersCodeStep extends StatefulWidget {
  const CheckersCodeStep({required this.onLinked, super.key});

  final VoidCallback onLinked;

  @override
  State<CheckersCodeStep> createState() => _CheckersCodeStepState();
}

class _CheckersCodeStepState extends State<CheckersCodeStep> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CheckersLinkController>();
    final nest = NestTheme.of(context);
    final fieldFailure = controller.fieldFailure;
    final sentTo = controller.codeSentTo;
    final canVerify = _code.text.length >= 4 && !controller.isBusy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sentTo != null) ...[
          Text(CheckersCopy.codeSentTo(sentTo), style: nest.text.body),
          const SizedBox(height: NestSpace.md),
        ],
        NestTextField(
          label: CheckersCopy.codeLabel,
          controller: _code,
          autofocus: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          errorText: fieldFailure == null
              ? null
              : AppCopy.failure(fieldFailure),
          onChanged: (_) {
            controller.clearFieldFailure();
            setState(() {});
          },
          onSubmitted: (_) => canVerify ? _verify(controller) : null,
        ),
        const SizedBox(height: NestSpace.lg),
        NestButton(
          label: CheckersCopy.verify,
          isLoading: controller.isBusy,
          onPressed: canVerify ? () => _verify(controller) : null,
        ),
        const SizedBox(height: NestSpace.sm),
        NestButton(
          label: CheckersCopy.changeNumber,
          variant: NestButtonVariant.ghost,
          onPressed: controller.isBusy ? null : controller.changeNumber,
        ),
      ],
    );
  }

  Future<void> _verify(CheckersLinkController controller) async {
    if (await controller.verify(_code.text)) widget.onLinked();
  }
}

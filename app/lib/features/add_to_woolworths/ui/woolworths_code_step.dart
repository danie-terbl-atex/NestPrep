import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/woolworths_copy.dart';
import '../state/woolworths_link_controller.dart';

/// The code Woolworths sent by SMS or email.
class WoolworthsCodeStep extends StatefulWidget {
  const WoolworthsCodeStep({required this.onLinked, super.key});

  final VoidCallback onLinked;

  @override
  State<WoolworthsCodeStep> createState() => _WoolworthsCodeStepState();
}

class _WoolworthsCodeStepState extends State<WoolworthsCodeStep> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WoolworthsLinkController>();
    final nest = NestTheme.of(context);
    final fieldFailure = controller.fieldFailure;
    final sentTo = controller.codeSentTo;
    final canVerify = _code.text.length >= 4 && !controller.isBusy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          sentTo == null
              ? WoolworthsCopy.codeSent
              : WoolworthsCopy.codeSentTo(sentTo),
          style: nest.text.body,
        ),
        const SizedBox(height: NestSpace.md),
        NestTextField(
          key: const ValueKey('woolworths-code'),
          label: WoolworthsCopy.codeLabel,
          controller: _code,
          autofocus: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
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
          key: const ValueKey('woolworths-verify'),
          label: WoolworthsCopy.verify,
          isLoading: controller.isBusy,
          onPressed: canVerify ? () => _verify(controller) : null,
        ),
        const SizedBox(height: NestSpace.sm),
        NestButton(
          label: WoolworthsCopy.startOver,
          variant: NestButtonVariant.ghost,
          onPressed: controller.isBusy ? null : controller.startOver,
        ),
      ],
    );
  }

  Future<void> _verify(WoolworthsLinkController controller) async {
    if (await controller.verify(_code.text)) widget.onLinked();
  }
}

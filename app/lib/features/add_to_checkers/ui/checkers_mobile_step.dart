import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/checkers_copy.dart';
import '../state/checkers_link_controller.dart';

/// The mobile number Checkers texts a code to. The server normalises it and
/// decides whether it is a South African number; the field only keeps out
/// what could never be one.
class CheckersMobileStep extends StatefulWidget {
  const CheckersMobileStep({super.key});

  @override
  State<CheckersMobileStep> createState() => _CheckersMobileStepState();
}

class _CheckersMobileStepState extends State<CheckersMobileStep> {
  final _mobile = TextEditingController();

  @override
  void dispose() {
    _mobile.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CheckersLinkController>();
    final fieldFailure = controller.fieldFailure;
    final canSend = _mobile.text.trim().length >= 9 && !controller.isBusy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestTextField(
          label: CheckersCopy.mobileLabel,
          hint: CheckersCopy.mobileHint,
          controller: _mobile,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.send,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
          ],
          errorText: fieldFailure == null
              ? null
              : AppCopy.failure(fieldFailure),
          onChanged: (_) {
            controller.clearFieldFailure();
            setState(() {});
          },
          onSubmitted: (_) => canSend ? _send(controller) : null,
        ),
        const SizedBox(height: NestSpace.lg),
        NestButton(
          label: CheckersCopy.sendCode,
          isLoading: controller.isBusy,
          onPressed: canSend ? () => _send(controller) : null,
        ),
      ],
    );
  }

  // Only ever from a tap: a code is a text message to somebody's phone.
  void _send(CheckersLinkController controller) =>
      controller.requestOtp(_mobile.text);
}

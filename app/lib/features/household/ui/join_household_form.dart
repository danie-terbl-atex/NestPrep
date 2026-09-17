import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../state/household_gate_controller.dart';

/// Types the code somebody shared. Codes are shown in upper case and contain no
/// character a person confuses for another (household ADR-0002), so the field
/// upper-cases as you type rather than refusing what you meant.
class JoinHouseholdForm extends StatefulWidget {
  const JoinHouseholdForm({super.key});

  static const codeLength = 8;

  @override
  State<JoinHouseholdForm> createState() => _JoinHouseholdFormState();
}

class _JoinHouseholdFormState extends State<JoinHouseholdForm> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HouseholdGateController>();
    final canSubmit = _code.text.trim().length == JoinHouseholdForm.codeLength;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestTextField(
          label: AppCopy.inviteCodeLabel,
          hint: AppCopy.inviteCodeHint,
          controller: _code,
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.visiblePassword,
          inputFormatters: const [_UpperCaseFormatter()],
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => canSubmit ? _submit(controller) : null,
        ),
        const SizedBox(height: NestSpace.xl),
        NestButton(
          label: AppCopy.householdJoinAction,
          isLoading: controller.isBusy,
          onPressed: canSubmit ? () => _submit(controller) : null,
        ),
      ],
    );
  }

  void _submit(HouseholdGateController controller) {
    unawaited(controller.joinWithCode(_code.text.trim()));
  }
}

/// Upper-cases as the person types. Showing them what was stored is the point —
/// nothing is silently changed behind the cursor (`FE-10`).
class _UpperCaseFormatter extends TextInputFormatter {
  const _UpperCaseFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => TextEditingValue(
    text: newValue.text.toUpperCase(),
    selection: newValue.selection,
  );
}

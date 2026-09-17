import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../state/household_gate_controller.dart';

/// Names the household and the person creating it. Both are required, the
/// submit is disabled while either is empty and while a call is in flight, so
/// it cannot be sent twice (`FE-10`).
class CreateHouseholdForm extends StatefulWidget {
  const CreateHouseholdForm({super.key});

  @override
  State<CreateHouseholdForm> createState() => _CreateHouseholdFormState();
}

class _CreateHouseholdFormState extends State<CreateHouseholdForm> {
  late final TextEditingController _householdName;
  late final TextEditingController _myName;

  @override
  void initState() {
    super.initState();
    final suggested = context.read<HouseholdGateController>().suggestedName;
    _householdName = TextEditingController();
    _myName = TextEditingController(text: suggested);
  }

  @override
  void dispose() {
    _householdName.dispose();
    _myName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HouseholdGateController>();
    final canSubmit =
        _householdName.text.trim().isNotEmpty && _myName.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestTextField(
          label: AppCopy.householdNameLabel,
          hint: AppCopy.householdNameHint,
          controller: _householdName,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: NestSpace.lg),
        NestTextField(
          label: AppCopy.myNameLabel,
          controller: _myName,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => canSubmit ? _submit(controller) : null,
        ),
        const SizedBox(height: NestSpace.xl),
        NestButton(
          label: AppCopy.householdCreateAction,
          isLoading: controller.isBusy,
          onPressed: canSubmit ? () => _submit(controller) : null,
        ),
      ],
    );
  }

  void _submit(HouseholdGateController controller) {
    unawaited(
      controller.createHousehold(
        householdName: _householdName.text.trim(),
        myName: _myName.text.trim(),
      ),
    );
  }
}

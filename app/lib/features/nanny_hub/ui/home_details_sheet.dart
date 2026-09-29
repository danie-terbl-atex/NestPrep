import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/home_sheet.dart';
import '../model/nanny_limits.dart';

/// Edits the address and the medical aid. Null when closed without saving.
Future<HomeSheet?> showHomeDetailsSheet({
  required BuildContext context,
  required HomeSheet sheet,
}) => showNestSheet<HomeSheet>(
  context: context,
  title: NannyCopy.editHomeDetails,
  builder: (_) => _HomeDetailsBody(sheet: sheet),
);

class _HomeDetailsBody extends StatefulWidget {
  const _HomeDetailsBody({required this.sheet});

  final HomeSheet sheet;

  @override
  State<_HomeDetailsBody> createState() => _HomeDetailsBodyState();
}

class _HomeDetailsBodyState extends State<_HomeDetailsBody> {
  late final _address = TextEditingController(text: widget.sheet.address);
  late final _scheme = TextEditingController(
    text: widget.sheet.medicalAidScheme,
  );
  late final _plan = TextEditingController(text: widget.sheet.medicalAidPlan);
  late final _number = TextEditingController(
    text: widget.sheet.medicalAidNumber,
  );

  @override
  void dispose() {
    for (final controller in [_address, _scheme, _plan, _number]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NestTextField(
            label: NannyCopy.ourAddress,
            hint: NannyCopy.addressHint,
            controller: _address,
            maxLines: 3,
            inputFormatters: [
              LengthLimitingTextInputFormatter(NannyLimits.address),
            ],
          ),
          const SizedBox(height: NestSpace.lg),
          NestTextField(
            label: NannyCopy.medicalAidScheme,
            controller: _scheme,
            inputFormatters: [
              LengthLimitingTextInputFormatter(NannyLimits.medicalAidScheme),
            ],
          ),
          const SizedBox(height: NestSpace.sm),
          NestTextField(
            label: NannyCopy.medicalAidPlan,
            controller: _plan,
            inputFormatters: [
              LengthLimitingTextInputFormatter(NannyLimits.medicalAidPlan),
            ],
          ),
          const SizedBox(height: NestSpace.sm),
          NestTextField(
            label: NannyCopy.medicalAidNumber,
            controller: _number,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              LengthLimitingTextInputFormatter(NannyLimits.medicalAidNumber),
            ],
          ),
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: NannyCopy.save,
            onPressed: () => Navigator.of(context).pop(
              HomeSheet(
                address: _address.text,
                medicalAidScheme: _scheme.text,
                medicalAidPlan: _plan.text,
                medicalAidNumber: _number.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

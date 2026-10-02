import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/emergency_number.dart';

/// South Africa's public emergency numbers as three big buttons, each one tap
/// to the dialler with the number already in it (nanny-hub ADR-0003). The
/// number is written on the button too, so it can be dialled by hand from
/// another phone.
class EmergencyCallButtons extends StatelessWidget {
  const EmergencyCallButtons({required this.onCall, super.key});

  final ValueChanged<Uri> onCall;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final number in EmergencyNumber.values)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: NestButton(
              label: NannyCopy.callNumber(
                NannyCopy.emergencyNumberName(number),
                number.digits,
              ),
              icon: LucideIcons.phoneCall,
              variant: number == EmergencyNumber.ambulance
                  ? NestButtonVariant.danger
                  : NestButtonVariant.tonal,
              onPressed: () => onCall(number.dialLink),
            ),
          ),
      ],
    );
  }
}

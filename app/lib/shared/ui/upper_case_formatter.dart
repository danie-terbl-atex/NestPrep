import 'package:flutter/services.dart';

/// Upper-cases as the person types a code — an invite or a referral code,
/// which are shown in upper case (household ADR-0002, subscriptions
/// ADR-0002). Showing them what was stored is the point: nothing is silently
/// changed behind the cursor (`FE-10`).
class UpperCaseFormatter extends TextInputFormatter {
  const UpperCaseFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => TextEditingValue(
    text: newValue.text.toUpperCase(),
    selection: newValue.selection,
  );
}

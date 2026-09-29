import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/vault_copy.dart';
import '../../../shared/time/calendar_date.dart';
import '../../../shared/ui/nest_date_field.dart';

/// A document's expiry date, which most documents do not have: a button to
/// add one, and once there, the date with a way to take it away again — and
/// a line saying when the reminders will come (documents ADR-0005).
class ExpiryField extends StatelessWidget {
  const ExpiryField({
    required this.value,
    required this.today,
    required this.onChanged,
    super.key,
  });

  final CalendarDate? value;
  final CalendarDate today;
  final ValueChanged<CalendarDate?> onChanged;

  /// A passport runs ten years; a little more leaves room for a renewal.
  static const yearsAhead = 12;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final date = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (date == null) ...[
          Text(
            VaultCopy.expiryLabel,
            style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: VaultCopy.addExpiry,
            icon: Icons.event_outlined,
            variant: NestButtonVariant.outline,
            size: NestButtonSize.medium,
            onPressed: () => _add(context),
          ),
        ] else ...[
          NestDateField(
            label: VaultCopy.expiryLabel,
            value: date,
            today: today,
            yearsAhead: yearsAhead,
            onChanged: onChanged,
          ),
          const SizedBox(height: NestSpace.xs),
          Text(
            VaultCopy.remindersNote,
            style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
          ),
          NestButton(
            label: VaultCopy.removeExpiry,
            variant: NestButtonVariant.ghost,
            size: NestButtonSize.small,
            isExpanded: false,
            onPressed: () => onChanged(null),
          ),
        ],
      ],
    );
  }

  Future<void> _add(BuildContext context) async {
    final picked = await NestDateField.pickDate(
      context,
      initial: today.addMonthsKeepingDay(12) ?? today.addDays(365),
      today: today,
      yearsAhead: yearsAhead,
    );
    if (picked != null) onChanged(picked);
  }
}

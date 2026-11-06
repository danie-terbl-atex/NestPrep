import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/calendar_sync_copy.dart';
import '../model/apple_calendar.dart';

/// Which of this iPhone's calendars join the family week. Returns the chosen
/// ids, or null when the sheet was closed. Starts from [chosen] when the phone
/// already linked some, otherwise from every calendar that is not birthdays or
/// a subscription.
Future<List<String>?> showAppleCalendarPicker(
  BuildContext context, {
  required List<AppleCalendar> calendars,
  required List<String> chosen,
}) => showNestSheet<List<String>>(
  context: context,
  title: CalendarSyncCopy.applePickerTitle,
  builder: (sheetContext) =>
      _AppleCalendarPicker(calendars: calendars, chosen: chosen),
);

class _AppleCalendarPicker extends StatefulWidget {
  const _AppleCalendarPicker({required this.calendars, required this.chosen});

  final List<AppleCalendar> calendars;
  final List<String> chosen;

  @override
  State<_AppleCalendarPicker> createState() => _AppleCalendarPickerState();
}

class _AppleCalendarPickerState extends State<_AppleCalendarPicker> {
  late final Set<String> _chosen = widget.chosen.isNotEmpty
      ? {...widget.chosen}
      : {
          for (final calendar in widget.calendars)
            if (calendar.suggested) calendar.id,
        };

  List<AppleCalendar> get _sorted => [...widget.calendars]
    ..sort((a, b) {
      final byAccount = a.account.compareTo(b.account);
      return byAccount != 0 ? byAccount : a.title.compareTo(b.title);
    });

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final chosen = [
      for (final calendar in widget.calendars)
        if (_chosen.contains(calendar.id)) calendar.id,
    ];
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.calendars.isEmpty
                ? CalendarSyncCopy.applePickerEmpty
                : CalendarSyncCopy.applePickerBody,
            style: nest.text.body.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.lg),
          for (final calendar in _sorted) ...[
            NestCheckRow(
              key: ValueKey(calendar.id),
              label: CalendarSyncCopy.appleCalendarLabel(
                calendar.title,
                calendar.account,
              ),
              value: _chosen.contains(calendar.id),
              onChanged: (value) => setState(
                () => value
                    ? _chosen.add(calendar.id)
                    : _chosen.remove(calendar.id),
              ),
            ),
            const SizedBox(height: NestSpace.sm),
          ],
          const SizedBox(height: NestSpace.sm),
          Text(
            CalendarSyncCopy.privacyNote,
            style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
          ),
          const SizedBox(height: NestSpace.xl),
          NestButton(
            label: CalendarSyncCopy.applePickerSave,
            onPressed: chosen.isEmpty
                ? null
                : () => Navigator.of(context).pop(chosen),
          ),
        ],
      ),
    );
  }
}

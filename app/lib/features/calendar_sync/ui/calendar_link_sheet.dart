import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/calendar_sync_copy.dart';

/// Asks for a calendar link — Apple's way in, and a school's or a club's
/// (calendar ADR-0003). Returns what was pasted, trimmed, or null. Whether it
/// is a calendar is the Function's to say; this only refuses nothing at all.
Future<String?> showCalendarLinkSheet(BuildContext context) =>
    showNestSheet<String>(
      context: context,
      title: CalendarSyncCopy.linkSheetTitle,
      builder: (sheetContext) => const _CalendarLinkForm(),
    );

class _CalendarLinkForm extends StatefulWidget {
  const _CalendarLinkForm();

  @override
  State<_CalendarLinkForm> createState() => _CalendarLinkFormState();
}

class _CalendarLinkFormState extends State<_CalendarLinkForm> {
  final _link = TextEditingController();

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  void _submit() {
    final link = _link.text.trim();
    if (link.isEmpty) return;
    Navigator.of(context).pop(link);
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            CalendarSyncCopy.linkHelp,
            style: nest.text.body.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.lg),
          NestTextField(
            label: CalendarSyncCopy.linkLabel,
            hint: CalendarSyncCopy.linkHint,
            controller: _link,
            autofocus: true,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.none,
            prefixIcon: LucideIcons.link,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: NestSpace.md),
          Text(
            CalendarSyncCopy.privacyNote,
            style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
          ),
          const SizedBox(height: NestSpace.xl),
          NestButton(
            label: CalendarSyncCopy.linkAdd,
            onPressed: _link.text.trim().isEmpty ? null : _submit,
          ),
        ],
      ),
    );
  }
}

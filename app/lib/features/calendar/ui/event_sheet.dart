import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/recurrence/recurrence_rule.dart';
import '../../../shared/time/calendar_date.dart';
import '../../../shared/ui/nest_date_field.dart';
import '../../../shared/ui/pick_minute_of_day.dart';
import '../../../shared/ui/recurrence_editor.dart';
import '../../household/model/member.dart';
import '../../household/ui/member_picker.dart';
import '../model/household_event.dart';

/// What the event sheet came back with.
sealed class EventDraft {
  const EventDraft();
}

final class EventSaved extends EventDraft {
  const EventSaved({
    required this.title,
    this.note,
    required this.date,
    this.startMinute,
    this.endMinute,
    this.recurrence,
    required this.memberIds,
  });

  final String title;
  final String? note;
  final CalendarDate date;
  final int? startMinute;
  final int? endMinute;
  final RecurrenceRule? recurrence;
  final List<String> memberIds;
}

final class EventDeleted extends EventDraft {
  const EventDeleted();
}

/// Hide this one occurrence and leave the rest. The only per-occurrence change
/// v1 offers (calendar ADR-0001).
final class EventSkipped extends EventDraft {
  const EventSkipped();
}

Future<EventDraft?> showEventSheet({
  required BuildContext context,
  required List<Member> members,
  required CalendarDate today,
  required CalendarDate initialDate,
  HouseholdEvent? existing,
  EventSaved? draft,
  bool canSkip = false,
}) => showNestSheet<EventDraft>(
  context: context,
  title: existing == null
      ? AppCopy.calendarAddEvent
      : AppCopy.calendarEditEvent,
  builder: (sheetContext) => _EventSheetBody(
    members: members,
    today: today,
    initialDate: initialDate,
    existing: existing,
    draft: draft,
    canSkip: canSkip,
  ),
);

class _EventSheetBody extends StatefulWidget {
  const _EventSheetBody({
    required this.members,
    required this.today,
    required this.initialDate,
    required this.existing,
    required this.draft,
    required this.canSkip,
  });

  final List<Member> members;
  final CalendarDate today;
  final CalendarDate initialDate;
  final HouseholdEvent? existing;

  /// A new event already filled in — what quick add understood, opened for
  /// the member to change before it is saved (calendar ADR-0004).
  final EventSaved? draft;
  final bool canSkip;

  @override
  State<_EventSheetBody> createState() => _EventSheetBodyState();
}

class _EventSheetBodyState extends State<_EventSheetBody> {
  /// What a new timed event starts as: the next round hour, for an hour.
  static const _defaultStartMinute = 9 * 60;
  static const _defaultDurationMinutes = 60;

  late final _title = TextEditingController(
    text: widget.existing?.title ?? widget.draft?.title ?? '',
  );
  late CalendarDate _date =
      widget.existing?.date ?? widget.draft?.date ?? widget.initialDate;
  late bool _isAllDay =
      widget.existing?.isAllDay ??
      (widget.draft == null ? false : widget.draft!.startMinute == null);
  late int _startMinute =
      widget.existing?.startMinute ??
      widget.draft?.startMinute ??
      _defaultStartMinute;
  late int _endMinute =
      widget.existing?.endMinute ??
      widget.draft?.endMinute ??
      (_startMinute + _defaultDurationMinutes) % HouseholdEvent.minutesInADay;
  late RecurrenceRule? _recurrence =
      widget.existing?.recurrence ?? widget.draft?.recurrence;
  late List<String> _memberIds = [
    ...?widget.existing?.memberIds ?? widget.draft?.memberIds,
  ];

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final canSave = _title.text.trim().isNotEmpty;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NestTextField(
            label: AppCopy.calendarTitleLabel,
            controller: _title,
            autofocus: widget.existing == null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: NestSpace.xl),
          NestDateField(
            label: AppCopy.calendarStarts,
            value: _date,
            today: widget.today,
            onChanged: (date) => setState(() => _date = date),
          ),
          const SizedBox(height: NestSpace.lg),
          NestListRow(
            title: AppCopy.calendarAllDay,
            leading: const NestIconTile(
              icon: LucideIcons.sun,
              tint: NestTileTint.butter,
              size: NestSize.avatarMedium,
            ),
            trailing: Switch(
              value: _isAllDay,
              onChanged: (value) => setState(() => _isAllDay = value),
            ),
            onTap: () => setState(() => _isAllDay = !_isAllDay),
          ),
          if (!_isAllDay) ...[
            const SizedBox(height: NestSpace.lg),
            Row(
              children: [
                Expanded(
                  child: _TimeField(
                    label: AppCopy.calendarStarts,
                    minutes: _startMinute,
                    onChanged: _setStart,
                  ),
                ),
                const SizedBox(width: NestSpace.md),
                Expanded(
                  child: _TimeField(
                    label: AppCopy.calendarEnds,
                    minutes: _endMinute,
                    onChanged: (minutes) =>
                        setState(() => _endMinute = minutes),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: NestSpace.xl),
          RecurrenceEditor(
            rule: _recurrence,
            firstDate: _date,
            onChanged: (rule) => setState(() => _recurrence = rule),
          ),
          const SizedBox(height: NestSpace.xl),
          Text(
            AppCopy.calendarForLabel,
            style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.sm),
          MemberPicker(
            members: widget.members,
            selectedIds: _memberIds,
            onChanged: (ids) => setState(() => _memberIds = ids),
            anyoneLabel: AppCopy.calendarEveryone,
          ),
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: AppCopy.householdSave,
            onPressed: canSave ? _save : null,
          ),
          if (widget.canSkip) ...[
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: AppCopy.calendarSkip,
              variant: NestButtonVariant.outline,
              onPressed: () => Navigator.of(context).pop(const EventSkipped()),
            ),
          ],
          if (widget.existing != null) ...[
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: AppCopy.householdRemove,
              variant: NestButtonVariant.danger,
              onPressed: () => Navigator.of(context).pop(const EventDeleted()),
            ),
          ],
        ],
      ),
    );
  }

  /// Moving the start keeps how long the event lasts, which is what somebody
  /// changing 09:00 to 10:00 means.
  void _setStart(int minutes) {
    setState(() {
      final duration = _endMinute - _startMinute;
      _startMinute = minutes;
      _endMinute = duration > 0
          ? (minutes + duration) % HouseholdEvent.minutesInADay
          : minutes + _defaultDurationMinutes;
    });
  }

  void _save() {
    Navigator.of(context).pop(
      EventSaved(
        title: _title.text,
        date: _date,
        startMinute: _isAllDay ? null : _startMinute,
        endMinute: _isAllDay ? null : _endMinute,
        recurrence: _recurrence,
        memberIds: _memberIds,
      ),
    );
  }
}

/// A wall-clock time in the household's zone, picked with the platform's own
/// picker (calendar ADR-0002).
class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.minutes,
    required this.onChanged,
  });

  final String label;
  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
        ),
        const SizedBox(height: NestSpace.sm),
        NestListRow(
          title: NestDates.timeOfDay(minutes),
          onTap: () => _pick(context),
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await pickMinuteOfDay(context, initialMinutes: minutes);
    if (picked == null) return;
    onChanged(picked);
  }
}

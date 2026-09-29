import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../../../shared/time/household_clock.dart';
import '../../../shared/ui/nest_date_field.dart';
import '../../../shared/ui/pick_minute_of_day.dart';
import '../../household/model/member.dart';
import '../model/nanny_limits.dart';

/// A shift as the sheet booked it: whose, from when to when (UTC instants the
/// household's wall clock chose), and a note.
typedef BookingChoice = ({
  String carerMemberId,
  DateTime startsAt,
  DateTime endsAt,
  String? note,
});

/// Books a carer's shift ahead: who, which day, from and to on the
/// household's clock. An end before the start is the next morning — an
/// overnight shift — and the sheet says so rather than refusing it.
Future<BookingChoice?> showBookingSheet({
  required BuildContext context,
  required List<Member> carers,
  required HouseholdClock clock,
}) => showNestSheet<BookingChoice>(
  context: context,
  title: NannyBookingCopy.bookTitle,
  builder: (_) => _BookingBody(carers: carers, clock: clock),
);

class _BookingBody extends StatefulWidget {
  const _BookingBody({required this.carers, required this.clock});

  final List<Member> carers;
  final HouseholdClock clock;

  @override
  State<_BookingBody> createState() => _BookingBodyState();
}

class _BookingBodyState extends State<_BookingBody> {
  static const _defaultStart = 17 * 60 + 30;
  static const _defaultEnd = 22 * 60;

  final _note = TextEditingController();
  late String? _carerId = widget.carers.length == 1
      ? widget.carers.single.id
      : null;
  late CalendarDate _day = widget.clock.today;
  int _start = _defaultStart;
  int _end = _defaultEnd;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _isOvernight => _end <= _start;

  DateTime get _startsAt =>
      widget.clock.instantAt(_day, hour: _start ~/ 60, minute: _start % 60);

  DateTime get _endsAt => widget.clock.instantAt(
    _isOvernight ? _day.addDays(1) : _day,
    hour: _end ~/ 60,
    minute: _end % 60,
  );

  /// Why the shift cannot be booked as it stands, or null.
  String? get _problem {
    if (_endsAt.difference(_startsAt) > NannyLimits.bookingLength) {
      return NannyBookingCopy.tooLong;
    }
    if (!_endsAt.isAfter(widget.clock.now)) return NannyBookingCopy.inThePast;
    return null;
  }

  Future<void> _pick({required bool isStart}) async {
    final picked = await pickMinuteOfDay(
      context,
      initialMinutes: isStart ? _start : _end,
    );
    if (picked == null || !mounted) return;
    setState(() => isStart ? _start = picked : _end = picked);
  }

  void _book() {
    final carerId = _carerId;
    if (carerId == null || _problem != null) return;
    final note = _note.text.trim();
    Navigator.of(context).pop((
      carerMemberId: carerId,
      startsAt: _startsAt,
      endsAt: _endsAt,
      note: note.isEmpty ? null : note,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final label = nest.text.label.copyWith(color: nest.colors.inkSecondary);
    final problem = _problem;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(NannyBookingCopy.who, style: label),
          const SizedBox(height: NestSpace.sm),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              for (final carer in widget.carers)
                NestChip(
                  label: carer.displayName,
                  isSelected: carer.id == _carerId,
                  icon: carer.id == _carerId ? Icons.check : null,
                  onTap: () => setState(() => _carerId = carer.id),
                ),
            ],
          ),
          const SizedBox(height: NestSpace.lg),
          NestDateField(
            label: NannyBookingCopy.day,
            value: _day,
            today: widget.clock.today,
            onChanged: (day) => setState(() => _day = day),
          ),
          const SizedBox(height: NestSpace.lg),
          _TimeRow(
            title: NannyBookingCopy.startsAt(NestDates.timeOfDay(_start)),
            onTap: () => _pick(isStart: true),
          ),
          const SizedBox(height: NestSpace.sm),
          _TimeRow(
            title: NannyBookingCopy.endsAt(NestDates.timeOfDay(_end)),
            note: _isOvernight ? NannyBookingCopy.endsNextDay : null,
            onTap: () => _pick(isStart: false),
          ),
          const SizedBox(height: NestSpace.lg),
          NestTextField(
            label: NannyBookingCopy.note,
            hint: NannyBookingCopy.noteHint,
            controller: _note,
            maxLines: 2,
            inputFormatters: [
              LengthLimitingTextInputFormatter(NannyLimits.bookingNote),
            ],
          ),
          if (problem != null) ...[
            const SizedBox(height: NestSpace.lg),
            NestBanner(message: problem, tone: NestBannerTone.warning),
          ],
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: NannyBookingCopy.confirmBook,
            icon: Icons.event_available,
            onPressed: _carerId == null || problem != null ? null : _book,
          ),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.title, required this.onTap, this.note});

  final String title;
  final String? note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NestCard(
      variant: NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: NestListRow(
        leading: const NestIconTile(
          icon: Icons.schedule,
          tint: NestTileTint.peach,
          size: NestSize.avatarMedium,
          iconSize: NestSize.iconMedium,
        ),
        title: title,
        subtitle: note,
        trailing: const Icon(Icons.edit_outlined),
        onTap: onTap,
      ),
    );
  }
}

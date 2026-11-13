import '../../../shared/time/calendar_date.dart';
import '../../household/model/birthday.dart';
import 'avatar_catalogue.g.dart';

Map<AvatarSlot, String> avatarMomentsOn({
  required CalendarDate today,
  required AvatarHemisphere hemisphere,
  required Birthday? birthday,
  required Map<AvatarSlot, String> wear,
  List<AvatarMoment> moments = avatarMoments,
}) {
  final shown = <AvatarSlot, String>{};
  for (final moment in moments) {
    if (moment.rule is! BirthdayMomentRule) continue;
    if (shown.containsKey(moment.slot)) continue;
    if (birthday != null && birthday.occurrenceIn(today.year) == today) {
      shown[moment.slot] = moment.id;
    }
  }
  for (final moment in moments) {
    if (moment.rule is BirthdayMomentRule) continue;
    if (shown.containsKey(moment.slot) || wear.containsKey(moment.slot)) {
      continue;
    }
    if (isAvatarMomentOn(moment.rule, today: today, hemisphere: hemisphere)) {
      shown[moment.slot] = moment.id;
    }
  }
  return shown;
}

bool isAvatarMomentOn(
  MomentRule rule, {
  required CalendarDate today,
  required AvatarHemisphere hemisphere,
}) => switch (rule) {
  BirthdayMomentRule() => false,
  DatesMomentRule(:final from, :final to, hemisphere: final only) =>
    (only == null || only == hemisphere) && _isWithin(today, from, to),
  EasterMomentRule(:final from, :final to) => _isAround(
    westernEaster(today.year).daysUntil(today),
    from,
    to,
  ),
};

bool _isAround(int offset, int from, int to) => offset >= from && offset <= to;

bool _isWithin(CalendarDate today, String from, String to) {
  final day =
      '${today.month.toString().padLeft(2, '0')}-'
      '${today.day.toString().padLeft(2, '0')}';
  if (from.compareTo(to) <= 0) {
    return day.compareTo(from) >= 0 && day.compareTo(to) <= 0;
  }
  return day.compareTo(from) >= 0 || day.compareTo(to) <= 0;
}

CalendarDate westernEaster(int year) {
  final a = year % 19;
  final b = year ~/ 100;
  final c = year % 100;
  final d = b ~/ 4;
  final e = b % 4;
  final f = (b + 8) ~/ 25;
  final g = (b - f + 1) ~/ 3;
  final h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4;
  final k = c % 4;
  final l = (32 + 2 * e + 2 * i - h - k) % 7;
  final m = (a + 11 * h + 22 * l) ~/ 451;
  final month = (h + l - 7 * m + 114) ~/ 31;
  final day = ((h + l - 7 * m + 114) % 31) + 1;
  return CalendarDate(year, month, day);
}

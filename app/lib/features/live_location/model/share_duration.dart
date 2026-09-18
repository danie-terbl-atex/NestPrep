/// How long a member may choose to share for (live-location ADR-0002).
///
/// Three, not a picker: the school run, the trip, the day out. Every one of
/// them ends by itself, so there is no share anybody has to remember to switch
/// off. The longest is bounded by the rules as well, because a bound the client
/// alone keeps is not a bound (`BE-20`).
enum ShareDuration {
  fifteenMinutes(Duration(minutes: 15)),
  oneHour(Duration(hours: 1)),
  fourHours(Duration(hours: 4));

  const ShareDuration(this.length);

  final Duration length;

  DateTime endingFrom(DateTime now) => now.add(length);
}

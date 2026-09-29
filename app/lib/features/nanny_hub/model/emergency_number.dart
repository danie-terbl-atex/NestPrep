/// South Africa's public emergency numbers, at the top of every emergency
/// sheet whether or not the household filled anything in (nanny-hub
/// ADR-0003). They are data, not copy: what each is called is in `NannyCopy`.
///
/// A household outside South Africa is not in v1; when one is, this becomes a
/// table keyed by country and the sheet reads the household's.
enum EmergencyNumber {
  /// SAPS, the police flying squad.
  police('10111'),

  /// The public ambulance and fire service.
  ambulance('10177'),

  /// From any mobile phone, on any network, even without airtime.
  mobile('112');

  const EmergencyNumber(this.digits);

  final String digits;

  Uri get dialLink => Uri(scheme: 'tel', path: digits);
}

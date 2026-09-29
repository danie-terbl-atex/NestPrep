/// One of the two homes a linked child lives between (household ADR-0004).
///
/// `a` is the home that made the code and `b` the home that accepted it. The
/// other household's id is never known to this app — a side is all a mirror
/// says about who is who.
enum CustodySide {
  a,
  b;

  CustodySide get other => this == a ? b : a;

  /// A stored side, or null for anything this build does not know
  /// (`BE-10`): a day with an unreadable side has no band, rather than the
  /// wrong one.
  static CustodySide? fromName(Object? name) => switch (name) {
    'a' => CustodySide.a,
    'b' => CustodySide.b,
    _ => null,
  };
}

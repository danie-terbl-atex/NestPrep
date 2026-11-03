/// What a member let an assistant do, chosen on the consent page (assistants
/// ADR-0003). Mirrors the Functions' `ASSISTANT_SCOPES`, in the same order.
enum AssistantScope {
  householdRead('household:read'),
  calendarRead('calendar:read'),
  calendarWrite('calendar:write'),
  listsRead('lists:read'),
  listsWrite('lists:write');

  const AssistantScope(this.wire);

  /// The scope as the grant stores it.
  final String wire;

  /// The scopes among [stored] that this build knows, in this enum's order;
  /// one it has never heard of is left out rather than guessed at.
  static List<AssistantScope> parse(Iterable<String> stored) {
    final wanted = stored.toSet();
    return [
      for (final scope in values)
        if (wanted.contains(scope.wire)) scope,
    ];
  }
}

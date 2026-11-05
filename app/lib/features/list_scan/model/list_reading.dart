import '../../../shared/failure/app_failure.dart';
import 'list_scan_line.dart';

/// What reading one photo gave back: the lines it proposed, and how many AI
/// calls the household has left this month (foundation ADR-0015).
final class ListReading {
  const ListReading({required this.lines, required this.callsLeft});

  final List<ListScanLine> lines;
  final int callsLeft;

  /// The callable's reply, parsed — never cast (`ENG-09`). A reply that is
  /// not the contract's shape is an unreadable answer; a single line that
  /// does not parse is left out.
  factory ListReading.fromWire(Object? data) {
    if (data is! Map) throw const AiFailure(AiProblem.aiUnreadable);
    final lines = data['lines'];
    final callsLeft = data['callsLeft'];
    if (lines is! List || callsLeft is! int) {
      throw const AiFailure(AiProblem.aiUnreadable);
    }
    return ListReading(
      lines: [
        for (final (index, line) in lines.indexed)
          if (line case {'name': final String name} when name.trim().isNotEmpty)
            ListScanLine(
              key: index,
              name: name,
              quantity: switch (line['quantity']) {
                final String quantity when quantity.trim().isNotEmpty =>
                  quantity,
                _ => null,
              },
            ),
      ],
      callsLeft: callsLeft,
    );
  }
}

import 'package:flutter/widgets.dart';

import '../../../design/nest_kit.dart';

/// One beta number: what it is, the number, and what it was counted against
/// (product-analytics ADR-0001). A number alone is how "12" gets read as good
/// or bad without anybody asking "out of how many".
///
/// One node to a screen reader, read in the order a person reads it.
class BetaNumberTile extends StatelessWidget {
  const BetaNumberTile({
    required this.label,
    required this.value,
    this.detail,
    this.isProminent = false,
    super.key,
  });

  final String label;
  final String value;
  final String? detail;

  /// The north star is set larger than the two beside it.
  final bool isProminent;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final detailText = detail;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.xs),
          Text(
            value,
            style: isProminent ? nest.text.figure : nest.text.figureSmall,
          ),
          if (detailText != null) ...[
            const SizedBox(height: NestSpace.xxs),
            Text(detailText, style: nest.text.bodySecondary),
          ],
        ],
      ),
    );
  }
}

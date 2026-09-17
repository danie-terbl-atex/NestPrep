import 'package:flutter/material.dart';

import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';

/// The bottom sheet: rounded top, grab handle, optional title, content
/// padded to the gutter. Returns whatever the sheet pops with.
Future<T?> showNestSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    builder: (context) => NestSheetBody(title: title, child: builder(context)),
  );
}

class NestSheetBody extends StatelessWidget {
  const NestSheetBody({required this.child, this.title, super.key});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final titleText = title;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: NestSpace.md),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: nest.colors.outlineStrong,
                  borderRadius: BorderRadius.circular(NestRadius.pill),
                ),
                child: const SizedBox(
                  width: NestSize.sheetHandleWidth,
                  height: NestSize.sheetHandleHeight,
                ),
              ),
            ),
          ),
          if (titleText != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                NestSpace.gutter,
                NestSpace.xl,
                NestSpace.gutter,
                0,
              ),
              child: Text(titleText, style: nest.text.title),
            ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                NestSpace.gutter,
                NestSpace.lg,
                NestSpace.gutter,
                NestSpace.xxl,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

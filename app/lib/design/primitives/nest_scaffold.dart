import 'package:flutter/material.dart';

import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';

/// Every screen's frame: the canvas with its soft wash, safe areas, an
/// optional header row (leading, title, trailing), the body, and slots for a
/// floating bottom bar and a floating action. Screens never paint a
/// background themselves (`FE-01`).
class NestScaffold extends StatelessWidget {
  const NestScaffold({
    required this.body,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing = const [],
    this.bottomBar,
    this.floatingAction,
    this.bodyPadding = const EdgeInsets.symmetric(horizontal: NestSpace.gutter),
    super.key,
  });

  final Widget body;
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> trailing;
  final Widget? bottomBar;
  final Widget? floatingAction;
  final EdgeInsetsGeometry bodyPadding;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final hasHeader = title != null || leading != null || trailing.isNotEmpty;
    return Scaffold(
      backgroundColor: nest.colors.canvas,
      extendBody: true,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: nest.colors.canvasWash,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (hasHeader)
                _NestHeader(
                  title: title,
                  subtitle: subtitle,
                  leading: leading,
                  trailing: trailing,
                ),
              Expanded(
                child: Padding(
                  // A floating action floats *over* the body, so the body
                  // reserves room for it — otherwise an empty state's message
                  // ends up underneath it (`FE-14`).
                  padding: bodyPadding.add(
                    EdgeInsets.only(
                      bottom: floatingAction == null
                          ? 0
                          : NestSize.controlLarge + NestSpace.lg,
                    ),
                  ),
                  child: body,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: floatingAction,
      bottomNavigationBar: bottomBar,
    );
  }
}

class _NestHeader extends StatelessWidget {
  const _NestHeader({
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.trailing,
  });

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final titleText = title;
    final subtitleText = subtitle;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NestSpace.gutter,
        NestSpace.md,
        NestSpace.gutter,
        NestSpace.lg,
      ),
      child: Row(
        children: [
          ?leading,
          if (leading != null) const SizedBox(width: NestSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: leading == null && trailing.isEmpty
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (titleText != null)
                  Text(
                    titleText,
                    style: nest.text.title,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (subtitleText != null)
                  Text(subtitleText, style: nest.text.caption),
              ],
            ),
          ),
          for (final action in trailing) ...[
            const SizedBox(width: NestSpace.sm),
            action,
          ],
        ],
      ),
    );
  }
}

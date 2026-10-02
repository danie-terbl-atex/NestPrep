import 'package:flutter/material.dart';

import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';
import 'nest_eyebrow.dart';

/// Every screen's frame: the Oat page, safe areas, an optional header row
/// (leading, eyebrow and title, trailing), the body, and slots for a floating
/// bottom bar and a floating action. Screens never paint a background
/// themselves (`FE-01`).
class NestScaffold extends StatelessWidget {
  const NestScaffold({
    required this.body,
    this.title,
    this.eyebrow,
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
  final String? eyebrow;
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
      body: ColoredBox(
        color: nest.colors.canvas,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (hasHeader)
                _NestHeader(
                  title: title,
                  eyebrow: eyebrow,
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
    required this.eyebrow,
    required this.subtitle,
    required this.leading,
    required this.trailing,
  });

  final String? title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final titleText = title;
    final subtitleText = subtitle;
    final eyebrowText = eyebrow;
    final hasTitle =
        titleText != null || eyebrowText != null || subtitleText != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NestSpace.gutter,
        NestSpace.md,
        NestSpace.gutter,
        NestSpace.lg,
      ),
      child: Row(
        children: [
          if (!hasTitle && leading != null)
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FittedBox(fit: BoxFit.scaleDown, child: leading),
              ),
            )
          else ...[
            ?leading,
            if (leading != null) const SizedBox(width: NestSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (eyebrowText != null) ...[
                    NestEyebrow(eyebrowText),
                    const SizedBox(height: NestSpace.xs),
                  ],
                  if (titleText != null)
                    Text(
                      titleText,
                      style: nest.text.screenTitle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (subtitleText != null)
                    Text(subtitleText, style: nest.text.caption),
                ],
              ),
            ),
          ],
          for (final action in trailing) ...[
            const SizedBox(width: NestSpace.sm),
            action,
          ],
        ],
      ),
    );
  }
}

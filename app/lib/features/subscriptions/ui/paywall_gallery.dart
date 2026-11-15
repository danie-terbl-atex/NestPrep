import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../model/premium_highlight.dart';
import 'premium_highlight_look.dart';

/// The paywall's photos, one per Premium area that has one, swiped by hand
/// and opened on [first]. Decoration: the list under it says the same in
/// words, so a screen reader skips it (`FE-13`).
class PaywallGallery extends StatefulWidget {
  const PaywallGallery({required this.first, super.key});

  final PremiumHighlight? first;

  static final pictured = [
    for (final highlight in PremiumHighlight.values)
      if (highlight.photo != null) highlight,
  ];

  @override
  State<PaywallGallery> createState() => _PaywallGalleryState();
}

class _PaywallGalleryState extends State<PaywallGallery> {
  static const _viewport = 0.86;
  static const _maxHeight = 320.0;
  static const _decodeWidth = 900;

  late int _page = math.max(
    0,
    PaywallGallery.pictured.indexWhere((shown) => shown == widget.first),
  );
  late final PageController _controller = PageController(
    initialPage: _page,
    viewportFraction: _viewport,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final pictured = PaywallGallery.pictured;
    return ExcludeSemantics(
      child: Column(
        children: [
          SizedBox(
            height: math.min(
              MediaQuery.sizeOf(context).width * _viewport * 3 / 4,
              _maxHeight,
            ),
            child: PageView.builder(
              controller: _controller,
              itemCount: pictured.length,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (context, index) {
                final highlight = pictured[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: NestSpace.xs),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      NestPhotoFrame(
                        child: Image.asset(
                          highlight.photo!,
                          fit: BoxFit.cover,
                          cacheWidth: _decodeWidth,
                        ),
                      ),
                      PositionedDirectional(
                        start: NestSpace.md,
                        bottom: NestSpace.md,
                        child: IgnorePointer(
                          child: NestButton(
                            label: SubscriptionCopy.highlightTitle(highlight),
                            icon: highlight.icon,
                            onPressed: () {},
                            variant: NestButtonVariant.onPhoto,
                            size: NestButtonSize.small,
                            isExpanded: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: NestSpace.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0; index < pictured.length; index++)
                AnimatedContainer(
                  duration: NestMotion.of(context).standard,
                  margin: const EdgeInsets.symmetric(horizontal: NestSpace.xxs),
                  width: index == _page ? NestSpace.lg : NestSpace.sm,
                  height: NestSpace.sm,
                  decoration: ShapeDecoration(
                    shape: const StadiumBorder(),
                    color: index == _page
                        ? nest.colors.secondary
                        : nest.colors.outlineStrong,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

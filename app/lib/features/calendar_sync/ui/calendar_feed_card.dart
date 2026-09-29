import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/calendar_sync_copy.dart';
import '../model/calendar_feed_link.dart';

/// The family week going the other way: a link any member subscribes to from
/// Apple, Google or Outlook (calendar ADR-0003). Before anybody has asked for
/// it the card offers to make it; after, it shows it with the ways to use it.
/// An admin can make a new one, which is how a link shared too far is taken
/// back.
class CalendarFeedCard extends StatefulWidget {
  const CalendarFeedCard({
    required this.feed,
    required this.isBusy,
    required this.canReset,
    required this.onGetLink,
    required this.onSubscribe,
    required this.onReset,
    super.key,
  });

  final CalendarFeedLink? feed;
  final bool isBusy;
  final bool canReset;
  final VoidCallback onGetLink;
  final VoidCallback onSubscribe;
  final VoidCallback onReset;

  @override
  State<CalendarFeedCard> createState() => _CalendarFeedCardState();
}

class _CalendarFeedCardState extends State<CalendarFeedCard> {
  /// The button says it worked, as the invite code's does, rather than a
  /// toast that covers the tab bar.
  bool _hasCopied = false;

  @override
  void didUpdateWidget(CalendarFeedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feed != widget.feed) _hasCopied = false;
  }

  Future<void> _copy(CalendarFeedLink link) async {
    await Clipboard.setData(ClipboardData(text: link.url));
    if (!mounted) return;
    setState(() => _hasCopied = true);
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final link = widget.feed;
    final isBusy = widget.isBusy;
    return NestCard(
      variant: NestCardVariant.tinted,
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const NestIconTile(
                icon: Icons.ios_share,
                size: NestSize.avatarMedium,
                iconSize: NestSize.iconMedium,
              ),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Text(
                  CalendarSyncCopy.feedBlurb,
                  style: nest.text.body.copyWith(color: nest.colors.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: NestSpace.lg),
          if (link == null)
            NestButton(
              label: CalendarSyncCopy.feedGetLink,
              icon: Icons.link,
              isLoading: isBusy,
              onPressed: isBusy ? null : widget.onGetLink,
            )
          else ...[
            SelectableText(
              link.url,
              maxLines: 2,
              style: nest.text.caption.copyWith(
                color: nest.colors.inkSecondary,
              ),
            ),
            const SizedBox(height: NestSpace.md),
            NestButton(
              label: CalendarSyncCopy.feedSubscribe,
              icon: Icons.event_available_outlined,
              onPressed: widget.onSubscribe,
            ),
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: _hasCopied
                  ? CalendarSyncCopy.feedCopied
                  : CalendarSyncCopy.feedCopy,
              icon: _hasCopied ? Icons.check : Icons.copy_outlined,
              variant: NestButtonVariant.outline,
              onPressed: () => _copy(link),
            ),
            if (widget.canReset) ...[
              const SizedBox(height: NestSpace.sm),
              NestButton(
                label: CalendarSyncCopy.feedReset,
                variant: NestButtonVariant.ghost,
                isLoading: isBusy,
                onPressed: isBusy ? null : widget.onReset,
              ),
            ],
          ],
          const SizedBox(height: NestSpace.md),
          Text(
            CalendarSyncCopy.feedPrivacy,
            style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
          ),
        ],
      ),
    );
  }
}

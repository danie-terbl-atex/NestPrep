import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/notifications_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../model/notification_settings.dart';
import '../state/notification_settings_controller.dart';
import 'digest_settings_card.dart';
import 'kids_notifications_card.dart';
import 'phone_settings_card.dart';
import 'quiet_hours_card.dart';
import 'reminder_settings_card.dart';

/// A person's notification settings (notifications ADR-0003): this phone,
/// the morning digest, the reminders, quiet hours and — for family — the
/// children's digests. Pushed from the inbox, so it carries its own way back.
///
/// The phone's card sits above the choices, never replacing them: somebody
/// may choose their digest time before they allow the phone to buzz.
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NotificationSettingsController>();
    final failure = controller.actionFailure;
    return NestScaffold(
      title: NotificationsCopy.settingsTitle,
      leading: backLeading(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.lg),
              child: NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.danger,
                actionLabel: AppCopy.back,
                onAction: controller.dismissActionFailure,
              ),
            ),
          Expanded(
            child: NestAsyncView<NotificationSettings>(
              state: controller.settings,
              isEmpty: (_) => false,
              onRetry: controller.retry,
              emptyBuilder: (_) => const SizedBox.shrink(),
              dataBuilder: (context, settings) => _Choices(
                settings: settings,
                hasKids: controller.kids.isNotEmpty,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Choices extends StatelessWidget {
  const _Choices({required this.settings, required this.hasKids});

  final NotificationSettings settings;
  final bool hasKids;

  @override
  Widget build(BuildContext context) {
    final sections = <(String, Widget)>[
      (NotificationsCopy.phoneTitle, const PhoneSettingsCard()),
      (NotificationsCopy.digestTitle, DigestSettingsCard(settings: settings)),
      (
        NotificationsCopy.remindersTitle,
        ReminderSettingsCard(settings: settings),
      ),
      (NotificationsCopy.quietTitle, QuietHoursCard(settings: settings)),
      if (hasKids) (NotificationsCopy.kidsTitle, const KidsNotificationsCard()),
    ];
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        for (final (index, (title, card)) in sections.indexed)
          NestRiseIn(
            key: ValueKey('settings-$title'),
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NestSectionHeader(title: title),
                  const SizedBox(height: NestSpace.sm),
                  card,
                ],
              ),
            ),
          ),
      ],
    );
  }
}

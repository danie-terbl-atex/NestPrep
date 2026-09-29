import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/two_homes_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../model/change_request.dart';
import '../model/co_parent_link.dart';
import '../state/link_controller.dart';
import '../state/schedule_draft.dart';
import 'schedule_editor.dart';

/// Suggesting a new schedule to the other home (household ADR-0004): the same
/// editor a code is made with, starting from the schedule as it stands, and a
/// note. It is sent as a request; the schedule changes only if the other home
/// accepts it.
class ScheduleRequestScreen extends StatelessWidget {
  const ScheduleRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LinkController>();
    final failure = controller.actionFailure;
    return NestScaffold(
      title: TwoHomesCopy.scheduleRequestTitle,
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
            child: NestAsyncView<CoParentLink?>(
              state: controller.link,
              isEmpty: (link) => link == null || !link.isActive,
              onRetry: controller.retry,
              emptyBuilder: (_) => const NestEmptyView(
                icon: Icons.link_off,
                title: TwoHomesCopy.scheduleRequestTitle,
                message: TwoHomesCopy.linkGone,
              ),
              dataBuilder: (context, link) => link == null
                  ? const SizedBox.shrink()
                  : _ScheduleRequestForm(link: link),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleRequestForm extends StatefulWidget {
  const _ScheduleRequestForm({required this.link});

  final CoParentLink link;

  @override
  State<_ScheduleRequestForm> createState() => _ScheduleRequestFormState();
}

class _ScheduleRequestFormState extends State<_ScheduleRequestForm> {
  late final _draft = ScheduleDraft.from(widget.link.schedule);
  final _note = TextEditingController();

  @override
  void dispose() {
    _draft.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LinkController>();
    final nest = NestTheme.of(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        Text(
          TwoHomesCopy.scheduleRequestBody,
          style: nest.text.body.copyWith(color: nest.colors.inkSecondary),
        ),
        const SizedBox(height: NestSpace.lg),
        ChangeNotifierProvider.value(
          value: _draft,
          child: ScheduleEditor(
            homeOf: widget.link.homeOf,
            today: controller.today,
          ),
        ),
        const SizedBox(height: NestSpace.xl),
        NestTextField(
          label: TwoHomesCopy.noteLabel,
          hint: TwoHomesCopy.noteHint,
          controller: _note,
          maxLines: 3,
          inputFormatters: [
            LengthLimitingTextInputFormatter(ChangeRequest.maxNoteLength),
          ],
        ),
        const SizedBox(height: NestSpace.xl),
        ListenableBuilder(
          listenable: _draft,
          builder: (context, _) => NestButton(
            label: TwoHomesCopy.send,
            icon: Icons.send_outlined,
            isLoading: controller.isSending,
            onPressed: _draft.schedule.isComplete && !controller.isSending
                ? _send
                : null,
          ),
        ),
      ],
    );
  }

  Future<void> _send() async {
    final controller = context.read<LinkController>();
    final sent = await controller.proposeSchedule(
      _draft.schedule,
      note: _note.text,
    );
    if (!sent || !mounted) return;
    // Back to the link — which a deep link straight here has not got under it.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(
        TwoHomesRoute.linkPathFor(controller.householdId, controller.linkId),
      );
    }
  }
}
